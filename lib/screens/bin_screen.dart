import 'dart:async';

import 'package:flutter/material.dart';
import '../processes/storage_service.dart';
import '../models/bin_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'posted_screen.dart';
import '../my_scaffold.dart';
import '../objects/globals.dart';

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

      if (_isMultiSelectMode && _selectedIds.isEmpty) {
        // _isMultiSelectMode = false;
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
              Navigator.pop(dialogContext);
              
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
                Navigator.pop(context);
              }
              
              _refreshImages();

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

  String _formatDuration(Duration duration) {
    if (duration.inDays > 1) {
      return '${duration.inDays}d';
    } else if (duration.inDays == 1) {
      return '1d';
    } else if (duration.inHours >= 1 && duration.inMinutes % 60 != 0)  {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inHours >= 1)  {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 1) {
      return '${duration.inMinutes}m';
    } else {
      return 'Expires soon';
    }
  }

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
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
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
                            style: TextStyle(color: Color.fromARGB(255, 65, 65, 65))));
                  }

                  return CustomScrollView(
                    slivers: [
                      // Hint text as a sliver
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.transparent,
                          padding: const EdgeInsets.only(top: 16, left: 15, right: 15, bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'Binned memories expire after 6 hours.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color.fromARGB(255, 37, 6, 6).withOpacity(0.5),
                                      fontWeight: FontWeight.normal,
                                      fontSize: 14
                                    )
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      
                      // Grid of images
                      SliverPadding(
                        padding: const EdgeInsets.only(top: 5, right: 2, left: 2, bottom: 5),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2.0,
                            mainAxisSpacing: 2.0,
                            childAspectRatio: 0.7,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = images[index];
                              final remainingTime =
                                  item.expireAt.toDate().difference(DateTime.now());

                              return _BinGridTile(
                                item: item,
                                isSelected: _selectedIds.contains(item.id),
                                isMultiSelectMode: _isMultiSelectMode,
                                onToggleSelect: _toggleSelection,
                                remainingTime: _formatDuration(remainingTime),
                                timeObject: remainingTime,
                                onRefresh: _refreshImages,
                              );
                            },
                            childCount: images.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 35,     
        left: 12,
        right: 12,
        bottom: 12,  
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            offset: const Offset(0, 4), 
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // LEFT BUTTON
          Align(
            alignment: Alignment.centerLeft,
            child: _isMultiSelectMode
                ? TextButton.icon(
                    onPressed: _deselectAll,
                    icon: const Icon(Icons.close, color: Color.fromARGB(255, 250, 132, 154)),
                    label: const Text('Deselect All',
                        style: TextStyle(color: Color.fromARGB(255, 250, 132, 154))),
                  )
                : GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      color: Colors.transparent,
                      height: 40,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            color: Color.fromARGB(255, 250, 132, 154),
                            size: 20,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Back",
                            style: TextStyle(
                              color: Color.fromARGB(255, 250, 132, 154),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  ),
          ),

          // CENTER TITLE
          const Text(
            "Bin",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),

          // RIGHT BUTTON
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  if (!_isMultiSelectMode) {
                    _isMultiSelectMode = true;
                    _selectedIds.clear();
                  } else if (_selectedIds.isNotEmpty) {
                    _handleDeleteBulk();
                  } else {
                    _isMultiSelectMode = false;
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
              ),
              child: _isMultiSelectMode
                  ? SizedBox(
                    width: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete, color: Color.fromARGB(255, 250, 132, 154)),
                        SizedBox(width: 4,),
                        Text(
                          '${_selectedIds.length}',
                          style: const TextStyle(color: Color.fromARGB(255, 250, 132, 154)),
                        ),
                      ],
                  )
                  )
                    
                  
                  
                  : const Icon(Icons.delete, color: Color.fromARGB(255, 250, 132, 154)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BinGridTile extends StatelessWidget {
  final BinItem item;
  final bool isSelected;
  final Function(String) onToggleSelect;
  final bool isMultiSelectMode;
  final String remainingTime;
  final Duration timeObject;
  final VoidCallback onRefresh;

  const _BinGridTile({
    required this.item,
    required this.isSelected,
    required this.onToggleSelect,
    required this.isMultiSelectMode,
    required this.remainingTime,
    required this.onRefresh,
    required this.timeObject
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isMultiSelectMode) {
          onToggleSelect(item.id);
        } else {
          Navigator.pushNamed(
            context,
            "/journal",
            arguments: <dynamic> [item.imageUrl, item]
          ).then((didPost) {
            if (didPost == true) {
              onRefresh();
            }
          });
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 4,
                  spreadRadius: 1
                )
              ]
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
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
                      ? _kPrimarySelectionColor.withOpacity(0.2)
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
                  child: Row(
                    children: [
                      Icon(Icons.access_time_sharp, color: timeObject.inMinutes >= 60 ? Colors.white : const Color.fromARGB(255, 236, 105, 96), size: 16),
                      const SizedBox(width: 5),
                      Text(
                        remainingTime,
                        style: TextStyle(
                            color: timeObject.inMinutes >= 60 ? Colors.white : const Color.fromARGB(255, 236, 105, 96),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            shadows: const [Shadow(blurRadius: 2.0, color: Colors.black)]),
                      ),
                    ],
                  )
                ),
              ],
            ),
          ),
        ],
      )
    );
  }
}