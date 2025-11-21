import 'package:flutter/material.dart';
import '../processes/storage_service.dart';
import '../models/bin_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'posted_screen.dart';
import 'bin_preview_screen.dart'; // Added this import
import '../my_scaffold.dart'; // Kept from alpha-version
import '../objects/globals.dart'; // Kept from alpha-version

const Color _kPrimarySelectionColor = Color.fromARGB(255, 33, 150, 243);

class BinScreen extends StatefulWidget {
  const BinScreen({super.key});

  @override
  State<BinScreen> createState() => _BinScreenState();
}

class _BinScreenState extends State<BinScreen> {
  late Future<List<BinItem>> _binImagesFuture;
  bool _isMultiSelectMode = false;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Use global storageService from alpha-version
    _binImagesFuture = storageService.fetchBinImages();
  }

  void _refreshImages() {
    setState(() {
      _binImagesFuture = storageService.fetchBinImages();
      _selectedIds = {};
      _isMultiSelectMode = false;
    });
  }

  void _toggleSelection(String docId) {
    setState(() {
      if (_selectedIds.contains(docId)) {
        _selectedIds.remove(docId);
      } else {
        _selectedIds.add(docId);
      }

      // If user deselects all, exit multi-select mode
      if (_isMultiSelectMode && _selectedIds.isEmpty) {
        _isMultiSelectMode = false;
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedIds.clear();
      _isMultiSelectMode = false;
    });
  }

  void _handleDeleteBulk() async {
    if (_selectedIds.isEmpty) return;

    final images = await _binImagesFuture;
    if (!mounted) return;
    final selectedImages =
        images.where((img) => _selectedIds.contains(img.id)).toList();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Images Permanently?'),
        content: Text(
            'Are you sure you want to delete ${selectedImages.length} images permanently? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close confirm dialog
              
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              for (var item in selectedImages) {
                await storageService.permanentlyDeleteFromBin(item);
              }

              if (context.mounted) {
                Navigator.pop(context); // Close loading indicator
              }
              
              _refreshImages(); // Refreshes list and clears selection

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        '${selectedImages.length} images deleted permanently.')));
              }
            },
            child: const Text('Confirm Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Helper function from your new code
  String _formatDuration(Duration duration) {
    if (duration.inDays > 1) {
      return '${duration.inDays} days left';
    } else if (duration.inDays == 1) {
      return '1 day left';
    } else if (duration.inHours > 1) {
      return '${duration.inHours} hours left';
    } else if (duration.inHours == 1) {
      return '1 hour left';
    } else if (duration.inMinutes > 1) {
      return '${duration.inMinutes} minutes left';
    } else {
      return 'Expires soon';
    }
  }

  // Kept from alpha-version
  Widget _shadowedIcon(IconData iconData,
      {required Color color, required double size}) {
    return Text(
      String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        inherit: false,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        fontSize: size,
        color: color,
        shadows: const [
          Shadow(
              blurRadius: 3.0,
              color: Color.fromARGB(255, 121, 103, 103),
              offset: Offset(0.5, 0.5))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 239, 220, 224),
      body: Container( // Kept from alpha-version
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              _buildRecentsBar(context),
              Expanded(
                child: FutureBuilder<List<BinItem>>(
                  future: _binImagesFuture,
                  builder: (context, snapshot) {
                    final images = snapshot.data ?? [];

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error.toString()}',
                              style: const TextStyle(color: Colors.white70)));
                    }
                    if (images.isEmpty) {
                      return const Center(
                          child: Text('No images in bin.',
                              style: TextStyle(color: Colors.grey)));
                    }

                    return GridView.builder(
                      padding:
                          const EdgeInsets.only(top: 5, right: 2, left: 2, bottom: 5),
                      itemCount: images.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2.0,
                        mainAxisSpacing: 2.0,
                        childAspectRatio: 0.7,
                      ),
                      itemBuilder: (context, index) {
                        final item = images[index];
                        
                        // Calculate remaining time
                        final remainingTime =
                            item.expireAt.toDate().difference(DateTime.now());

                        return _BinGridTile(
                          item: item,
                          isSelected: _selectedIds.contains(item.id),
                          isMultiSelectMode: _isMultiSelectMode,
                          onToggleSelect: _toggleSelection,
                          remainingTime: _formatDuration(remainingTime),
                          onRefresh: _refreshImages,
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

  // This header is updated with your new logic
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(top: 5, bottom: 1, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _isMultiSelectMode
              ? TextButton.icon(
                  onPressed: _deselectAll,
                  icon: const Icon(Icons.close,
                      color: Color.fromARGB(255, 250, 132, 154), size: 15),
                  label: const Text('Deselect All',
                      style: TextStyle(
                          color: Color.fromARGB(255, 250, 132, 154))),
                )
              : IconButton(
                  icon: _shadowedIcon(Icons.close,
                      color: const Color.fromARGB(255, 37, 6, 6), size: 25),
                  onPressed: () => Navigator.pop(context),
                ),
          
          // "Delete" button with new multi-select toggle logic
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                if (!_isMultiSelectMode) {
                  // Enter multi-select mode
                  _isMultiSelectMode = true;
                  _selectedIds.clear();
                } else if (_selectedIds.isNotEmpty) {
                  // Perform bulk delete
                  _handleDeleteBulk();
                } else {
                  // Exit multi-select mode if no items are selected
                  _isMultiSelectMode = false;
                }
              });
            },
            icon: Icon(
              _isMultiSelectMode ? Icons.delete_forever : Icons.delete,
              size: 18,
            ),
            label: Text(
              _isMultiSelectMode
                  ? 'Delete (${_selectedIds.length})'
                  : 'Delete',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  // Kept from alpha-version, unchanged
  Widget _buildRecentsBar(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Recents',
              style: TextStyle(
                  color: Color.fromARGB(255, 37, 6, 6),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          IconButton(
            icon: const Icon(Icons.outbox, color: Color.fromARGB(255, 37, 6, 6)),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const PostedScreen()));
            },
          ),
        ],
      ),
    );
  }
}

// This is your new _BinGridTile class
class _BinGridTile extends StatelessWidget {
  final BinItem item;
  final bool isSelected;
  final Function(String) onToggleSelect;
  final bool isMultiSelectMode;
  final String remainingTime;
  final VoidCallback onRefresh;

  const _BinGridTile({
    required this.item,
    required this.isSelected,
    required this.onToggleSelect,
    required this.isMultiSelectMode,
    required this.remainingTime,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isMultiSelectMode) {
          onToggleSelect(item.id);
        } else {
          // Navigate to preview screen
          Navigator.pushNamed(
            context,
            "/journal",
            arguments: <dynamic> [item.imageUrl, item]
          ).then((didPost) {
            // Check if the preview screen popped with 'true' (meaning post was successful)
            if (didPost == true) {
              onRefresh();
            }
          });
        }
      },
      child: ClipRRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: Colors.black.withAlpha(100)),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),

            // Gradient for text visibility
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black54],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Selection overlay
            Container(
              color: isSelected
                  ? _kPrimarySelectionColor.withOpacity(0.4)
                  : Colors.transparent,
            ),

            // Checkbox (only in multi-select mode)
            if (isMultiSelectMode)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_box, size: 18, color: Colors.blue)
                      : const Icon(Icons.check_box_outline_blank,
                          size: 18, color: Colors.grey),
                ),
              ),

            // Remaining time
            Positioned(
              bottom: 5,
              left: 5,
              right: 5,
              child: Text(
                isSelected ? '' : remainingTime,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 2.0, color: Colors.black)]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}