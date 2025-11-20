//memory_card.dart
import 'package:presentation/objects/globals.dart';
import 'package:presentation/processes/comment_service.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'memory.dart';

class MemoryCard extends StatefulWidget {
  final List<MemoryData> memories;
  final MemoryData selectedMemory;
  final VoidCallback? onClose;
  final bool isClosing;

  const MemoryCard({
    super.key,
    required this.memories,
    required this.selectedMemory,
    this.onClose,
    this.isClosing = false,
  });

  @override
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard> with SingleTickerProviderStateMixin {
  Map<int, bool> _expandedReplies = {};
  Map<int, List<CommentData>> _repliesCache = {};
  Map<int, bool> _loadingReplies = {};
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late PageController _pageController;
  
  int _currentIndex = 0;
  bool _showComments = false;
  List<CommentData> _comments = [];
  bool _isLoadingComments = false;
  bool _isLiked = false;
  bool _isLoadingLike = false;
  int? _replyingToCommentId;
  String? _replyingToUserName;
  bool _isWishlisted = false;
  bool _isDescriptionExpanded = false;
  
  int _likesCount = 0;
  int _commentsCount = 0;

  Map<int, Map<String, dynamic>> _statsCache = {}; // Cache for stats
  Map<int, bool> _likedCache = {}; // Cache for liked status
  Map<String, bool> _wishlistCache = {}; // Cache for wishlist status

  final TextEditingController _commentController = TextEditingController();
  
  String _getMemoryRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 0) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return difference.inMinutes == 0 ? 'Just now' : '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 28) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      // 4 weeks or more - show date as MM-DD-YYYY
      final month = timestamp.month.toString().padLeft(2, '0');
      final day = timestamp.day.toString().padLeft(2, '0');
      return '$month-$day-${timestamp.year}';
      }
    }
  @override
  void initState() {
    super.initState();
    
    _currentIndex = widget.memories.indexWhere(
      (m) => m.position == widget.selectedMemory.position && 
             m.addressString == widget.selectedMemory.addressString
    );
    if (_currentIndex == -1) _currentIndex = 0;
    
    _pageController = PageController(initialPage: _currentIndex);
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _controller.forward();
    _loadMemoryStats();
    _prefetchAdjacentMemoryStats();

    _commentController.addListener(() {
    setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _animateOut() async {
    await _controller.reverse();
    if (widget.onClose != null) {
      widget.onClose!();
    }
  }

  Future<void> _loadMemoryStats() async {
    final currentMemory = widget.memories[_currentIndex];
    final supabaseMemoryId = currentMemory.supabaseMemoryId;
    final memoryId = currentMemory.memoryId;
  
    if (supabaseMemoryId == null) {
      setState(() {
        _likesCount = 0;
        _commentsCount = 0;
        _isLiked = false;
        _isWishlisted = false;
      });
      return;
    }

    // Check cache first
    if (_statsCache.containsKey(supabaseMemoryId)) {
      setState(() {
        _likesCount = _statsCache[supabaseMemoryId]!['likes'] ?? 0;
        _commentsCount = _statsCache[supabaseMemoryId]!['comments'] ?? 0;
        _isLiked = _likedCache[supabaseMemoryId] ?? false;
        _isWishlisted = _wishlistCache[memoryId ?? ''] ?? false;
      });
      return;
    }

    // If not cached, fetch from network
    try {
      final stats = await commentsService.getMemoryStats(supabaseMemoryId);
      final isLiked = await commentsService.checkIfMemoryLiked(supabaseMemoryId);
    
      // Check wishlist status
      final currentUser = FirebaseAuth.instance.currentUser;
      bool isWishlisted = false;
      if (currentUser != null && memoryId != null) {
        final firestore = FirebaseFirestore.instance;
        final wishlistRef = firestore
            .collection('wishlist')
            .doc('${memoryId}_${currentUser.uid}');
        final doc = await wishlistRef.get();
        isWishlisted = doc.exists;
      }

      // Store in cache
      _statsCache[supabaseMemoryId] = stats;
      _likedCache[supabaseMemoryId] = isLiked;
      if (memoryId != null) {
        _wishlistCache[memoryId] = isWishlisted;
      }

      setState(() {
        _likesCount = stats['likes'] ?? 0;
        _commentsCount = stats['comments'] ?? 0;
        _isLiked = isLiked;
        _isWishlisted = isWishlisted;
      });
    } catch (e) {
      print('Error loading memory stats: $e');
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    
    try {
      final currentMemory = widget.memories[_currentIndex];
      final supabaseMemoryId = currentMemory.supabaseMemoryId;
      
      if (supabaseMemoryId == null) {
        setState(() {
          _comments = [];
          _isLoadingComments = false;
        });
        return;
      }

      final memoryOwnerId = currentMemory.userId ?? '';
      final loadedComments = await commentsService.loadComments(
        supabaseMemoryId,
        memoryOwnerId,
      );

      setState(() {
        _comments = loadedComments;
        _isLoadingComments = false;
      });
    } catch (e) {
      print('❌ Error loading comments: $e');
      setState(() => _isLoadingComments = false);
    }
  }

  void _resetCommentState() {
    setState(() {
      _showComments = false;
      _comments = [];
      _expandedReplies = {};
      _repliesCache = {};
      _loadingReplies = {};
      _replyingToCommentId = null;
      _replyingToUserName = null;
      _commentController.clear();
      _isDescriptionExpanded = false;
    });
  }

  void _toggleComments() {
    if (_showComments) {
      // When closing comments, just reset comment state without affecting page
      setState(() {
        _showComments = false;
        _comments = [];
        _expandedReplies = {};
        _repliesCache = {};
        _loadingReplies = {};
        _replyingToCommentId = null;
        _replyingToUserName = null;
        _commentController.clear();
      });
    } else {
      // When opening comments, load them
      _loadComments();
      setState(() {
        _showComments = true;
      });
    }
  }

  // Load replies for a specific comment
  Future<void> _loadReplies(int commentId) async {
    setState(() => _loadingReplies[commentId] = true);
  
    try {
      final currentMemory = widget.memories[_currentIndex];
      final memoryOwnerId = currentMemory.userId ?? '';
    
      final replies = await commentsService.loadReplies(
        commentId,
        memoryOwnerId,
      );
    
      setState(() {
        _repliesCache[commentId] = replies;
        _expandedReplies[commentId] = true;
        _loadingReplies[commentId] = false;
      });
    } catch (e) {
      print('❌ Error loading replies: $e');
      setState(() => _loadingReplies[commentId] = false);
    }
  }

  // Toggle replies expansion
  void _toggleReplies(int commentId) {
    if (_expandedReplies[commentId] == true) {
      // Collapse
      setState(() => _expandedReplies[commentId] = false);
    } else {
      // Expand - load replies if not cached
      if (_repliesCache[commentId] == null) {
        _loadReplies(commentId);
      } else {
        setState(() => _expandedReplies[commentId] = true);
      }
    }
  }

  Future<void> _handleLike() async {
    if (_isLoadingLike) return;
    
    final currentMemory = widget.memories[_currentIndex];
    final supabaseMemoryId = currentMemory.supabaseMemoryId;
    
    if (supabaseMemoryId == null) return;

    setState(() => _isLoadingLike = true);

    try {
      await commentsService.toggleMemoryLike(supabaseMemoryId);
      
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
        // Update cache
        _statsCache[supabaseMemoryId] = {'likes': _likesCount, 'comments': _commentsCount};
        _likedCache[supabaseMemoryId] = _isLiked;
      });
    } catch (e) {
      print('Error handling like: $e');
    } finally {
      setState(() => _isLoadingLike = false);
    }
  }

  Future<void> _handleWishlist() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final currentMemory = widget.memories[_currentIndex];
      final memoryId = currentMemory.memoryId;
      
      if (memoryId == null) return;

      final firestore = FirebaseFirestore.instance;
      final wishlistRef = firestore
          .collection('wishlist')
          .doc('${memoryId}_${currentUser.uid}');

      final doc = await wishlistRef.get();

      if (doc.exists) {
        await wishlistRef.delete();
        setState(() { 
          _isWishlisted = false;
           _wishlistCache[memoryId] = false;
        });
      } else {
        await wishlistRef.set({
          'memoryId': memoryId,
          'userId': currentUser.uid,
          'latitude': currentMemory.position.latitude,
          'longitude': currentMemory.position.longitude,
          'addressString': currentMemory.addressString,
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() { 
          _isWishlisted = true;
          _wishlistCache[memoryId] = true;
        });
      }
    } catch (e) {
      print('Error handling wishlist: $e');
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentMemory = widget.memories[_currentIndex];
    final supabaseMemoryId = currentMemory.supabaseMemoryId;

    if (supabaseMemoryId == null) return;

    try {
      final replyToCommentId = _replyingToCommentId;

      await commentsService.postComment(
        memoryId: supabaseMemoryId,
        text: text,
        replyToCommentId: _replyingToCommentId,
      );

      _commentController.clear();

      // Always increment comment count
      setState(() {
        _commentsCount++;
        // Update cache
        _statsCache[supabaseMemoryId] = {'likes': _likesCount, 'comments': _commentsCount};
        _replyingToCommentId = null;
        _replyingToUserName = null;
      });

      // Reload comments first
      await _loadComments();

      // Small delay to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 100));

      // If it was a reply, reload those replies to show the new one
      if (replyToCommentId != null) {
        await _loadReplies(replyToCommentId);
      }

    } catch (e) {
      print('❌ Error sending comment: $e');
    }
  }

  Future<void> _prefetchAdjacentMemoryStats() async {
    // Prefetch previous memory
    if (_currentIndex > 0) {
      final prevMemory = widget.memories[_currentIndex - 1];
      final prevSupabaseId = prevMemory.supabaseMemoryId;
      final prevMemoryId = prevMemory.memoryId;
    
      if (prevSupabaseId != null && !_statsCache.containsKey(prevSupabaseId)) {
        try {
          final stats = await commentsService.getMemoryStats(prevSupabaseId);
          final isLiked = await commentsService.checkIfMemoryLiked(prevSupabaseId);
          _statsCache[prevSupabaseId] = stats;
          _likedCache[prevSupabaseId] = isLiked;
        
          // Prefetch wishlist
          if (prevMemoryId != null) {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              final firestore = FirebaseFirestore.instance;
              final wishlistRef = firestore
                  .collection('wishlist')
                  .doc('${prevMemoryId}_${currentUser.uid}');
              final doc = await wishlistRef.get();
              _wishlistCache[prevMemoryId] = doc.exists;
            }
          }
        } catch (e) {
          print('Error prefetching prev memory stats: $e');
        }
      }
    }
  
    // Prefetch next memory
    if (_currentIndex < widget.memories.length - 1) {
      final nextMemory = widget.memories[_currentIndex + 1];
      final nextSupabaseId = nextMemory.supabaseMemoryId;
      final nextMemoryId = nextMemory.memoryId;
    
      if (nextSupabaseId != null && !_statsCache.containsKey(nextSupabaseId)) {
        try {
          final stats = await commentsService.getMemoryStats(nextSupabaseId);
          final isLiked = await commentsService.checkIfMemoryLiked(nextSupabaseId);
          _statsCache[nextSupabaseId] = stats;
          _likedCache[nextSupabaseId] = isLiked;
        
          // Prefetch wishlist
          if (nextMemoryId != null) {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              final firestore = FirebaseFirestore.instance;
              final wishlistRef = firestore
                  .collection('wishlist')
                  .doc('${nextMemoryId}_${currentUser.uid}');
              final doc = await wishlistRef.get();
              _wishlistCache[nextMemoryId] = doc.exists;
            }
          }
        } catch (e) {
          print('Error prefetching next memory stats: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // Tap outside to close
        Positioned.fill(
          child: GestureDetector(
            onTap: _animateOut,
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
        ),
      
        // The actual card
        Positioned(
          top: screenHeight * 0.3,
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            children: [
              // Address above card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.memories[_currentIndex].addressString,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {}, // Prevents tap from propagating to background
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 8,
                    color: Colors.transparent,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      side: BorderSide.none
                    ),
                    child: Column(
                      children: [
                        // Drawer handle at the very top
                        Container(
                          margin: const EdgeInsets.only(top: 6, bottom: 2),
                          width: 32,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // The actual content
                        Expanded(
                          child: Stack(
                            children: [
                              _buildMemoryView(),
                              if (_showComments)
                                _buildCommentsView(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
    );
  }

  Widget _buildMemoryView() {
  // Ensure PageController is on the right page
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_pageController.hasClients && 
        _pageController.page?.round() != _currentIndex) {
      _pageController.jumpToPage(_currentIndex);
    }
  });
  
  return Padding(
    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // PageView with images
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _isDescriptionExpanded = false;
                _showComments = false;
                _comments = [];
                _expandedReplies = {};
                _repliesCache = {};
                _loadingReplies = {};
                _replyingToCommentId = null;
                _replyingToUserName = null;
                _commentController.clear();
              });
              _loadMemoryStats();
              _prefetchAdjacentMemoryStats();
            },
            itemCount: widget.memories.length,
            itemBuilder: (context, index) {
              final memory = widget.memories[index];
              final isCurrentPage = index == _currentIndex;
              
              return Stack(
                children: [
                  // Image
                  Positioned.fill(
                    child: memory.imageUrl != null && memory.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: memory.imageUrl!,
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
                  ),

                  // Bottom gradient overlay (per page)
                  if (isCurrentPage)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 280,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.7),
                                Colors.black.withOpacity(0.85),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Tap area to collapse description (covers entire screen except buttons)
                  if (isCurrentPage && _isDescriptionExpanded)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDescriptionExpanded = false;
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),

                  // Content overlay - username and description (per page, behind buttons)
                  if (isCurrentPage)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        ignoring: false,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(8, 20, 8, 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Owner name and timestamp
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.grey.shade300,
                                    child: Text(
                                      memory.userName != null
                                          ? memory.userName![0].toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          memory.userName ?? 'Unknown User',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (memory.timestamp != null)
                                          Text(
                                            _getMemoryRelativeTime(memory.timestamp!),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Add padding on right to avoid buttons
                                  const SizedBox(width: 60),
                                ],
                              ),

                              // Description
                              if (memory.description != null && memory.description!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isDescriptionExpanded = !_isDescriptionExpanded;
                                    });
                                  },
                                  child: AnimatedSize(
                                    duration: const Duration(milliseconds: 200),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: _isDescriptionExpanded ? 150 : 40,
                                      ),
                                      child: ScrollConfiguration(
                                        behavior: ScrollConfiguration.of(context).copyWith(
                                          scrollbars: false,
                                        ),
                                        child: SingleChildScrollView(
                                          physics: _isDescriptionExpanded
                                              ? const ClampingScrollPhysics()
                                              : const NeverScrollableScrollPhysics(),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                memory.description!,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  height: 1.4,
                                                  color: Colors.white,
                                                ),
                                                maxLines: _isDescriptionExpanded ? null : 1,
                                                overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
                                              ),
                                              if (!_isDescriptionExpanded && memory.description!.length > 30)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Text(
                                                    'See more...',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey.shade400,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Action buttons (per page, on top of description)
                  if (isCurrentPage)
                    Positioned(
                      right: 8,
                      bottom: 80,
                      child: Column(
                        children: [
                          _buildActionButton(
                            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                            label: _formatCount(_likesCount),
                            onTap: _handleLike,
                            isActive: _isLiked,
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            icon: Icons.chat_bubble_outline,
                            label: _formatCount(_commentsCount),
                            onTap: _toggleComments,
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            icon: _isWishlisted ? Icons.bookmark : Icons.bookmark_border,
                            label: 'Wishlist',
                            onTap: _handleWishlist,
                            isActive: _isWishlisted,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

Widget _buildActionButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  bool isActive = false,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: 28, 
            color: isActive ? (icon == Icons.favorite ? Colors.red : Colors.white) : Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCommentsView() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
            // Header
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: _toggleComments,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Comments',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
        
            // Comments list
            Expanded(
              child: _isLoadingComments
                  ? const Center(child: CircularProgressIndicator(color: Colors.black87))
                  : _comments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No comments yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to comment!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            return _buildCommentItem(_comments[index]);
                          },
                        ),
            ),
        
            // Comment input
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyingToUserName != null)
                    Container(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            'Replying to $_replyingToUserName',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _replyingToCommentId = null;
                                _replyingToUserName = null;
                                _commentController.clear();
                              });
                            },
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey.shade300,
                        child: Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendComment(),
                        ),
                      ),
                      if (_commentController.text.isNotEmpty)
                        TextButton(
                          onPressed: _sendComment,
                          child: const Text(
                            'Post',
                            style: TextStyle(
                              color: Color(0xFFF75270),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(CommentData comment) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnComment = currentUser?.uid == comment.userId;
    final isExpanded = _expandedReplies[comment.id] ?? false;
    final isLoadingReplies = _loadingReplies[comment.id] ?? false;
    final replies = _repliesCache[comment.id] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  comment.userName[0].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comment.getRelativeTime(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (comment.isAuthor) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Author',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.text,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            try {
                              await commentsService.toggleCommentLike(comment.id);
                              await _loadComments();
                            } catch (e) {
                              print('Error liking comment: $e');
                            }
                          },
                          child: Text(
                            comment.likesCount > 0 
                                ? '${comment.getFormattedLikesCount()} likes'
                                : 'Like',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _replyingToCommentId = comment.id;
                              _replyingToUserName = comment.userName;
                              _commentController.text = '@${comment.userName} ';
                            });
                          },
                          child: Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isOwnComment) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () async {
                              try {
                                await commentsService.deleteComment(comment.id);
                                _repliesCache.remove(comment.id);
                                _expandedReplies.remove(comment.id);
                                // Decrement by 1 + number of replies
                                final totalDeleted = 1 + (comment.repliesCount);
                                await _loadComments();
                                setState(() => _commentsCount--);
                              } catch (e) {
                                print('Error deleting comment: $e');
                              }
                            },
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  
                    // View replies button
                    if (comment.repliesCount > 0) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _toggleReplies(comment.id),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 1,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded 
                                  ? Icons.keyboard_arrow_up 
                                  : Icons.arrow_forward,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isExpanded 
                                  ? 'Hide replies'
                                  : comment.getRepliesText(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (comment.isLikedByMe)
                const Icon(
                  Icons.favorite,
                  size: 12,
                  color: Colors.red,
                ),
            ],
          ),
        ),
      
        // Expanded replies section
        if (isExpanded && !isLoadingReplies)
          ...replies.map((reply) => _buildReplyItem(reply, comment.id)),
      
        // Loading indicator for replies
        if (isLoadingReplies)
          Padding(
            padding: const EdgeInsets.only(left: 60, top: 8, bottom: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey.shade400,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReplyItem(CommentData reply, int parentCommentId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnReply = currentUser?.uid == reply.userId;

    return Padding(
      padding: const EdgeInsets.only(left: 44, right: 16, top: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 2,
            height: 32,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.only(right: 12, top: 4),
          ),
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey.shade300,
            child: Text(
              reply.userName[0].toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      reply.getRelativeTime(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (reply.isAuthor) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'Author',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  reply.text,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        try {
                          await commentsService.toggleCommentLike(reply.id);
                          _loadReplies(parentCommentId); // Reload replies
                        } catch (e) {
                          print('Error liking reply: $e');
                        }
                      },
                      child: Text(
                        reply.likesCount > 0 
                            ? '${reply.getFormattedLikesCount()} likes'
                            : 'Like',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _replyingToCommentId = parentCommentId;
                          _replyingToUserName = reply.userName;
                          _commentController.text = '@${reply.userName} ';
                        });
                      },
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isOwnReply) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () async {
                          try {
                            await commentsService.deleteComment(reply.id);
                            setState(() => _commentsCount--);
                            await _loadReplies(parentCommentId); // Reload replies
                            await _loadComments(); // Reload comments to update reply count
                          } catch (e) {
                            print('Error deleting reply: $e');
                          }
                        },
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (reply.isLikedByMe)
            const Icon(
              Icons.favorite,
              size: 10,
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) {
      final k = (count / 1000).toStringAsFixed(1);
      return k.endsWith('.0') ? '${count ~/ 1000}k' : '${k}k';
    }
    final m = (count / 1000000).toStringAsFixed(1);
    return m.endsWith('.0') ? '${count ~/ 1000000}M' : '${m}M';
  }
}

// Keep existing CommentData class unchanged
class CommentData {
  final int id;
  final String userName;
  final String userId;
  final String text;
  final DateTime timestamp;
  final int? repliedCommentID;
  final int? headcommentid;
  final int likesCount;
  final int repliesCount;
  final bool isLikedByMe;
  final bool isAuthor;
  final CommentData? latestReply;

  CommentData({
    required this.id,
    required this.userName,
    required this.userId,
    required this.text,
    required this.timestamp,
    this.repliedCommentID,
    this.headcommentid,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.isLikedByMe = false,
    this.isAuthor = false,
    this.latestReply,
  });

  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 0) {
    // Handle future timestamps (clock sync issues)
    return 'Just now';
    } else if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 28) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w';
    } else {
      // 4 weeks or more - show date as MM-DD-YYYY
      final month = timestamp.month.toString().padLeft(2, '0');
      final day = timestamp.day.toString().padLeft(2, '0');
      return '$month-$day-${timestamp.year}';
    }
  }

  String getFormattedLikesCount() {
    if (likesCount < 1000) return likesCount.toString();
    if (likesCount < 1000000) {
      final k = (likesCount / 1000).toStringAsFixed(1);
      return '${k}k';
    }
    final m = (likesCount / 1000000).toStringAsFixed(1);
    return '${m}M';
  }

  String getRepliesText() {
    if (repliesCount == 0) return '';
    if (repliesCount == 1) return 'View 1 reply';
    return 'View all $repliesCount replies';
  }
}