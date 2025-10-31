import 'package:flutter/material.dart';
import '../processes/storage_service.dart'; 
import '../models/bin_item.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
      backgroundColor: const Color.fromARGB(255, 239, 206, 217),
      appBar: AppBar(
        title: const Text('Bin'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 239, 175, 196),
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

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, 
              crossAxisSpacing: 5.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 0.6, 
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0), 
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.black.withAlpha(100)),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
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

  void _showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item.fileName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.restore_from_trash),
                title: const Text('Restore'),
                onTap: () async {
                  Navigator.of(context).pop(); 
                  await _handleAction(
                    context, 
                    () => storageService.restoreImage(item), 
                    'Image restored successfully (moved to Posted).'
                  );
                },
              ),
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