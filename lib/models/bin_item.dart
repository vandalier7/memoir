import 'package:cloud_firestore/cloud_firestore.dart';
class BinItem {
  final String id;
  final String supabasePath;
  final String imageUrl;
  final String fileName;
  final Timestamp expireAt;

  const BinItem({
    required this.id,
    required this.supabasePath,
    required this.imageUrl,
    required this.fileName,
    required this.expireAt,
  });

  factory BinItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BinItem(
      id: doc.id, 
      
      supabasePath: data['supabasePath'] ?? '',
      imageUrl: data['publicUrl'] ?? data['imageUrl'] ?? '',
      fileName: data['fileName'] ?? '',
      expireAt: data['expireAt'] ?? Timestamp.now(),
    );
  }
}