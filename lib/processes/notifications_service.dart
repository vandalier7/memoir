import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Create a notification
  /// [recipientId] - User who receives the notification
  /// [type] - Type of notification: 'memory_like', 'memory_comment', 'comment_like', 'comment_reply', 'follow'
  /// [actorId] - User who triggered the notification
  /// [actorName] - Username of the actor (cached for quick display)
  /// [actorAvatar] - Profile picture URL of the actor (optional)
  /// [memoryId] - Supabase memory ID (optional, for memory-related notifications)
  /// [memoryImageUrl] - Thumbnail of the memory (optional)
  /// [commentId] - Supabase comment ID (optional, for comment-related notifications)
  /// [commentText] - Preview of the comment text (optional)
  Future<void> createNotification({
    required String recipientId,
    required String type,
    required String actorId,
    required String actorName,
    String? actorAvatar,
    int? memoryId,
    String? memoryImageUrl,
    int? commentId,
    String? commentText,
  }) async {
    // Don't create notification if actor is the recipient (self-action)
    if (actorId == recipientId) return;

    try {
      final notificationData = {
        'type': type,
        'actorId': actorId,
        'actorName': actorName,
        'actorAvatar': actorAvatar,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add type-specific fields
      if (memoryId != null) {
        notificationData['memoryId'] = memoryId;
      }
      if (memoryImageUrl != null) {
        notificationData['memoryImageUrl'] = memoryImageUrl;
      }
      if (commentId != null) {
        notificationData['commentId'] = commentId;
      }
      if (commentText != null) {
        // Limit comment preview to 50 characters
        notificationData['commentText'] = commentText.length > 50 
            ? '${commentText.substring(0, 50)}...' 
            : commentText;
      }

      await _firestore
          .collection('users')
          .doc(recipientId)
          .collection('notifications')
          .add(notificationData);

      print('✅ Notification created: $type for user $recipientId');
    } catch (e) {
      print('❌ Error creating notification: $e');
      rethrow;
    }
  }

  /// Get notifications for the current user
  /// Returns a stream of notifications ordered by creation time (newest first)
  Stream<List<NotificationData>> getNotifications() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to 50 most recent notifications
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationData(
          id: doc.id,
          type: data['type'] as String,
          actorId: data['actorId'] as String,
          actorName: data['actorName'] as String,
          actorAvatar: data['actorAvatar'] as String?,
          isRead: data['isRead'] as bool? ?? false,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          memoryId: data['memoryId'] as int?,
          memoryImageUrl: data['memoryImageUrl'] as String?,
          commentId: data['commentId'] as int?,
          commentText: data['commentText'] as String?,
        );
      }).toList();
    });
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      print('✅ Notification marked as read');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Get unread notification count
  Stream<int> getUnreadCount() {
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      print('🗑️ Notification deleted');
    } catch (e) {
      print('❌ Error deleting notification: $e');
      rethrow;
    }
  }

  /// Delete all notifications for current user
  Future<void> deleteAllNotifications() async {
    if (currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('🗑️ All notifications deleted');
    } catch (e) {
      print('❌ Error deleting all notifications: $e');
      rethrow;
    }
  }
}

/// Notification data model
class NotificationData {
  final String id;
  final String type;
  final String actorId;
  final String actorName;
  final String? actorAvatar;
  final bool isRead;
  final DateTime createdAt;
  final int? memoryId;
  final String? memoryImageUrl;
  final int? commentId;
  final String? commentText;

  NotificationData({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorName,
    this.actorAvatar,
    required this.isRead,
    required this.createdAt,
    this.memoryId,
    this.memoryImageUrl,
    this.commentId,
    this.commentText,
  });

  /// Get a human-readable notification message
  String getMessage() {
    switch (type) {
      case 'memory_like':
        return 'liked your memory';
      case 'memory_comment':
        return 'commented on your memory';
      case 'comment_like':
        return 'liked your comment';
      case 'comment_reply':
        return 'replied to your comment';
      case 'follow':
        return 'started following you';
      default:
        return 'interacted with your content';
    }
  }

  /// Get relative time string
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 28) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      final month = createdAt.month.toString().padLeft(2, '0');
      final day = createdAt.day.toString().padLeft(2, '0');
      return '$month-$day-${createdAt.year}';
    }
  }
}

// Global instance
final notificationService = NotificationService();