import 'package:flutter/material.dart';
import '../processes/storage_service.dart';
// import '../models/bin_item.dart'; // No longer used here
import '../models/posted_item.dart'; // Use the new PostedItem model
import 'package:cached_network_image/cached_network_image.dart';
// import 'recently_deleted_screen.dart'; // No longer used
import '../objects/globals.dart';

class PostedScreen extends StatefulWidget {
  const PostedScreen({super.key});

  @override
  State<PostedScreen> createState() => _PostedScreenState();
}

class _PostedScreenState extends State<PostedScreen> {
  // Use the new PostedItem model
  late Future<List<PostedItem>> _postedImagesFuture;

  @override
  void initState() {
    super.initState();
    _postedImagesFuture = storageService.fetchPostedImages();
  }

  void _refreshImages() {
    setState(() {
      _postedImagesFuture = storageService.fetchPostedImages();
    });
  }

  // This handleAction function from alpha-version is perfect, no change needed
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
      _refreshImages();
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
        title: const Text('Posted Memories'),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 248, 217, 174),
        // The 'actions' property (with the recently_deleted button) is removed.
      ),
      body: FutureBuilder<List<PostedItem>>( // Use PostedItem
        future: _postedImagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading posted images: ${snapshot.error.toString()}'),
            );
          }

          final images = snapshot.data ?? [];
          if (images.isEmpty) {
            return const Center(
              child: Text(
                'No images posted yet. Post some from the Bin!', // Updated text
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(5.0),
            itemCount: images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 5.0,
              mainAxisSpacing: 5.0,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final item = images[index];
              return _PostedGridTile(
                item: item,
                storageService: storageService,
                onActionComplete: _refreshImages,
                handleAction: _handleAction,
              );
            },
          );
        },
      ),
    );
  }
}

class _PostedGridTile extends StatelessWidget {
  final PostedItem item; // Use PostedItem
  final StorageService storageService;
  final VoidCallback onActionComplete;
  final Function handleAction;

  const _PostedGridTile({
    // 'super.key' was missing in alpha, adding it
    super.key,
    required this.item,
    required this.storageService,
    required this.onActionComplete,
    required this.handleAction,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showOptionsDialog(context),
      child: Card(
        elevation: 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Theme.of(context).colorScheme.surfaceVariant),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
              Align(
                alignment: Alignment(0.0, 0.90),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  color: Colors.black54,
                  child: Text(
                    // Use the dateAdded from PostedItem
                    'Posted: ${item.dateAdded.year}-${item.dateAdded.month}-${item.dateAdded.day}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(' ${item.fileName} '),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Permanently'), // Updated text
                onTap: () {
                  Navigator.of(context).pop(); // Close this dialog first
                  // Show confirmation dialog for permanent delete
                  _showDeleteConfirmation(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: const Text('This image will be deleted permanently and cannot be recovered.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog
              // Use the new permanent delete function
              await handleAction(
                context,
                () => storageService.permanentlyDeleteFromPosted(item),
                'Image deleted permanently.',
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          )
        ],
      )
    );
  }
}