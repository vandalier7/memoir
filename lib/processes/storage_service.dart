import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/bin_item.dart';
import '../objects/memory.dart'; // your MemoryData class
import '../objects/globals.dart';
import 'dart:async';

const String supabaseBucket = 'images';
const String postedFolder = 'posted';
const String binFolder = 'bin';
const String pendingDelete = 'pending_delete';

class StorageService {
  final FirebaseAuth _auth = FirebaseAuth.instance; 
  final SupabaseClient _supabase = Supabase.instance.client; 
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  String _getUserFolderPath(String folder) {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception("Authentication Error: User is not logged in."); 
    }
    return '$userId/$folder';
  }

  Future<String> uploadImage(String fileName, Uint8List bytes, String bucket) async {
  final fileName = 'memory_${DateTime.now().millisecondsSinceEpoch}.png';

  await _supabase.storage
      .from(supabaseBucket)
          .uploadBinary(
            "$currentUserId/posted/$fileName", 
            bytes
          );

  return _supabase.storage
          .from(supabaseBucket)
          .getPublicUrl("$currentUserId/posted/$fileName");
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
      if (kDebugMode) debugPrint("Supabase Storage Error fetching bin images: ${e.message}");
      return []; 
    } on Exception catch (e) {
      if (kDebugMode) debugPrint("General Error fetching bin images: $e");
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
        if (kDebugMode) debugPrint('✅ Image ${item.fileName} restored (moved to POSTED).');
      } on StorageException catch (e) {
        if (kDebugMode) debugPrint("Supabase Storage Error restoring image: ${e.message}");
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
      if (kDebugMode) debugPrint("Supabase Storage Error fetching posted images: ${e.message}");
      return []; 
    } on Exception catch (e) {
      if (kDebugMode) debugPrint("General Error fetching posted images: $e");
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
    if (kDebugMode) debugPrint("Supabase Storage Error fetching pending delete images: ${e.message}");
    return []; 
  } on Exception catch (e) {
    if (kDebugMode) debugPrint("General Error fetching pending delete images: $e");
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
      if (kDebugMode) debugPrint('✅ Image moved from POSTED to PENDING DELETE stage.');
      
    } on StorageException catch (e) {
      if (kDebugMode) debugPrint("Supabase Storage Error during soft delete from posted: ${e.message}");
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
      if (kDebugMode) debugPrint('✅ Image ${item.fileName} restored from pending delete back to POSTED.');
      
    } on StorageException catch (e) {
      if (kDebugMode) debugPrint("Supabase Storage Error during restore from pending: ${e.message}");
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
      if (kDebugMode) debugPrint('✅ Image ${item.fileName} permanently removed from storage.');
    } on StorageException catch (e) {
      if (kDebugMode) debugPrint("Supabase Storage Error during hard delete: ${e.message}");
      rethrow;
    }
  }

  Future<void> permanentlyDeleteFromBin(BinItem item) async {
    final userId = currentUserId;
    if (userId == null) return;

    final filePathToDelete = '${_getUserFolderPath(binFolder)}/${item.fileName}';

    try {
      await _supabase.storage.from(supabaseBucket).remove([filePathToDelete]);
      if (kDebugMode) debugPrint('✅ Image ${item.fileName} permanently removed from BIN storage.');
    } on StorageException catch (e) {
      if (kDebugMode) debugPrint("Supabase Storage Error during hard delete from bin: ${e.message}");
      rethrow;
    }
  }

  StreamSubscription<QuerySnapshot>? _memorySub;

  void listenUserMemories({bool Function(MemoryData)? filter}) {
  debugPrint('🔵 [1] listenUserMemories called');
  
  _memorySub?.cancel();
  debugPrint('🔵 [2] Previous subscription cancelled');

  final userId = currentUserId;
  debugPrint('🔵 [3] Got userId: $userId');
  
  if (userId == null) {
    debugPrint('⚠️ Cannot listen to memories: user not logged in');
    return;
  }

  debugPrint('🔵 [4] About to create Firestore listener...');
  
  _memorySub = _firestore
    .collection('memories')
    .where('userId', isEqualTo: userId)
    .snapshots()
    .listen(
      (snapshot) {
        print('🟢 [5] Snapshot received with ${snapshot.docs.length} docs');
        
        unfilteredMemories.clear();
        print('🟢 [6] Cleared unfilteredMemories');

        print('🟡 [6.5] snapshot.docs type: ${snapshot.docs.runtimeType}');
        print('🟡 [6.6] About to enter for loop...');
        
        int count = 0;
        for (var doc in snapshot.docs) {
          print('🟡 [7.$count] INSIDE for loop - processing doc');
          
          print('🟡 [7.${count}a] About to call doc.data()');
          final data = doc.data();
          print('🟡 [7.${count}b] Got data: ${data.keys}');
          
          print('🟡 [7.${count}c] Parsing latitude');
          final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
          print('🟡 [7.${count}d] lat = $lat');
          
          print('🟡 [7.${count}e] Parsing longitude');
          final lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
          print('🟡 [7.${count}f] lng = $lng');

          print('🟡 [7.${count}g] Getting moodValue');
          final moodVal = data['moodValue'] as int? ?? 1;
          print('🟡 [7.${count}h] moodVal = $moodVal, calling moodFromValue()');
          
          final mood = moodFromValue(moodVal);
          print('🟡 [7.${count}i] mood = $mood');

          print('🟡 [7.${count}j] Creating LatLng');
          final position = LatLng(lat, lng);
          print('🟡 [7.${count}k] position created');

          print('🟡 [7.${count}l] Creating MemoryData');
          final memory = MemoryData(
            head: data['head'] as bool? ?? false,
            mood: mood,
            addressString: data['addressString'] as String? ?? '',
            position: position,
            imageUrl: data['imageUrl'] as String?,
          );


          print('🟡 [7.${count}o] Checking filter');
          if (filter == null || filter(memory)) {
            print('🟡 [7.${count}p] Adding to unfilteredMemories');
            unfilteredMemories.add(memory);
            print('🟡 [7.${count}q] Added successfully');
          }
          
          print('🟡 [7.${count}r] Doc complete');
          count++;
        }
        print('🟢 [7] Finished processing $count memories');
      },
      onError: (error) {
        print('❌ Firestore error: $error');
      },
    );
  
  debugPrint('🔵 [8] Listener setup complete (but stream is async)');
}

  void dispose() {
    _memorySub?.cancel();
  }
}