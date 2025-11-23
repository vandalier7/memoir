import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../processes/notifications_service.dart';
import '../app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  final Function(int supabaseMemoryId, {int? commentId})? onMemoryTap;

  const NotificationsScreen({
    super.key,
    this.onMemoryTap,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Content with padding for header
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 87), // Height of header
                child: StreamBuilder<List<NotificationData>>(
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
              ),
            ),

            // Fixed header on top with shadow
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(context),
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
          // LEFT BUTTON - Back
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
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
              ),
            ),
          ),

          // CENTER TITLE
          const Text(
            "Notifications",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),

          // RIGHT BUTTON - Mark all read
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                notificationService.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Color.fromARGB(255, 250, 132, 154),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
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
          color: notification.isRead
            ? Colors.white 
            : memoirTheme.tertiary.withOpacity(0.1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, "/account", arguments: notification.actorId);
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: memoirTheme.primary.withOpacity(0.2),
                  backgroundImage: notification.actorAvatar != null
                      ? CachedNetworkImageProvider(notification.actorAvatar!) as ImageProvider
                      : const AssetImage('assets/temp.png'),
                ),
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
                        color: notification.isRead
                          ? memoirTheme.primary 
                          : memoirTheme.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Memory thumbnail (if available)
              if (notification.memoryImageUrl != null || notification.memoryLocation != null) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Memory image
                    if (notification.memoryImageUrl != null)
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
        
                    // Location text
                    if (notification.memoryLocation != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 10,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              notification.memoryLocation!
                                .split(',')
                                .take(2)
                                .join(',')
                                .trim(),
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],

              // Unread indicator dot
              if (!notification.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: memoirTheme.tertiary,
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
    if (!notification.isRead) {
      notificationService.markAsRead(notification.id);
    }

    if (notification.type == 'follow') {
      Navigator.pushNamed(context, '/account', arguments: notification.actorId);
      return;
    }
  
    // Return data to the caller
    switch (notification.type) {
      case 'memory_like':
        if (notification.memoryId != null) {
          Navigator.pop(context, {
            'memoryId': notification.memoryId!,
          });
        }
        break;

      case 'memory_comment':
      case 'comment_like':
      case 'comment_reply':
        if (notification.memoryId != null && notification.commentId != null) {
          Navigator.pop(context, {
            'memoryId': notification.memoryId!,
            'commentId': notification.commentId,
            });
          }
        break;
    }
  }
}