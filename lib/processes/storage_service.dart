import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/bin_item.dart';

// 🛑 UPDATE THESE CONSTANTS 
const String supabaseBucket = 'images'; // <-- Use your actual bucket name
const String postedFolder = 'posted';
const String binFolder = 'bin';

class StorageService {
  // Uses Firebase for User ID (Access Key)
  final FirebaseAuth _auth = FirebaseAuth.instance; 
  // Uses Supabase for File Operations
  final SupabaseClient _supabase = Supabase.instance.client; 

  String? get currentUserId => _auth.currentUser?.uid;

  String _getUserFolderPath(String folder) {
    final userId = currentUserId;
    if (userId == null) {
      // This ensures no operation runs if the user is not authenticated.
      throw Exception("Authentication Error: User is not logged in."); 
    }
    // Storage Path Format: 'user_id/folder/'
    return '$userId/$folder';
  }

  // --- A. FETCH IMAGES FROM BIN ---
// lib/processes/storage_service.dart (Replace existing fetchBinImages function)

// --- A. FETCH IMAGES FROM BIN ---
Future<List<BinItem>> fetchBinImages() async {
  final binPath = _getUserFolderPath(binFolder);
  
  try {
    // 1. List files in the user's bin folder (List<FileObject> type is explicit)
    final List<FileObject> fileList = await _supabase.storage
        .from(supabaseBucket)
        .list(
          path: binPath,  
        );

    
    final binItems = <BinItem>[];

    // 2. Iterate through the list to construct BinItem objects
    for (FileObject file in fileList) { // Explicitly define FileObject
      // Supabase list can include folder objects (name is null for folders), skip if not a file
      if (file.id != null) { 
        // Construct the full Supabase file path
        final fullSupabasePath = '$binPath/${file.name}';
        
        // 3. Get the public URL for display
        final publicUrl = _supabase.storage
            .from(supabaseBucket)
            .getPublicUrl(fullSupabasePath);

        // 4. Create the BinItem using the retrieved metadata and URL
        binItems.add(BinItem.fromSupabaseFileObject( // <--- NEW FACTORY NAME
          file, // <--- Pass the FileObject directly
          publicUrl
        ));
      }
    }
    return binItems;
    
  } on StorageException catch (e) {
    if (kDebugMode) print("Supabase Storage Error fetching bin images: ${e.message}");
    return []; 
  } on Exception catch (e) {
    if (kDebugMode) print("General Error fetching bin images: $e");
    return [];
  }
}

  // --- B. RESTORE IMAGE (Move Operation) ---
  Future<void> restoreImage(BinItem item) async {
    final userId = currentUserId;
    if (userId == null) return;
    
    // Original path: {user_id}/bin/{filename}
    final sourcePath = '${_getUserFolderPath(binFolder)}/${item.fileName}';
    // New path: {user_id}/posted/{filename}
    final destinationPath = '${_getUserFolderPath(postedFolder)}/${item.fileName}';
    
    try {
      // Supabase supports a direct MOVE operation to simulate restoration/posting
      await _supabase.storage.from(supabaseBucket).move(
        sourcePath, 
        destinationPath,
      );
      if (kDebugMode) print('✅ Image ${item.fileName} restored (moved to POSTED).');
    } on StorageException catch (e) {
      if (kDebugMode) print("Supabase Storage Error restoring image: ${e.message}");
      rethrow;
    }
  }

  // --- C. DELETE IMAGE (Remove Operation) ---
  Future<void> deleteImage(BinItem item) async {
    final userId = currentUserId;
    if (userId == null) return;

    // The path to delete is the full path stored in the BinItem
    final filePathToDelete = item.storagePath;

    try {
      // Supabase remove takes a list of file paths to delete
      await _supabase.storage.from(supabaseBucket).remove([filePathToDelete]);
      if (kDebugMode) print('✅ Image ${item.fileName} permanently deleted via Supabase.');
    } on StorageException catch (e) {
      if (kDebugMode) print("Supabase Storage Error deleting image: ${e.message}");
      rethrow;
    }
  }
}