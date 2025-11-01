import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/bin_item.dart';

const String supabaseBucket = 'images';
const String postedFolder = 'posted';
const String binFolder = 'bin';
const String pendingDelete = 'pending_delete';

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
        if (file.id != null) { 
          final fullSupabasePath = '$binPath/${file.name!}';
          
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

  Future<List<BinItem>> fetchPostedImages() async {
    final postedPath = _getUserFolderPath(postedFolder); 
    
    try {
      final List<FileObject> fileList = await _supabase.storage
          .from(supabaseBucket)
          .list(
            path: postedPath,
          );
      final postedItems = <BinItem>[];
      for (FileObject file in fileList) { 
        if (file.id != null) { 
          final fullSupabasePath = '$postedPath/${file.name!}'; 
          final publicUrl = _supabase.storage
              .from(supabaseBucket)
              .getPublicUrl(fullSupabasePath); 
          postedItems.add(BinItem.fromSupabaseFileObject( 
            file,
            publicUrl
          ));
        }
      }
      return postedItems;
      
    } on StorageException catch (e) {
      if (kDebugMode) print("Supabase Storage Error fetching posted images: ${e.message}");
      return []; 
    } on Exception catch (e) {
      if (kDebugMode) print("General Error fetching posted images: $e");
      return [];
    }
  }

Future<List<BinItem>> fetchPendingDeleteImages() async {
  const String pendingDelete = 'pending_delete'; 
  final pendingPath = _getUserFolderPath(pendingDelete);
  
  try {
    final List<FileObject> fileList = await _supabase.storage
        .from(supabaseBucket)
        .list(
          path: pendingPath,
        );

    final pendingItems = <BinItem>[];

    for (FileObject file in fileList) { 
      if (file.id != null) { 
        final fullSupabasePath = '$pendingPath/${file.name!}';
        final publicUrl = _supabase.storage
            .from(supabaseBucket)
            .getPublicUrl(fullSupabasePath); 

        pendingItems.add(BinItem.fromSupabaseFileObject( 
          file,
          publicUrl
        ));
      }
    }
    return pendingItems;
    
  } on StorageException catch (e) {
    if (kDebugMode) print("Supabase Storage Error fetching pending delete images: ${e.message}");
    return []; 
  } on Exception catch (e) {
    if (kDebugMode) print("General Error fetching pending delete images: $e");
    return [];
  }
}

Future<void> softDeleteFromPosted(BinItem item) async {
    final userId = currentUserId;
    if (userId == null) return;
    
    final sourcePath = '${_getUserFolderPath(postedFolder)}/${item.fileName}'; 
    final destinationPath = '${_getUserFolderPath(pendingDelete)}/${item.fileName}';

    try {
      await _supabase.storage.from(supabaseBucket).move(
        sourcePath, 
        destinationPath,
      );
      if (kDebugMode) print('✅ Image moved from POSTED to PENDING DELETE stage.');
      
    } on StorageException catch (e) {
      if (kDebugMode) print("Supabase Storage Error during soft delete from posted: ${e.message}");
      rethrow;
    }
  }

Future<void> restoreFromPending(BinItem item) async {
    final userId = currentUserId;
    if (userId == null) return;
    
    const String pendingDelete = 'pending_delete';
    final sourcePath = '${_getUserFolderPath(pendingDelete)}/${item.fileName}'; 
    final destinationPath = '${_getUserFolderPath(postedFolder)}/${item.fileName}';

    try {
      await _supabase.storage.from(supabaseBucket).move(
        sourcePath, 
        destinationPath,
      );
      if (kDebugMode) print('✅ Image ${item.fileName} restored from pending delete back to POSTED.');
      
    } on StorageException catch (e) {
      if (kDebugMode) print("Supabase Storage Error during restore from pending: ${e.message}");
      rethrow;
    }
}

  Future<void> permanentlyDeleteImage(BinItem item) async {
    final userId = currentUserId;
    if (userId == null) return;

    const String pendingDelete = 'pending_delete';
    final filePathToDelete = '${_getUserFolderPath(pendingDelete)}/${item.fileName}';

    try {
      await _supabase.storage.from(supabaseBucket).remove([filePathToDelete]);
      if (kDebugMode) print('✅ Image ${item.fileName} permanently removed from storage.');
    } on StorageException catch (e) {
      if (kDebugMode) print("Supabase Storage Error during hard delete: ${e.message}");
      rethrow;
    }
  }

}
