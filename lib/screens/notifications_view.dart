import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_app/api_service.dart';
import 'package:staff_app/constants.dart';
import 'package:staff_app/notifiers/notifications_notifier.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  static const Color primaryColor = Color(0xFF5B8A72);
  static const Color surfaceColor = Color(0xFFF8F6F4);

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Refresh on view if notifications are empty
    if (notificationsNotifier.value.isEmpty) {
      _refreshNotifications();
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() => isLoading = true);

    try {
      final data = await ApiService.get(kStaffNotifications);
      if (data != null && data['data'] != null) {
        final notifications = (data['data'] as List)
            .map(
              (json) =>
                  NotificationModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        notificationsNotifier.setNotifications(notifications);
      }
    } catch (e) {
      print('Error refreshing notifications: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await ApiService.put('$kStaffNotifications/$notificationId/read');
      notificationsNotifier.markAsRead(notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'attendance':
        return Icons.fact_check_outlined;
      case 'exam':
        return Icons.quiz_outlined;
      case 'event':
        return Icons.event_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'attendance':
        return Colors.blue;
      case 'exam':
        return Colors.orange;
      case 'event':
        return Colors.purple;
      default:
        return primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: ValueListenableBuilder<List<NotificationModel>>(
                valueListenable: notificationsNotifier,
                builder: (context, notifications, child) {
                  final unreadCount = notifications
                      .where((n) => !n.isRead)
                      .length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Notifications",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        unreadCount > 0
                            ? "$unreadCount unread"
                            : "All caught up!",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Notifications List
            Expanded(
              child: ValueListenableBuilder<List<NotificationModel>>(
                valueListenable: notificationsNotifier,
                builder: (context, notifications, child) {
                  if (isLoading && notifications.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No notifications yet",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshNotifications,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(notifications[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          _markAsRead(notification.id);
        }
        _showNotificationDetails(notification);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade100
                : primaryColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getTypeColor(notification.type).withOpacity(0.1),
              ),
              child: Center(
                child: Icon(
                  _getTypeIcon(notification.type),
                  size: 22,
                  color: _getTypeColor(notification.type),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          height: 8,
                          width: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(notification.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(notification.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      notification.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getTypeColor(notification.type),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDate(notification.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
