// lib/models/posted_item.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class PostedItem {
  final String storagePath;
  final String imageUrl;
  final String fileName;
  final DateTime dateAdded;

  const PostedItem({
    required this.storagePath,
    required this.imageUrl,
    required this.fileName,
    required this.dateAdded,
  });

  factory PostedItem.fromSupabaseFileObject(
    FileObject fileObject,
    String publicUrl,
  ) {
    final createdAtString = fileObject.createdAt;

    return PostedItem(
      storagePath: fileObject.id!, 
      imageUrl: publicUrl,
      fileName: fileObject.name!,
      dateAdded: DateTime.parse(createdAtString!),
    );
  }
}