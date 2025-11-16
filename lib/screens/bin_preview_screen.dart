// lib/screens/bin_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/bin_item.dart';
import '../processes/storage_service.dart';
import '../objects/globals.dart'; // Import globals to use the service

class BinPreviewScreen extends StatefulWidget {
  final BinItem item;
  const BinPreviewScreen({super.key, required this.item});

  @override
  State<BinPreviewScreen> createState() => _BinPreviewScreenState();
}

class _BinPreviewScreenState extends State<BinPreviewScreen> {
  // We don't need to instantiate storageService, we use the global one
  bool _isPosting = false;

  Future<void> _handlePost() async {
    setState(() => _isPosting = true);

    try {
      // Use the global storageService
      await storageService.restoreImage(widget.item);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image posted successfully!')),
        );
        // Pop with 'true' to signal to BinScreen to refresh
        Navigator.pop(context, true); 
      }
    } catch (e) {
      setState(() => _isPosting = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: CachedNetworkImage(
              imageUrl: widget.item.imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  const Center(child: Icon(Icons.error, color: Colors.red)),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: _isPosting ? null : _handlePost,
              icon: _isPosting
                  ? Container(
                      width: 20,
                      height: 20,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_file, color: Colors.white),
              label: Text(
                _isPosting ? 'POSTING...' : 'POST IMAGE',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 250, 132, 154),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}