import 'dart:convert';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staff_app/api_service.dart';
import 'package:staff_app/constants.dart';
import 'package:staff_app/notifiers/user_notifier.dart';
import 'package:staff_app/notifiers/notifications_notifier.dart';
import 'package:staff_app/screens/profile_view.dart';
import 'package:staff_app/screens/home_view.dart';
import 'package:staff_app/screens/students_view.dart';
import 'package:staff_app/screens/attendance_view.dart';
import 'package:staff_app/screens/notifications_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _bottomNavIndex = 0;

  Map<String, dynamic>? userData;
  bool isLoading = true;

  // Titles for each tab
  final titles = ['Home', 'Attendance', 'Students', 'Notifications', 'Profile'];

  // Different page widgets
  final List<Widget> pages = [
    const HomeView(),
    const AttendanceView(),
    const StudentsView(),
    const NotificationsView(),
    const ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadNotifications();
  }

  Future<void> _loadProfile() async {
    print('[AppShell] Loading profile...');
    final prefs = await SharedPreferences.getInstance();
    final userDataJson = prefs.getString('user_data');

    print('[AppShell] user_data from prefs: $userDataJson');

    if (userDataJson != null) {
      try {
        final userData = jsonDecode(userDataJson) as Map<String, dynamic>;
        print('[AppShell] Parsed user data: $userData');
        userNotifier.value = UserModel.fromJson(userData);
        print('[AppShell] UserModel created: ${userNotifier.value?.name}');
      } catch (e) {
        print('[AppShell] Error loading user data: $e');
      }
    } else {
      print('[AppShell] No user_data found in SharedPreferences');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadNotifications() async {
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
      print('[AppShell] Error loading notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),

      bottomNavigationBar: Stack(
        children: [
          AnimatedBottomNavigationBar(
            icons: const [
              Icons.home,
              Icons.fact_check_outlined,
              Icons.people,
              Icons.notifications_outlined,
              Icons.person,
            ],
            activeIndex: _bottomNavIndex,
            gapLocation: GapLocation.none,
            notchSmoothness: NotchSmoothness.defaultEdge,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.grey,
            onTap: (index) => setState(() => _bottomNavIndex = index),
          ),
          // Notification badge overlay
          ValueListenableBuilder<List<NotificationModel>>(
            valueListenable: notificationsNotifier,
            builder: (context, notifications, child) {
              final unreadCount = notifications.where((n) => !n.isRead).length;
              if (unreadCount == 0) return const SizedBox.shrink();

              return Positioned(
                // Position over the notifications icon (4th icon, index 3)
                left: MediaQuery.of(context).size.width / 5 * 3.5 - 4,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: SafeArea(
        child: Column(children: [Expanded(child: pages[_bottomNavIndex])]),
      ),
    );
  }
}
