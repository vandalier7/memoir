import 'package:presentation/objects/globals.dart';
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
  
  String _getMoodLabel(Mood mood) {
    switch (mood) {
      case Mood.happy: return 'Happy';
      case Mood.sad: return 'Sad';
      case Mood.angry: return 'Angry';
      case Mood.disgusted: return 'Disgusted';
      case Mood.afraid: return 'Afraid';
      case Mood.calm: return 'Calm';
      case Mood.worried: return 'Worried';
    }
  }
  
  int _currentIndex = 0;
  bool _showComments = false;
  List<CommentData> _comments = [];
  bool _isLoadingComments = false;
  bool _isLiked = false;
  bool _isLoadingLike = false;
  
  final TextEditingController _commentController = TextEditingController();

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
    
    // Find index of selected memory
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
    _checkIfLiked();
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

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    
    try {
      final currentMemory = widget.memories[_currentIndex];
      final memoryId = currentMemory.memoryId;
      
      print('🔍 Loading comments for memoryId: $memoryId');
      print('🔍 Memory image URL: ${currentMemory.imageUrl}');
      print('🔍 Memory address: ${currentMemory.addressString}');
      
      if (memoryId == null) {
        print('Memory ID is null');
        setState(() {
          _comments = [];
          _isLoadingComments = false;
        });
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('comments')
          .where('memoryId', isEqualTo: memoryId)
          .orderBy('timestamp', descending: false)
          .get();
      
      print('📊 Found ${snapshot.docs.length} comments');

      if (snapshot.docs.isEmpty) {
        print('⚠️ No comments found for memoryId: $memoryId');
        // Check if there are ANY comments in the collection
        final allComments = await firestore.collection('comments').limit(5).get();
        print('📋 Total comments in collection: ${allComments.docs.length}');
        if (allComments.docs.isNotEmpty) {
          print('📋 Sample memoryIds in comments collection:');
          for (var doc in allComments.docs) {
            print('   - ${doc.data()['memoryId']}');
          }
        }
      }

      List<CommentData> loadedComments = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('💬 Comment data: $data');

        // Get user name
        String userName = 'Anonymous';
        try {
          final userDoc = await firestore
              .collection('users')
              .doc(data['userId'])
              .get();
          if (userDoc.exists) {
            userName = userDoc.data()?['displayName'] ?? 'Anonymous';
          }
        } catch (e) {
          print('Error loading user: $e');
        }
        
        loadedComments.add(CommentData(
          id: doc.id,
          userName: userName,
          userId: data['userId'] ?? '',
          text: data['text'] ?? '',
          timestamp: _formatTimestamp(data['timestamp']),
        ));
      }
      
      print('✅ Loaded ${loadedComments.length} comments');

      setState(() {
        _comments = loadedComments;
        _isLoadingComments = false;
      });
    } catch (e) {
      print('Error loading comments: $e');
      setState(() => _isLoadingComments = false);
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else {
        return 'Just now';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 7) {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  void _toggleComments() {
    print('🔄 Toggle comments - current state: $_showComments');
    if (!_showComments) {
      _loadComments();
    }
    setState(() {
      _showComments = !_showComments;
    });
  }

  Future<void> _handleLike() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like')),
      );
      return;
    }

    if (_isLoadingLike) return; // Prevent double-tap
    setState(() => _isLoadingLike = true);

    try{
      final currentMemory = widget.memories[_currentIndex];
      final memoryId = currentMemory.memoryId;
      
      if (memoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot like this memory')),
        );
        setState(() => _isLoadingLike = false);
        return;
      }

      final firestore = FirebaseFirestore.instance;

      // Check if user already liked - THIS WAS MISSING
      final likeRef = firestore
        .collection('likes')
        .doc('${memoryId}_${currentUser.uid}');

      if (_isLiked) {
        // Unlike
        await likeRef.delete();
        await firestore.collection('memories').doc(memoryId).update({
          'likesCount': FieldValue.increment(-1),
        });
      
        setState(() => _isLiked = false);
      
      } else {
        // Like
        await likeRef.set({
          'memoryId': memoryId,
          'userId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
      
        await firestore.collection('memories').doc(memoryId).update({
          'likesCount': FieldValue.increment(1),
        });
      
        setState(() => _isLiked = true);
    
      }
    } catch (e) {
      print('Error handling like: $e');
    } finally {
      setState(() => _isLoadingLike = false);
    }
  }

  Future<void> _checkIfLiked() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isLiked = false);
      return;
    }

    final currentMemory = widget.memories[_currentIndex];
    final memoryId = currentMemory.memoryId;
  
    if (memoryId == null) {
      setState(() => _isLiked = false);
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final likeDoc = await firestore
        .collection('likes')
        .doc('${memoryId}_${currentUser.uid}')
        .get();
    
      setState(() => _isLiked = likeDoc.exists);
    } catch (e) {
      print('Error checking like status: $e');
      setState(() => _isLiked = false);
    }
  }

  Future<void> _deleteComment(CommentData comment) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final firestore = FirebaseFirestore.instance;
    
      // Get the comment document to check ownership
      final commentDoc = await firestore
        .collection('comments')
        .doc(comment.id)
        .get();
    
      if (!commentDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment not found')),
        );
        return;
      }
    
      final commentUserId = commentDoc.data()?['userId'];
    
      // Only allow deletion if user owns the comment
      if (commentUserId != currentUser.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only delete your own comments')),
        );
        return;
      }
    
      // Delete the comment
      await firestore.collection('comments').doc(comment.id).delete();
    
      // Decrement comment count
      final currentMemory = widget.memories[_currentIndex];
      final memoryId = currentMemory.memoryId;
      if (memoryId != null) {
        await firestore.collection('memories').doc(memoryId).update({
          'commentsCount': FieldValue.increment(-1),
        });
     }
    
      // Reload comments
      _loadComments();
    
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment deleted')),
      );
    } catch (e) {
      print('Error deleting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _handleWishlist() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add to wishlist')),
      );
      return;
    }

    try {
      final currentMemory = widget.memories[_currentIndex];
      final memoryId = currentMemory.memoryId;
      
      if (memoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot add this to wishlist')),
        );
        return;
      }

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

  Future<void> _confirmDeleteComment(CommentData comment) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  
    if (shouldDelete == true) {
      _deleteComment(comment);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to comment')),
      );
      return;
    }

    try {
      final currentMemory = widget.memories[_currentIndex];
      final memoryId = currentMemory.memoryId;

      if (memoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot comment on this memory')),
        );
      return;
      }

      final firestore = FirebaseFirestore.instance;
      
      await firestore.collection('comments').add({
        'memoryId': memoryId,
        'userId': currentUser.uid,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Also increment comment count
      await firestore.collection('memories').doc(memoryId).update({
        'commentsCount': FieldValue.increment(1),
      });

      _commentController.clear();
      _loadComments(); // Reload comments
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added!')),
      );
    } catch (e) {
      print('Error sending comment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Positioned(
      top: screenHeight * 0.3,
      left: 0,   // No padding
      right: 0,  // No padding
      bottom: 0, // No padding
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
          child: _showComments 
              ? _buildCommentsView()
              : _buildMemoryView(),
        ),
      ),
    );
  }

  Widget _buildMemoryView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image section with horizontal scroll
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  _checkIfLiked();
                },
                itemCount: widget.memories.length,
                itemBuilder: (context, index) {
                  final memory = widget.memories[index];
                  return ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(5),
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
                  bottom: 12,
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
              
              // Mood indicator
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: getMoodColor(widget.memories[_currentIndex].mood).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    _getMoodLabel(widget.memories[_currentIndex].mood),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                // Address
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      widget.memories[_currentIndex].addressString,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Location icon
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
                        widget.memories[_currentIndex].addressString,
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
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                      label: 'Like',
                      onTap: _handleLike,
                      isActive: _isLiked,
                    ),
                    _buildActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: 'Comment',
                      onTap: _toggleComments,
                    ),
                    _buildActionButton(
                      icon: Icons.bookmark_border,
                      label: 'Wishlist',
                      onTap: _handleWishlist,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsView() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _toggleComments,
              ),
              const SizedBox(width: 8),
              Text(
                'Comments (${_comments.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _animateOut,
                ),
            ],
          ),
        ),
        
        // Comments list
        Expanded(
          child: _isLoadingComments
              ? const Center(child: CircularProgressIndicator())
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
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to comment!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFFF75270),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _sendComment,
                ),
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
              color: isActive ? Colors.red : Colors.grey.shade700,),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(CommentData comment) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnComment = currentUser?.uid == comment.userId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade300,
            child: Text(
              comment.userName[0].toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
                    Expanded(
                      child: Text(
                        comment.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // Only show delete if it's the user's own comment
                    if (isOwnComment)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade600),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _confirmDeleteComment(comment),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.timestamp,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class CommentData {
  final String id;
  final String userName;
  final String userId;
  final String text;
  final String timestamp;

  CommentData({
    required this.id,
    required this.userName,
    required this.userId,
    required this.text,
    required this.timestamp,
  });
}