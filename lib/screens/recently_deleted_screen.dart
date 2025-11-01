import 'package:flutter/material.dart';
import '../processes/storage_service.dart';
import '../models/bin_item.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecentlyDeletedScreen extends StatefulWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  State<RecentlyDeletedScreen> createState() => _RecentlyDeletedScreenState();
}

class _RecentlyDeletedScreenState extends State<RecentlyDeletedScreen> {
  final StorageService _storageService = StorageService();
  late Future<List<BinItem>> _deletedImagesFuture;

  @override
  void initState() {
    super.initState();
    // Fetch files from the /pending_delete/ folder
    _deletedImagesFuture = _storageService.fetchPendingDeleteImages(); 
  }

  void _refreshImages() {
    setState(() {
      _deletedImagesFuture = _storageService.fetchPendingDeleteImages();
    });
  }

  // Handle the action feedback and refresh (Used by the tile)
  Future<void> _handleAction(
    BuildContext context, 
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      // Add a small delay to ensure state change is ready before refresh (optional safety)
      await Future.delayed(const Duration(milliseconds: 200)); 
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
      }
      _refreshImages(); // Refresh the list
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Recently Deleted'),
        centerTitle: true,
        backgroundColor:    Color.fromARGB(255, 250, 132, 154), // Distinct color for deletion stage
      ),
      body: FutureBuilder<List<BinItem>>(
        future: _deletedImagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(
               child: Text('Error loading deleted items: ${snapshot.error.toString()}'),
             );
          }

          final images = snapshot.data ?? [];
          if (images.isEmpty) {
            return const Center(
              child: Text(
                'Trash is empty. Nothing to permanently delete.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 0.9, 
            ),
            itemBuilder: (context, index) {
              final item = images[index];
              return _DeletedGridTile(
                item: item,
                storageService: _storageService,
                handleAction: _handleAction, // Pass handler down
              );
            },
          );
        },
      ),
    );
  }
}

// Helper Widget for Deleted Grid Tile
class _DeletedGridTile extends StatelessWidget {
  final BinItem item;
  final StorageService storageService;
  final Function handleAction; 

  const _DeletedGridTile({
    required this.item,
    required this.storageService,
    required this.handleAction,
  });

  // Function to show the action management dialog
  void _showActionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(' ${item.fileName} '),
          actions: [
            // RESTORE BUTTON (Moves file back to Bin folder)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); 
                await handleAction( 
                  context,
                  () => storageService.restoreFromPending(item),
                  'Image restored to Posted.',
                );
              },
              child: const Text('Restore Image to Posted'),
            ),

            const SizedBox(width: 10),

            // Permanent Delete Button (Triggers the final confirmation step)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close initial dialog
                _showPermanentDeleteConfirm(context); // Open the second confirmation dialog
              },
              child: const Text('Delete Permanently', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
}

// Function for the final, destructive confirmation (REQUIRED by the prompt)
void _showPermanentDeleteConfirm(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
            return AlertDialog(
                title: const Text('CONFIRM DELETION'),
                content: const Text(
                    'Are you sure you want to permanently delete this image? This action cannot be undone.', 
                    style: TextStyle(color: Colors.red),
                ),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                    ),
                    TextButton(
                        onPressed: () async {
                            Navigator.of(context).pop(); // Close dialog
                            await handleAction(
                                context,
                                // Calls the destructive permanent delete method
                                () => storageService.permanentlyDeleteImage(item), 
                                'Image permanently deleted.',
                            );
                        },
                        child: const Text('DELETE', style: TextStyle(color: Colors.red)),
                    ),
                ],
            );
        },
    );
}


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showActionDialog(context), // Tapping triggers the action dialog
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image Display
            CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Theme.of(context).colorScheme.surfaceVariant),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            // Overlay Text
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                color: Colors.black54,
                child: const Text(
                  'Pending Delete', 
                  style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}