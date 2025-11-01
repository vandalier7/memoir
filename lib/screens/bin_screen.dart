import 'package:flutter/material.dart';
import '../processes/storage_service.dart'; 
import '../models/bin_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'posted_screen.dart';

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
    const List<Shadow> customIconShadows = [
      Shadow(
        blurRadius: 3.0,
        color: Color.fromARGB(255, 121, 103, 103),
        offset: Offset(0.5, 0.5),
      ),
    ];
  Widget shadowedIcon(IconData iconData, {required Color color, required double size}) {
    return Text(
      String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        inherit: false,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        fontSize: size,
        color: color,
        shadows: customIconShadows, // Applies the shadow here
      ),
    );
  }
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 253, 192, 203), 
      body: Container (
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const RadialGradient(
            colors: [ // deep pink
              Color.fromARGB(255, 250, 227, 194), // beige tint
              Color.fromARGB(255, 253, 192, 203),
            ],
            radius: 0.85,
          ),
        ),
        child: SafeArea (  
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  color: Colors.transparent, // deep pink
                  width: 350,
                  padding: const EdgeInsets.only(top: 5, bottom: 1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      IconButton( 
                        icon: shadowedIcon(Icons.close, color:Color.fromARGB(255, 46, 11, 22), size: 25),
                        onPressed: () {}, // Keep onPressed blank
                      ), 
                      const Text(
                        'Camera Bin', 
                          style: TextStyle(
                            color: Color.fromARGB(255, 46, 11, 22), 
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            shadows: [
                              Shadow (
                                blurRadius: 3.0,
                                color: Color.fromARGB(255, 121, 103, 103),
                                offset: Offset(0.5, 0.5),
                              )
                            ]
                        ),
                      ),
                      const SizedBox(width: 48.0), 
                    ],
                  ),
                ),
              ),

              Center(
                child: Container(
                  color: Colors.transparent, // deep pink,
                  width: 350,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recents', 
                        style: TextStyle(
                            color:Color.fromARGB(255, 46, 11, 22), 
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            shadows: [
                              Shadow (
                                blurRadius: 3.0,
                                color: Color.fromARGB(255, 121, 103, 103),
                                offset: Offset(0.5, 0.5),
                              )
                            ]
                        ),
                      ),
                      IconButton(
                        icon: shadowedIcon(Icons.amp_stories, color:Color.fromARGB(255, 46, 11, 22), size: 25),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PostedScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: FutureBuilder<List<BinItem>> (
                  future: _binImagesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading images: ${snapshot.error.toString()}', style: const TextStyle(color: Colors.white70)),
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
                      padding: const EdgeInsets.only(top: 3, right: 2, left: 2, bottom: 3),
                      itemCount: images.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, 
                        crossAxisSpacing: 2.0, 
                        mainAxisSpacing: 2.0, 
                        childAspectRatio: 0.7, 
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
              ),
            ],
          ),
        ),
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
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 207, 183, 183),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  'Added: ${item.dateAdded.year}-${item.dateAdded.month}-${item.dateAdded.day}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
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
              leading: const Icon(Icons.post_add, color: Colors.green), 
              title: const Text('Restore / Posted'),
              onTap: () async {
                Navigator.of(context).pop(); 
                await _handleAction(
                  context, 
                  () => storageService.restoreImage(item), 
                  'Image Posted Successfully.'
                );
              },
            ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete Permanently'), 
                onTap: () async {
                  Navigator.of(context).pop(); 
                  await _handleAction(
                    context, 
                    () => storageService.permanentlyDeleteImage(item), 
                    'Image moved to Recently Deleted.',
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