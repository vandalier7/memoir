import 'package:flutter/material.dart';
import '../processes/storage_service.dart'; 
import '../models/bin_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'posted_screen.dart'; // Navigation
import 'package:firebase_auth/firebase_auth.dart'; 

// Constants for Design and Logic
const Color _kPrimarySelectionColor = Color.fromARGB(255, 33, 150, 243); // Blue for selection overlay
const Color _kDarkBackground = Color.fromARGB(255, 32, 28, 29);

class BinScreen extends StatefulWidget {
  const BinScreen({super.key});

  @override
  State<BinScreen> createState() => _BinScreenState();
}

class _BinScreenState extends State<BinScreen> {
  final StorageService _storageService = StorageService(); 
  late Future<List<BinItem>> _binImagesFuture;
  
  // State to track selected items
  Set<String> _selectedIds = {}; 

  @override
  void initState() {
    super.initState();
    _binImagesFuture = _storageService.fetchBinImages();
  }

  void _refreshImages() {
    setState(() {
      _binImagesFuture = _storageService.fetchBinImages();
      _selectedIds = {}; // Clear selection on refresh
    });
  }

  // Toggles selection state (called by the grid item)
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }
  
  // Selects all visible images
  void _selectAll(List<BinItem> images) {
    setState(() {
      _selectedIds = Set.from(images.map((img) => img.fileName));
    });
  }

  // Deselects all visible images
  void _deselectAll() {
    setState(() {
      _selectedIds.clear();
    });
  }

  // Handler for bulk POST action (Restore to Posted)
  // lib/screens/bin_screen.dart (Inside _BinScreenState class)

  void _handlePostBulk() async { // MUST be async now
    if (_selectedIds.isEmpty) return;
    
    // 🛑 FIX: Safely await the Future to get the list of images
    // This is the functional equivalent of the failed .value attempt, but correct.
    final images = await _binImagesFuture; 
    
    // Now you can safely use the images list:
    final selectedImages = images.where((img) => _selectedIds.contains(img.fileName)).toList();
    
    // Execute logic...
    for (var item in selectedImages) {
        await _storageService.restoreImage(item); 
    }

    _selectedIds.clear(); 
    _refreshImages(); 
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${selectedImages.length} images posted successfully!')));
} 

  // Handler for bulk DELETE action (Soft Delete to Pending)
  void _handleDeleteBulk(List<BinItem> images) {
    if (_selectedIds.isEmpty) return;
    
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
              // Execute soft deletion (move to PENDING_DELETE)
              for (var item in selectedImages) {
                  await _storageService.permanentlyDeleteImage(item);
              }
              
              Navigator.pop(context); // Close dialog
              _selectedIds.clear(); 
              _refreshImages(); 
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${selectedImages.length} images deleted permanently.')));
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  // Helper for displaying shadowed icons (copied from previous steps)
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
    // We use the custom dark header structure
    return Scaffold(
        backgroundColor: _kDarkBackground,
        body: Container(
            decoration: const BoxDecoration(
                gradient: RadialGradient(
                    colors: [ 
                        Color.fromARGB(255, 250, 227, 194), 
                        Color.fromARGB(255, 253, 192, 203), 
                        _kDarkBackground, 
                    ],
                    radius: 1.5, 
                ),
            ),
            child: SafeArea ( 
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        // HEADER WITH MULTI-SELECT ACTIONS
                        _buildHeader(context),
                        
                        // RECENTS BAR
                        _buildRecentsBar(context),

                        // GRID VIEW AREA
                        Expanded(
                            child: FutureBuilder<List<BinItem>>(
                                future: _binImagesFuture,
                                builder: (context, snapshot) {
                                    // ... (Error and loading handling) ...
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
                                            return _BinGridTile( // Updated tile
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
  
  // Custom Header Builder (Matches video functionality)
  Widget _buildHeader(BuildContext context) {
    final isSelecting = _selectedIds.isNotEmpty;
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(top: 5, bottom: 1, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Side: Close or Deselect/Select All Button
          isSelecting
              ? TextButton.icon(
                  onPressed: _deselectAll,
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  label: const Text('Deselect All', style: TextStyle(color: Colors.white)),
                )
              : IconButton( // Close Button (X)
                  icon: _shadowedIcon(Icons.close, color: Colors.black, size: 25),
                  onPressed: () async {},
                ),
          
          // Right Side: Post and Delete Buttons
          Row(
            children: [
              // Post Button
              ElevatedButton.icon(
                onPressed: isSelecting ? _handlePostBulk : null,
                icon: const Icon(Icons.upload, size: 18),
                label: Text('Post (${_selectedIds.length})'),
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimarySelectionColor),
              ),
              const SizedBox(width: 8),
              // Delete Button
              ElevatedButton.icon(
                onPressed: isSelecting ? _handlePostBulk : null,
                icon: const Icon(Icons.delete_forever, size: 18),
                label: Text('Delete (${_selectedIds.length})'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Custom Recents Bar Builder
  Widget _buildRecentsBar(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Recents', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          // Navigation to Posted Screen
          IconButton(
            icon: const Icon(Icons.outbox, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PostedScreen()));
            },
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _BinGridTile (Modified for Selection and Visuals)
// -----------------------------------------------------------------------------
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
    return GestureDetector( // Handles tapping for selection
      onTap: () => onToggleSelect(item.fileName), // Use file name as the unique ID
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.0), // Subtle rounded corners
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image Display
            CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.black.withAlpha(100)),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),

            // 1. Selection Overlay (Dark Blue Tint when selected)
            Container(
              color: isSelected ? _kPrimarySelectionColor.withOpacity(0.4) : Colors.transparent,
            ),
            
            // 2. Checkbox and Top Right Corner
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
            
            // 3. Status/Title Overlay
            Positioned(
              bottom: 5,
              left: 5,
              child: Text(
                // Use file name as a visible identifier
                isSelected ? 'Selected' : item.fileName, 
                style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}