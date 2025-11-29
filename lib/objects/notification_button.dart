import 'package:presentation/processes/notifications_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../app_theme.dart';

import 'package:presentation/my_scaffold.dart';
import 'package:presentation/objects/globals.dart';

// 🐛 DEBUG FLAGS
const bool _debugForceShowNotification = false; // Set to true to always show the floating notification
const String _debugNotificationText = "John Doe liked your memory."; // Custom debug text

class _NotificationButtonState extends State<NotificationButton> with SingleTickerProviderStateMixin {
  NotificationData? _previousLatest;
  NotificationData? _displayedNotification;
  Timer? _dismissTimer;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  String? _currentNotificationId; // Track which notification is currently displayed

  @override
  void initState() {
    super.initState();
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    // 🐛 Debug: Auto-show notification if flag is enabled
    if (_debugForceShowNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDebugNotification();
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  // 🐛 Debug: Create a fake notification for testing
  void _showDebugNotification() {
    final debugNotif = NotificationData(
      id: 'debug-notif',
      type: 'memory_like',
      actorId: 'debug-user',
      actorName: 'Debug User',
      actorAvatar: null,
      isRead: false,
      createdAt: DateTime.now(),
      memoryId: 123,
      commentText: 'This is a debug comment preview',
    );
    _showFloatingNotification(debugNotif);
  }

  void _showFloatingNotification(NotificationData notification) {
    // Only show if it's a different notification
    if (_currentNotificationId == notification.id) {
      return;
    }

    feedbackService.playSound("notif-short");

    setState(() {
      _displayedNotification = notification;
      _currentNotificationId = notification.id;
    });
    _animController.forward(from: 0);
    
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _displayedNotification = null;
          _currentNotificationId = null;
        });
        
        // 🐛 Debug: Re-show notification if flag is enabled
        if (_debugForceShowNotification) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _showDebugNotification();
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationData>>(
      stream: notificationService.getNotifications(),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final unreadCount = notifications.where((n) => !n.isRead).length;
        final latestNotif = notifications.isNotEmpty ? notifications.first : null;

        // Detect new notification (check if latest changed and it's unread)
        if (latestNotif != null && 
            latestNotif.id != _previousLatest?.id &&
            !latestNotif.isRead &&
            !_debugForceShowNotification) { // Don't trigger if debug mode is on
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showFloatingNotification(latestNotif);
          });
        }
        _previousLatest = latestNotif;

        return GestureDetector(
          onTap: () async {
            if (widget.hasActiveMemory) {
              await Future.delayed(Duration(milliseconds: 450));
            }

            final result = await Navigator.pushNamed(context, '/notifications');
            
            if (result != null && result is Map) {
              final memoryId = result['memoryId'] as int?;
              final commentId = result['commentId'] as int?;
              if (memoryId != null) {

                final scaffoldState = context.findAncestorStateOfType<MyState>();
                if (scaffoldState != null) {
                  scaffoldState.navigateToMemory(memoryId, commentId: commentId);
                }
              }
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: memoirTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.forum_outlined,
                      size: 18,
                      color: memoirTheme.onSurface,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Floating notification preview
              if (_displayedNotification != null) ...[
                const SizedBox(width: 8),
                SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    height: 50,
                    constraints: const BoxConstraints(maxWidth: 160),
                    decoration: BoxDecoration(
                      color: memoirTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _debugForceShowNotification && false
                            ? Colors.orange // 🐛 Orange border in debug mode
                            : memoirTheme.tertiary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 🐛 Use debug text if flag is enabled
                              if (_debugForceShowNotification && _debugNotificationText.isNotEmpty)
                                Text(
                                  _debugNotificationText,
                                  style: TextStyle(
                                    color: memoirTheme.tertiaryFixed,
                                    fontSize: 10,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              else
                                RichText(
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: memoirTheme.onSurface,
                                      fontSize: 10,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: _displayedNotification!.actorName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: ' ${_displayedNotification!.getMessage()}',
                                      ),
                                    ],
                                  ),
                                ),
                              if (_displayedNotification!.commentText != null && !_debugForceShowNotification) ...[
                                const SizedBox(height: 1),
                                Text(
                                  _displayedNotification!.commentText!,
                                  style: TextStyle(
                                    color: memoirTheme.onSurface.withValues(alpha: 0.6),
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class NotificationButton extends StatefulWidget {
  final bool hasActiveMemory;

  const NotificationButton({super.key, required this.hasActiveMemory});

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}