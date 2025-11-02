import 'package:flutter/material.dart';
import '../processes/storage_service.dart'; 
import '../models/bin_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'posted_screen.dart';
import '../my_scaffold.dart';

const Color _kPrimarySelectionColor = Color.fromARGB(255, 33, 150, 243); 

class BinScreen extends StatefulWidget {
  const BinScreen({super.key});

  @override
  State<BinScreen> createState() => _BinScreenState();
}

class _BinScreenState extends State<BinScreen> {
  final StorageService _storageService = StorageService(); 
  late Future<List<BinItem>> _binImagesFuture;
  
  Set<String> _selectedIds = {}; 

  @override
  void initState() {
    super.initState();
    _binImagesFuture = _storageService.fetchBinImages();
  }

  void _refreshImages() {
    setState(() {
      _binImagesFuture = _storageService.fetchBinImages();
      _selectedIds = {}; 
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedIds.clear();
    });
  }

  void _handlePostBulk() async {
    if (_selectedIds.isEmpty) return;
    
    final images = await _binImagesFuture; 
    final selectedImages = images.where((img) => _selectedIds.contains(img.fileName)).toList();
    
    for (var item in selectedImages) {
        await _storageService.restoreImage(item); 
    }

    if (!context.mounted) return; 
    
    _selectedIds.clear(); 
    _refreshImages(); 
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${selectedImages.length} images posted successfully!')));
  }

  void _handleDeleteBulk() async {
    if (_selectedIds.isEmpty) return;

    final images = await _binImagesFuture;
    
    if (!mounted) return;
    
    final selectedImages = images.where((img) => _selectedIds.contains(img.fileName)).toList();

    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text('Delete Images Permanently?'),
        content: Text('Are you sure you want to delete ${selectedImages.length} images permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              
              for (var item in selectedImages) {
                  await _storageService.permanentlyDeleteFromBin(item);
              }
              
              if (context.mounted) {
                  Navigator.pop(context); 
              }

              _selectedIds.clear(); 
              _refreshImages(); 

              if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${selectedImages.length} images deleted permanently.')));
              }
            },
            child: const Text('Confirm Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Widget _shadowedIcon(IconData iconData, {required Color color, required double size}) {
    return Text(
      String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        inherit: false,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        fontSize: size,
        color: color,
        shadows: const [Shadow(blurRadius: 3.0, color: Color.fromARGB(255, 121, 103, 103), offset: Offset(0.5, 0.5))],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 239, 220, 224),
        body: Container(   
            child: SafeArea ( 
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
                                    
                                    if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator(color: Colors.white)); }
                                    if (snapshot.hasError) { return Center(child: Text('Error: ${snapshot.error.toString()}', style: const TextStyle(color: Colors.white70))); }
                                    if (images.isEmpty) { return const Center(child: Text('No images in bin.', style: TextStyle(color: Colors.grey))); }

                                    return GridView.builder(
                                        padding: const EdgeInsets.only(top: 5, right: 2, left: 2, bottom: 5),
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
                                                isSelected: _selectedIds.contains(item.fileName),
                                                onToggleSelect: _toggleSelection,
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
  
  Widget _buildHeader(BuildContext context) {
    final isSelecting = _selectedIds.isNotEmpty;
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(top: 5, bottom: 1, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          isSelecting
              ? TextButton.icon(
                  onPressed: _deselectAll,
                  icon: const Icon(Icons.close, color: Color.fromARGB(255, 250, 132, 154), size: 15),
                  label: const Text('Deselect All', style: TextStyle(color: Color.fromARGB(255, 250, 132, 154))),
                )
              : IconButton( 
                  icon: _shadowedIcon(Icons.close, color: Color.fromARGB(255, 37, 6, 6), size: 25),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
          
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: isSelecting ? _handlePostBulk : null,
                icon: const Icon(Icons.upload, size: 18),
                label: Text('Post (${_selectedIds.length})'),
                style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 250, 132, 154), 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: isSelecting ? _handleDeleteBulk : null,
                icon: const Icon(Icons.delete_forever, size: 18),
                label: Text('Delete (${_selectedIds.length})'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentsBar(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Recents', style: TextStyle(color: Color.fromARGB(255, 37, 6, 6), fontWeight: FontWeight.bold, fontSize: 18)),
          IconButton(
            icon: const Icon(Icons.outbox, color: Color.fromARGB(255, 37, 6, 6)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PostedScreen()));
            },
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

  const _BinGridTile({
    required this.item,
    required this.isSelected,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector( 
      onTap: () => onToggleSelect(item.fileName), 
      child: ClipRRect( 
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.black.withAlpha(100)),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),

            Container(
              color: isSelected ? _kPrimarySelectionColor.withOpacity(0.4) : Colors.transparent,
            ),
            
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
                    : const Icon(Icons.check_box_outline_blank, size: 18, color: Colors.grey),
              ),
            ),
            
            Positioned(
              bottom: 5,
              left: 5,
              child: Text(
                isSelected ? '' : item.fileName, 
                style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}