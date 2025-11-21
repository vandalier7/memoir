import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

Future<String> getCachedImagePath(String imageUrl) async {
  // Use hash of URL as filename (so same URL = same file)
  final urlHash = md5.convert(utf8.encode(imageUrl)).toString();

  // Path in cache directory
  final cacheDir = await getTemporaryDirectory();
  final filePath = "${cacheDir.path}/$urlHash.png";
  final file = File(filePath);

  // If the file already exists → re-use it
  if (await file.exists()) {
    return file.path;
  }

  // Otherwise download it
  try {
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode != 200) {
      throw Exception("Failed to download image");
    }

    await file.writeAsBytes(response.bodyBytes, flush: true);

    return file.path;
  } catch (e) {
    print("Image cache download error: $e");
    rethrow;
  }
}
