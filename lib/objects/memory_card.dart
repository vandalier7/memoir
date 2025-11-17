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
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late PageController _pageController;
  
  int _currentIndex = 0;
  bool _showComments = false;
  List<CommentData> _comments = [];
  bool _isLoadingComments = false;
  bool _isLiked = false;
  bool _isLoadingLike = false;
  bool _isDescriptionExpanded = false;
  
  int _likesCount = 0;
  int _commentsCount = 0;
  
  final TextEditingController _commentController = TextEditingController();

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
    
    if (supabaseMemoryId == null) return;

    try {
      final stats = await commentsService.getMemoryStats(supabaseMemoryId);
      final isLiked = await commentsService.checkIfMemoryLiked(supabaseMemoryId);
      
      setState(() {
        _likesCount = stats['likes'] ?? 0;
        _commentsCount = stats['comments'] ?? 0;
        _isLiked = isLiked;
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

      final memoryOwnerId = FirebaseAuth.instance.currentUser?.uid ?? '';
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

  void _toggleComments() {
    if (!_showComments) {
      _loadComments();
    }
    setState(() {
      _showComments = !_showComments;
    });
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from wishlist')),
        );
      } else {
        await wishlistRef.set({
          'memoryId': memoryId,
          'userId': currentUser.uid,
          'latitude': currentMemory.position.latitude,
          'longitude': currentMemory.position.longitude,
          'addressString': currentMemory.addressString,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to wishlist! 🗺️')),
        );
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
      await commentsService.postComment(
        memoryId: supabaseMemoryId,
        text: text,
      );

      _commentController.clear();
      _loadComments();
      
      setState(() {
        _commentsCount++;
      });
    } catch (e) {
      print('❌ Error sending comment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      top: screenHeight * 0.3,
      left: 0,
      right: 0,
      bottom: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 8,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            side: BorderSide.none
          ),
          child: Column(  // Wrap everything in a Column
            children: [
              // Drawer handle at the very top
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // The actual content
              Expanded(
                child: _showComments 
                  ? _buildCommentsView()
                  : _buildMemoryView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemoryView() {
  return Stack(  
    children: [
      // Full-screen image as background
      PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          _loadMemoryStats();
        },
        itemCount: widget.memories.length,
        itemBuilder: (context, index) {
          final memory = widget.memories[index];
          return ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: memory.imageUrl != null && memory.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: memory.imageUrl!,
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
          );
        },
      ),
      
      // Close button
      if (widget.onClose != null)
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: _animateOut,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      
      // Page indicator
      if (widget.memories.length > 1)
        Positioned(
          top: 60,  // <-- Moved down from bottom
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.memories.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      
      // Bottom overlay - Description and Location only
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.9),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Description
              if (widget.memories[_currentIndex].description != null && 
                  widget.memories[_currentIndex].description!.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDescriptionExpanded = !_isDescriptionExpanded;
                    });
                  },
                  child: Text(
                    widget.memories[_currentIndex].description!,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.white,
                    ),
                    maxLines: _isDescriptionExpanded ? null : 3,
                    overflow: _isDescriptionExpanded 
                        ? TextOverflow.visible 
                        : TextOverflow.ellipsis,
                  ),
                ),
        
              const SizedBox(height: 12),
        
              // Location
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.memories[_currentIndex].addressString,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
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

      // Action buttons on the right side
      Positioned(
        right: 12,
        bottom: 100,
        child: Column(
          children: [
            _buildActionButton(
              icon: _isLiked ? Icons.favorite : Icons.favorite_border,
              label: _formatCount(_likesCount),
              onTap: _handleLike,
              isActive: _isLiked,
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              icon: Icons.chat_bubble_outline,
              label: _formatCount(_commentsCount),
              onTap: _toggleComments,
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              icon: Icons.bookmark_border,
              label: 'Wishlist',
              onTap: _handleWishlist,
            ),
          ],
        ),
      ),
          ],
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
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: 24, 
            color: isActive ? Colors.red : Colors.white,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCommentsView() {
    return Column(
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
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
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
            bottom: 12 + MediaQuery.of(context).padding.bottom,
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
          child: Row(
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
        ),
      ],
    );
  }

  Widget _buildCommentItem(CommentData comment) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnComment = currentUser?.uid == comment.userId;

    return Padding(
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
                          _loadComments();
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
                    Text(
                      'Reply',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isOwnComment) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () async {
                          try {
                            await commentsService.deleteComment(comment.id);
                            _loadComments();
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
                if (comment.repliesCount > 0) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      // TODO: Load and show replies
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          comment.getRepliesText(),
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
                if (comment.latestReply != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 2,
                        height: 24,
                        color: Colors.grey.shade800,
                        margin: const EdgeInsets.only(right: 8),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  comment.latestReply!.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  comment.latestReply!.getRelativeTime(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              comment.latestReply!.text,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
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

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1 ? '1d' : '${days}d';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w';
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