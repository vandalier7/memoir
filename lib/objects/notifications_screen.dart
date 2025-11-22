import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../processes/notifications_service.dart';
import '../app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all as read when screen opens (optional - remove if you don't want this)
    Future.delayed(const Duration(seconds: 1), () {
      notificationService.markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: memoirTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: memoirTheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Mark all as read button
          TextButton(
            onPressed: () {
              notificationService.markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: memoirTheme.primary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationData>>(
        stream: notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: memoirTheme.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When you get notifications, they\'ll show up here',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 72,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationData notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        notificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          // Mark as read
          if (!notification.isRead) {
            notificationService.markAsRead(notification.id);
          }

          // Navigate based on notification type
          _handleNotificationTap(notification);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: notification.isRead ? Colors.white : Colors.blue.shade50,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: memoirTheme.primary.withOpacity(0.2),
                backgroundImage: notification.actorAvatar != null
                    ? CachedNetworkImageProvider(notification.actorAvatar!)
                    : null,
                child: notification.actorAvatar == null
                    ? Icon(Icons.person, color: memoirTheme.primary)
                    : null,
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: notification.actorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: ' ${notification.getMessage()}',
                          ),
                        ],
                      ),
                    ),
                    
                    // Show comment preview if available
                    if (notification.commentText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '"${notification.commentText}"',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 4),
                    Text(
                      notification.getRelativeTime(),
                      style: TextStyle(
                        fontSize: 12,
                        color: memoirTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Memory thumbnail (if available)
              if (notification.memoryImageUrl != null) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: notification.memoryImageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade200,
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade300,
                      child: Icon(Icons.image, color: Colors.grey.shade500),
                    ),
                  ),
                ),
              ],

              // Unread indicator dot
              if (!notification.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: memoirTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationData notification) {
    switch (notification.type) {
      case 'memory_like':
      case 'memory_comment':
        // TODO: Navigate to memory detail screen
        // Navigator.pushNamed(context, '/memory', arguments: notification.memoryId);
        print('Navigate to memory: ${notification.memoryId}');
        break;
      
      case 'comment_like':
      case 'comment_reply':
        // TODO: Navigate to memory detail with comment focused
        // Navigator.pushNamed(context, '/memory', arguments: {
        //   'memoryId': notification.memoryId,
        //   'commentId': notification.commentId,
        // });
        print('Navigate to comment: ${notification.commentId}');
        break;
      
      case 'follow':
        // Navigate to user profile
        Navigator.pushNamed(
          context,
          '/account',
          arguments: notification.actorId,
        );
        break;
    }
  }
}