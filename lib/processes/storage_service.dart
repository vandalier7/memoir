import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/bin_item.dart';

const String supabaseBucket = 'images';
const String postedFolder = 'posted';
const String binFolder = 'bin';

class StorageService {
  final FirebaseAuth _auth = FirebaseAuth.instance; 
  final SupabaseClient _supabase = Supabase.instance.client; 

  String? get currentUserId => _auth.currentUser?.uid;

  String _getUserFolderPath(String folder) {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception("Authentication Error: User is not logged in."); 
    }
    return '$userId/$folder';
  }

Future<List<BinItem>> fetchBinImages() async {
  final binPath = _getUserFolderPath(binFolder);

  try {
    final List<FileObject> fileList = await _supabase.storage
        .from(supabaseBucket)
        .list(
          path: binPath,  
        );

    final binItems = <BinItem>[];

    for (FileObject file in fileList) { 
      print(file.name);
      if (file.name != null) { 
        final fullSupabasePath = '$binPath/${file.name}';
        
        final publicUrl = _supabase.storage
            .from(supabaseBucket)
            .getPublicUrl(fullSupabasePath);

        binItems.add(BinItem.fromSupabaseFileObject( 
          file,
          publicUrl));
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

  Future<void> restoreImage(BinItem item) async {
    final userId = currentUserId;
    if (userId == null) return;
    
    final sourcePath = '${_getUserFolderPath(binFolder)}/${item.fileName}';
    final destinationPath = '${_getUserFolderPath(postedFolder)}/${item.fileName}';
    
    try {
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

  Future<void> deleteImage(BinItem item) async {
    final userId = currentUserId;
    if (userId == null) return;

    final filePathToDelete = item.storagePath;

    try {
      await _supabase.storage.from(supabaseBucket).remove([filePathToDelete]);
      if (kDebugMode) print('✅ Image ${item.fileName} permanently deleted via Supabase.');
    } on StorageException catch (e) {
      if (kDebugMode) print("Supabase Storage Error deleting image: ${e.message}");
      rethrow;
    }
  }
}

Future<void> testBucketConnection() async {
  final SupabaseClient supabase = Supabase.instance.client;
  const String bucketName = 'images';
  const String testPath = ''; // empty string for root folder

  try {
    final List<FileObject> files = await supabase.storage.from(bucketName).list(path: testPath);
    
    if (files.isEmpty) {
      print('No files found in bucket "$bucketName" at path "$testPath".');
    } else {
      print('Files in bucket "$bucketName" at path "$testPath":');
      for (var file in files) {
        print('- ${file.name} (updated: ${file.updatedAt})');
      }
    }
  } catch (e) {
    print('Error accessing bucket: $e');
  }
}
