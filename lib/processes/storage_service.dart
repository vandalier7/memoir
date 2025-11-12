// lib/processes/storage_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/bin_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/posted_item.dart';  

const String supabaseBucket = 'images';
const String postedFolder = 'posted';
const String binFolder = 'bin'; 

class StorageService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  String getPublicUrlForPath(String supabasePath) {
    return _supabase.storage.from(supabaseBucket).getPublicUrl(supabasePath);
  }

  String _getUserFolderPath(String folder) {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception("Authentication Error: User is not logged in.");
    }
    return '$userId/$folder';
  }

  Future<void> uploadAndStageImage(Uint8List bytes, {int expireAfterDays = 30}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final fileName = 'staged_${DateTime.now().millisecondsSinceEpoch}.png';
    final supabasePath = '${_getUserFolderPath(binFolder)}/$fileName';

    try {
      await _supabase.storage
          .from(supabaseBucket)
          .uploadBinary(supabasePath, bytes);

      final publicUrl = _supabase.storage
          .from(supabaseBucket)
          .getPublicUrl(supabasePath);

      final expireAtTime = DateTime.now().add(Duration(days: expireAfterDays));

      await _firestore.collection('binned_images').add({ 
        'userId': userId,
        'fileName': fileName,
        'supabasePath': supabasePath,
        'publicUrl': publicUrl,
        'binnedAt': FieldValue.serverTimestamp(),
        'expireAt': Timestamp.fromDate(expireAtTime), 
      });
      if (kDebugMode) print('✅ Image staged in bin with TTL: $fileName');
    } on Exception catch (e) {
      if (kDebugMode) print('Error staging image: $e');
      rethrow;
    }
  }

  Future<List<BinItem>> fetchBinImages() async {
    final userId = currentUserId;
    if (userId == null) {
      if (kDebugMode) print("Not authenticated");
      return [];
    }

    try {
      final querySnapshot = await _firestore
          .collection('binned_images')
          .where('userId', isEqualTo: userId)

          .where('expireAt', isGreaterThan: Timestamp.now())
          .orderBy('expireAt', descending: false)
          .get();

      final binItems = querySnapshot.docs.map((doc) {
        return BinItem.fromFirestore(doc);
      }).toList();

      return binItems;
    } on Exception catch (e) {
      if (kDebugMode) print("Error fetching binned images from Firestore: $e");
      return [];
    }
  }

  Future<void> restoreImage(BinItem item) async {
    final userId = currentUserId;
    if (userId == null) return;

    final sourcePath = item.supabasePath; 
    final destinationPath = '${_getUserFolderPath(postedFolder)}/${item.fileName}';

    try {
      await _supabase.storage.from(supabaseBucket).move(
            sourcePath,
            destinationPath,
          );

      await _firestore.collection('binned_images').doc(item.id).delete();

      if (kDebugMode) print('✅ Image ${item.fileName} restored (posted).');
    } on StorageException catch (e) {
      if (kDebugMode) print("Supabase Storage Error restoring image: ${e.message}");
      rethrow;
    }
  }

  Future<void> permanentlyDeleteFromBin(BinItem item) async {
    final userId = currentUserId;
    if (userId == null) return;

    final filePathToDelete = item.supabasePath;

    try {
      await _supabase.storage.from(supabaseBucket).remove([filePathToDelete]);

      await _firestore.collection('binned_images').doc(item.id).delete();

      if (kDebugMode) print('✅ Image ${item.fileName} permanently removed from bin.');
    } on StorageException catch (e) {
      if (kDebugMode) print("Supabase Storage Error during hard delete from bin: ${e.message}");
      rethrow;
    }
  }

  Future<String> uploadImage(Uint8List bytes) async {
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

  Future<List<PostedItem>> fetchPostedImages() async {
    final postedPath = _getUserFolderPath(postedFolder);

    try {
      final List<FileObject> fileList = await _supabase.storage
          .from(supabaseBucket)
          .list(
            path: postedPath,
          );

      final postedItems = <PostedItem>[]; 
      
      for (FileObject file in fileList) {
        if (file.id != null) {
          final fullSupabasePath = '$postedPath/${file.name!}';
          final publicUrl = _supabase.storage
              .from(supabaseBucket)
              .getPublicUrl(fullSupabasePath);

          postedItems.add(PostedItem.fromSupabaseFileObject( 
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

  Future<void> permanentlyDeleteFromPosted(PostedItem item) async {
    final userId = currentUserId;
    if (userId == null) return;

    final filePathToDelete = '${_getUserFolderPath(postedFolder)}/${item.fileName}';

    try {
      await _supabase.storage.from(supabaseBucket).remove([filePathToDelete]);
      if (kDebugMode) print('✅ Image ${item.fileName} permanently removed from POSTED storage.');
    } on StorageException catch (e) {
      if (kDebugMode) print("Supabase Storage Error during hard delete from posted: ${e.message}");
      rethrow;
    }
  }
}