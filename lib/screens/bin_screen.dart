import 'package:flutter/material.dart';
import '../processes/storage_service.dart'; 
import '../models/bin_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BinScreen extends StatefulWidget {
  const BinScreen({super.key});

  @override
  State<BinScreen> createState() => _BinScreenState();
}

class _BinScreenState extends State<BinScreen> {
  final StorageService _storageService = StorageService(); 
  late Future<List<BinItem>> _binImagesFuture;

  @override
  void initState() {
    super.initState();
    _binImagesFuture = _storageService.fetchBinImages();
  }

  void _refreshImages() {
    setState(() {
      _binImagesFuture = _storageService.fetchBinImages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bin'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key),
            onPressed: () {
              // Retrieve the current user's UID (the Access Key)
              final userUid = FirebaseAuth.instance.currentUser?.uid;
              
              // Show the UID in a SnackBar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('UID: ${userUid ?? "Not Logged In"}'),
                  duration: const Duration(seconds: 5),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<BinItem>>(
        future: _binImagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading images: ${snapshot.error.toString()}'),
            );
          }
          
          final images = snapshot.data ?? [];
          if (images.isEmpty) {
            return const Center(
              child: Text(
                'The Bin is empty. Nothing to restore or delete!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Grid Based View (High-Priority)
          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, 
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 1.0, 
            ),
            itemBuilder: (context, index) {
              final item = images[index];
              return _BinGridTile(
                item: item,
                storageService: _storageService,
                onActionComplete: _refreshImages,
              );
            },
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. The Individual Grid Item and Action Handler
// -----------------------------------------------------------------------------
class _BinGridTile extends StatelessWidget {
  final BinItem item;
  final StorageService storageService;
  final VoidCallback onActionComplete;

  const _BinGridTile({
    required this.item,
    required this.storageService,
    required this.onActionComplete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showOptionsDialog(context),
      
      // ✅ NEW: Added ClipRRect to create rounded corners
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0), // Adjust the radius as needed
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image Display using CachedNetworkImage
            CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Theme.of(context).colorScheme.surfaceVariant),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            
            // Lifetime Memory Display
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                color: Colors.black54,
                child: Text(
                  'Added: ${item.dateAdded.year}-${item.dateAdded.month}-${item.dateAdded.day}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog for Restore/Delete Actions
  void _showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item.fileName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Restore Button (calls Supabase move operation)
              ListTile(
                leading: const Icon(Icons.restore_from_trash),
                title: const Text('Restore (Post)'),
                onTap: () async {
                  Navigator.of(context).pop(); 
                  await _handleAction(
                    context, 
                    () => storageService.restoreImage(item), 
                    'Image restored successfully (moved to Posted).'
                  );
                },
              ),
              // Delete Button (calls Supabase remove operation)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Permanently Delete'),
                onTap: () async {
                  Navigator.of(context).pop(); 
                  await _handleAction(
                    context, 
                    () => storageService.deleteImage(item), 
                    'Image permanently deleted.'
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAction(
      BuildContext context, 
      Future<void> Function() action,
      String successMessage,
    ) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
      }
      onActionComplete(); 
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e'))
        );
      }
    }
  }
}