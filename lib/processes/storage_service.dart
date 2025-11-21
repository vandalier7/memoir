//storage_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart'; // Kept from alpha
import '../models/bin_item.dart';
import '../models/posted_item.dart'; // Added import
import '../objects/memory.dart'; // Kept from alpha
import '../objects/globals.dart'; // Kept from alpha
import 'dart:async';

const String supabaseBucket = 'images';
const String postedFolder = 'posted';
const String binFolder = 'bin';
// const String pendingDelete = 'pending_delete'; // Removed

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
    await _supabase.storage
        .from(bucket)
            .uploadBinary(
              "$currentUserId/posted/$fileName", 
              bytes
            );
    databaseService.recordMemory(currentUserId!);

    return _supabase.storage
        .from(bucket)
        .getPublicUrl("$currentUserId/posted/$fileName");
  }

  // --- NEW BIN LOGIC (Firestore + Supabase) ---

  // New function from your code:
  Future<void> uploadAndStageImage(Uint8List bytes) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final fileName = 'staged_${DateTime.now().millisecondsSinceEpoch}.png';
    final supabasePath = '${_getUserFolderPath(binFolder)}/$fileName';

    try {
      // 1. Upload to Supabase Storage
      await _supabase.storage
          .from(supabaseBucket)
          .uploadBinary(supabasePath, bytes);

      final publicUrl = _supabase.storage
          .from(supabaseBucket)
          .getPublicUrl(supabasePath);

      // 2. Create Firestore document to track expiration
      final expireAtTime = DateTime.now().add(const Duration(hours: 6));

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

  // Updated fetchBinImages from your code:
  Future<List<BinItem>> fetchBinImages() async {
    final userId = currentUserId;
    if (userId == null) {
      if (kDebugMode) print("Not authenticated");
      return [];
    }

    try {
      // Query Firestore for images that haven't expired
      final querySnapshot = await _firestore
          .collection('binned_images')
          .where('userId', isEqualTo: userId)
          .where('expireAt', isGreaterThan: Timestamp.now()) // Filter expired
          .orderBy('expireAt', descending: false) // Show soon-to-expire first
          .get();

      final binItems = querySnapshot.docs.map((doc) {
        return BinItem.fromFirestore(doc); // Uses new constructor
      }).toList();

      return binItems;
    } on Exception catch (e) {
      if (kDebugMode) print("Error fetching binned images from Firestore: $e");
      return [];
    }
  }

  Future<String?> _getUserName(String userId) async {
    try {
      final response = await _supabase
        .from('user')
        .select('username')
        .eq('uid', userId)
        .maybeSingle();

      return response?['username'] as String?;
    } catch (e) {
      debugPrint('Error fetching username: $e');
      return null;
    }
  }

  // Updated restoreImage from your code:
  Future<void> restoreImage(BinItem item) async {
    final userId = currentUserId;
    if (userId == null) return;

    final sourcePath = item.supabasePath;
    final destinationPath = '${_getUserFolderPath(postedFolder)}/${item.fileName}';

    try {
      // 1. Move file in Supabase
      await _supabase.storage.from(supabaseBucket).move(
            sourcePath,
            destinationPath,
          );

      // 2. Delete the tracking document from Firestore
      await _firestore.collection('binned_images').doc(item.id).delete();

      if (kDebugMode) print('✅ Image ${item.fileName} restored (posted).');
    } on StorageException catch (e) {
      if (kDebugMode) print("Supabase Storage Error restoring image: ${e.message}");
      rethrow;
    }
  }

  // Updated permanentlyDeleteFromBin from your code:
  Future<void> permanentlyDeleteFromBin(BinItem item) async {
    final userId = currentUserId;
    if (userId == null) return;

    final filePathToDelete = item.supabasePath;

    try {
      // 1. Delete from Supabase Storage
      await _supabase.storage.from(supabaseBucket).remove([filePathToDelete]);

      // 2. Delete the tracking document from Firestore
      await _firestore.collection('binned_images').doc(item.id).delete();

      if (kDebugMode) print('✅ Image ${item.fileName} permanently removed from bin.');
    } on StorageException catch (e) {
      if (kDebugMode) print("Supabase Storage Error during hard delete from bin: ${e.message}");
      rethrow;
    }
  }

  // --- NEW POSTED IMAGES LOGIC ---

  // Updated fetchPostedImages from your code:
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

          // Use the new PostedItem model
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

  // New function from your code:
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
  
  // --- KEPT FROM ALPHA-VERSION ---
  // This is the memory listener you already had, left untouched.

  StreamSubscription<QuerySnapshot>? _memorySub;

  void listenUserMemories({bool Function(MemoryData)? filter}) async {
  
  _memorySub?.cancel();

  final userId = currentUserId;
  
  if (userId == null) {
   return;
  }

  // Fetch username once for this user
  final userName = await _getUserName(userId);
  debugPrint('🔵 [3.5] Got userName: $userName');

  
  _memorySub = _firestore
    .collection('memories')
    .where('userId', isEqualTo: userId)
    .snapshots()
    .listen(
      (snapshot) {
        
        unfilteredMemories.clear();

        
        int count = 0;
        for (var doc in snapshot.docs) {
          
          final data = doc.data();
          
          final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
          
          final lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;

          final moodVal = data['moodValue'] as int? ?? 1;
          
          final mood = moodFromValue(moodVal);

          final position = LatLng(lat, lng);

          debugPrint('🟡 [7.${count}l] Creating MemoryData');
          final memory = MemoryData(
            head: data['head'] as bool? ?? false,
            mood: mood,
            addressString: data['addressString'] as String? ?? '',
            position: position,
            imageUrl: data['imageUrl'] as String?,
            memoryId: doc.id,
            description: data['description'] as String?,
            supabaseMemoryId: data['supabaseMemoryId'] as int?,
            userName: userName,
            userId: userId,
            timestamp: data['createdAt'] != null 
              ? DateTime.parse(data['createdAt'] as String)
              : null,
          );


          if (filter == null || filter(memory)) {
            unfilteredMemories.add(memory);
          }
          
          count++;
        }
        debugPrint('🟢 [7] Finished processing $count memories');
      },
      onError: (error) {
        debugPrint('❌ Firestore error: $error');
      },
    );
  
}

  void dispose() {
    _memorySub?.cancel();
  }
}