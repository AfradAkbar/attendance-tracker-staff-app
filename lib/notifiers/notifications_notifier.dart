import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String targetAudience;
  final String? batchId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.targetAudience,
    this.batchId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      targetAudience: json['target_audience']?.toString() ?? 'all',
      batchId: json['batch_id']?.toString(),
      isRead: json['isRead'] == true,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      targetAudience: targetAudience,
      batchId: batchId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

class NotificationsNotifier extends ValueNotifier<List<NotificationModel>> {
  NotificationsNotifier() : super([]);

  int get unreadCount => value.where((n) => !n.isRead).length;

  void setNotifications(List<NotificationModel> notifications) {
    value = notifications;
    notifyListeners();
  }

  void markAsRead(String notificationId) {
    final index = value.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      value[index] = value[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void clear() {
    value = [];
    notifyListeners();
  }
}

// Global instance
final notificationsNotifier = NotificationsNotifier();
