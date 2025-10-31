import 'package:supabase_flutter/supabase_flutter.dart';

class BinItem {
  final String storagePath;
  final String imageUrl;
  final String fileName;
  final DateTime dateAdded;
  
  const BinItem({
    required this.storagePath,
    required this.imageUrl,
    required this.fileName,
    required this.dateAdded,
  });

factory BinItem.fromSupabaseFileObject(
  FileObject fileObject, 
  String publicUrl
) {
  final createdAtString = fileObject.createdAt; 
  
  return BinItem(
    storagePath: fileObject.id!, 
    imageUrl: publicUrl,
    fileName: fileObject.name!,
    dateAdded: DateTime.parse(createdAtString!),
  );
  }
}