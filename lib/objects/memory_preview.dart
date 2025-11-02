import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'globals.dart';

class MemoryPreview extends StatelessWidget {
  final String addressString;
  final Mood mood;
  final String? imageUrl; // Network image URL
  final VoidCallback onClose;

  const MemoryPreview({
    super.key,
    required this.addressString,
    required this.mood,
    this.imageUrl,
    required this.onClose,
    
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 30,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              : Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Icon(
                      Icons.photo_library,
                      size: 30,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
        ),
    );
  }
}