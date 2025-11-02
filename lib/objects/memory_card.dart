import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MemoryCard extends StatefulWidget {
  final String? imageUrl;
  final String description;
  final String addressString;
  final VoidCallback? onClose;
  final Color borderColor;
  final double borderWidth;
  final bool isClosing;

  const MemoryCard({
    super.key,
    this.imageUrl,
    required this.description,
    required this.addressString,
    this.onClose,
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.isClosing = false,
  });

  @override
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void didUpdateWidget(covariant MemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isClosing) {
      _animateOut();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Use easeOut curve for entry animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start off-screen at bottom
      end: Offset.zero, // End at normal position
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animation when widget is created
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _animateOut() async {
    // Create new animation with easeIn curve for exit
    final exitAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInCubic,
    ));
    
    setState(() {
      _slideAnimation = exitAnimation;
    });
    
    await _controller.reverse();
    if (widget.onClose != null) {
      widget.onClose!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Positioned(
      top: screenHeight * 0.3,
      left: 16,
      right: 16,
      bottom: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide.none
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image section
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20 - widget.borderWidth),
                        topRight: Radius.circular(20 - widget.borderWidth),
                      ),
                      child: Container(
                        margin: EdgeInsets.all(5),
                        child: 
                        widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.imageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade300,
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 60,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Icon(
                                  Icons.photo_library,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                      )
                    ),
                    // Close button
                    if (widget.onClose != null)
                      Positioned(
                        top: 8,
                        height: 30,
                        width: 30,
                        right: 8,
                        child: IconButton(
                            icon: const Icon(Icons.close, color: Color.fromARGB(255, 139, 132, 132)),
                            onPressed: _animateOut,
                            padding: const EdgeInsets.all(1),
                          ),
                        ),
                  ],
                ),
              ),
              
              // Content section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            widget.description,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.addressString,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}