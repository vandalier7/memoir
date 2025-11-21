import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:presentation/objects/memory_card.dart';

class CommentsService {
  // Singleton instance
  static final CommentsService _instance = CommentsService._internal();
  factory CommentsService() => _instance;
  CommentsService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Load top-level comments with their latest reply
  Future<List<CommentData>> loadComments(int memoryId, String memoryOwnerId) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    try {
      // Get top-level comments (where headcommentid is null)
      final response = await _supabase
          .from('comment')
          .select('*')
          .eq('memoryID', memoryId)
          .isFilter('headcommentid', null)
          .order('created_at', ascending: false); // Most recent first

      if (response == null || response.isEmpty) return [];

      final comments = <CommentData>[];
      
      for (final data in response as List) {
        // Count replies for this comment
        final repliesCount = await _countReplies(data['id']);
        
        // Check if user liked this comment
        final isLiked = await _checkIfLiked(data['id']);
        
        // Get latest reply if there are replies
        CommentData? latestReply;
        if (repliesCount > 0) {
          latestReply = await _getLatestReply(data['id'], memoryOwnerId);
        }

        // Get user display name
        final userName = await _getUserName(data['userID']);

        comments.add(CommentData(
          id: data['id'] as int,
          userName: userName,
          userId: data['userID'] as String,
          text: data['comment'] as String,
          timestamp: DateTime.parse(data['created_at'] as String),
          repliedCommentID: data['repliedCommentID'] as int?,
          likesCount: data['likes_count'] as int? ?? 0,
          repliesCount: repliesCount,
          isLikedByMe: isLiked,
          isAuthor: data['userID'] == memoryOwnerId,
          latestReply: latestReply,
        ));
      }

      return comments;
    } catch (e) {
      print('❌ Error loading comments: $e');
      rethrow;
    }
  }

  // Count replies for a comment
  Future<int> _countReplies(int commentId) async {
    try {
      final response = await _supabase
        .from('comment')
        .select()
        .eq('repliedCommentID', commentId)
        .count();

      return response.count;
    } catch (e) {
      print('Error counting replies: $e');
      return 0;
    }
  }

  // Get user display name
  Future<String> _getUserName(String userId) async {
    try {
      final response = await _supabase
          .from('user')
          .select('username, email')
          .eq('uid', userId)
          .maybeSingle();

      if (response != null) {
        // Prioritize username, fallback to email
        return response['username'] as String? ?? 
               response['email'] as String? ?? 
               'Anonymous';
      }
      return 'Anonymous';
    } catch (e) {
      print('Error loading user: $e');
      return 'Anonymous';
    }
  }

  // Get latest reply for a comment
  Future<CommentData?> _getLatestReply(int commentId, String memoryOwnerId) async {
    try {
      final response = await _supabase
          .from('comment')
          .select('*')
          .eq('repliedCommentID', commentId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final isLiked = await _checkIfLiked(response['id']);
      final userName = await _getUserName(response['userID']);

      return CommentData(
        id: response['id'] as int,
        userName: userName,
        userId: response['userID'] as String,
        text: response['comment'] as String,
        timestamp: DateTime.parse(response['created_at'] as String),
        repliedCommentID: response['repliedCommentID'] as int?,
        likesCount: response['likes_count'] as int? ?? 0,
        repliesCount: 0, // Don't need to count for reply preview
        isLikedByMe: isLiked,
        isAuthor: response['userID'] == memoryOwnerId,
      );
    } catch (e) {
      print('Error loading latest reply: $e');
      return null;
    }
  }

  // Load all replies for a comment
  Future<List<CommentData>> loadReplies(int commentId, String memoryOwnerId) async {
    try {
      final response = await _supabase
          .from('comment')
          .select('*')
          .eq('repliedCommentID', commentId)
          .order('created_at', ascending: true); // Oldest first for replies

      if (response == null || response.isEmpty) return [];

      final replies = <CommentData>[];
      
      for (final data in response as List) {
        final isLiked = await _checkIfLiked(data['id']);
        final userName = await _getUserName(data['userID']);
        
        replies.add(CommentData(
          id: data['id'] as int,
          userName: userName,
          userId: data['userID'] as String,
          text: data['comment'] as String,
          timestamp: DateTime.parse(data['created_at'] as String),
          repliedCommentID: data['repliedCommentID'] as int?,
          likesCount: data['likes_count'] as int? ?? 0,
          repliesCount: 0,
          isLikedByMe: isLiked,
          isAuthor: data['userID'] == memoryOwnerId,
        ));
      }

      return replies;
    } catch (e) {
      print('❌ Error loading replies: $e');
      rethrow;
    }
  }

  // Check if current user liked a comment
  Future<bool> _checkIfLiked(int commentId) async {
    if (currentUserId == null) return false;

    try {
      final response = await _supabase
          .from('comment_likes')
          .select('id')
          .eq('commentid', commentId)
          .eq('userid', currentUserId!)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

  // Post a new comment or reply
  Future<void> postComment({
    required int memoryId,
    required String text,
    int? replyToCommentId,
    int? headcommentid, // For nested replies - always points to the top-level comment
  }) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    try {
      await _supabase.from('comment').insert({
        'memoryID': memoryId,
        'userID': currentUserId,
        'comment': text,
        'repliedCommentID': replyToCommentId,
        'headcommentid': headcommentid ?? replyToCommentId, // If replying, set to head
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'likes_count': 0,
      });
      
      print('✅ Comment posted successfully');
    } catch (e) {
      print('❌ Error posting comment: $e');
      rethrow;
    }
  }

  // Like/unlike a comment
  Future<void> toggleCommentLike(int commentId) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    try {
      final existingLike = await _supabase
          .from('comment_likes')
          .select('id')
          .eq('commentid', commentId)
          .eq('userid', currentUserId!)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _supabase
            .from('comment_likes')
            .delete()
            .eq('commentid', commentId)
            .eq('userid', currentUserId!);

        // Decrement like count
        await _supabase.rpc('decrement_comment_likes', params: {
          'comment_id': commentId,
        });
        
        print('👎 Comment unliked');
      } else {
        // Like
        await _supabase.from('comment_likes').insert({
          'commentid': commentId,
          'userid': currentUserId,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Increment like count
        await _supabase.rpc('increment_comment_likes', params: {
          'comment_id': commentId,
        });
        
        print('❤️ Comment liked');
      }
    } catch (e) {
      print('❌ Error toggling comment like: $e');
      rethrow;
    }
  }

  // Delete a comment (only if owner)
  Future<void> deleteComment(int commentId) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    try {
      // Verify ownership
      final comment = await _supabase
          .from('comment')
          .select('userID')
          .eq('id', commentId)
          .single();

      if (comment['userID'] != currentUserId) {
        throw Exception('You can only delete your own comments');
      }

      // Delete comment (cascades to likes and replies if set up in DB)
      await _supabase
          .from('comment')
          .delete()
          .eq('id', commentId);
      
      print('🗑️ Comment deleted');
    } catch (e) {
      print('❌ Error deleting comment: $e');
      rethrow;
    }
  }

  // Get memory stats (likes and comments count)
  Future<Map<String, int>> getMemoryStats(int memoryId) async {
    try {
      // Get likes count from like table
      final likesResponse = await _supabase
        .from('like')
        .select()
        .eq('memoryID', memoryId)
        .count();

      // Get top-level comments count (not replies)
      final commentsResponse = await _supabase
        .from('comment')
        .select()
        .eq('memoryID', memoryId)
        .isFilter('headcommentid', null)
        .count();
    
      return {
        'likes': likesResponse.count,
        'comments': commentsResponse.count,
      };
    } catch (e) {
      print('Error getting memory stats: $e');
      return {'likes': 0, 'comments': 0};
    }
  }

  // Check if current user liked the memory
  Future<bool> checkIfMemoryLiked(int memoryId) async {
    if (currentUserId == null) return false;

    try {
      final response = await _supabase
          .from('like')
          .select('id')
          .eq('memoryID', memoryId)
          .eq('userID', currentUserId!)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking memory like status: $e');
      return false;
    }
  }

  // Toggle memory like
  Future<void> toggleMemoryLike(int memoryId) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    try {
      final existingLike = await _supabase
          .from('like')
          .select('id')
          .eq('memoryID', memoryId)
          .eq('userID', currentUserId!)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _supabase
            .from('like')
            .delete()
            .eq('memoryID', memoryId)
            .eq('userID', currentUserId!);
        
        print('👎 Memory unliked');
      } else {
        // Like
        await _supabase.from('like').insert({
          'memoryID': memoryId,
          'userID': currentUserId,
          'created_at': DateTime.now().toIso8601String(),
        });
        
        print('❤️ Memory liked');
      }
    } catch (e) {
      print('❌ Error toggling memory like: $e');
      rethrow;
    }
  }
}

// Global instance
final commentsService = CommentsService();