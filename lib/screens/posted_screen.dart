// lib/screens/posted_screen.dart
import 'package:flutter/material.dart';
import '../processes/storage_service.dart';
import '../models/posted_item.dart'; // UPDATED: Import PostedItem
import 'package:cached_network_image/cached_network_image.dart';

class PostedScreen extends StatefulWidget {
  const PostedScreen({super.key});

  @override
  State<PostedScreen> createState() => _PostedScreenState();
}

class _PostedScreenState extends State<PostedScreen> {
  final StorageService _storageService = StorageService();
  late Future<List<PostedItem>> _postedImagesFuture;

  @override
  void initState() {
    super.initState();
    _postedImagesFuture = _storageService.fetchPostedImages();
  }

  void _refreshImages() {
    setState(() {
      _postedImagesFuture = _storageService.fetchPostedImages();
    });
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
      _refreshImages();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action failed: $e')));
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
        backgroundColor: const Color.fromARGB(255, 248, 217, 174),
      ),
      body: FutureBuilder<List<PostedItem>>(
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
                'No images posted yet. Post some from the Bin!',
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
                item: item, // UPDATED: Pass PostedItem
                storageService: _storageService,
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
  final PostedItem item;
  final StorageService storageService;
  final VoidCallback onActionComplete;
  final Function handleAction;

  const _PostedGridTile({
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
                alignment: const Alignment(0.0, 0.90),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  color: Colors.black54,
                  child: Text(
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
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete Permanently'),
                onTap: () async {
                  Navigator.of(context).pop();
                  
                  await handleAction(
                    context,
                    () => storageService.permanentlyDeleteFromPosted(item),
                    'Image permanently deleted.',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}