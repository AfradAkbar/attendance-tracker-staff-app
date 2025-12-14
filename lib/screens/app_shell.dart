import 'dart:convert';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staff_app/screens/login_screen.dart';
import 'package:http/http.dart' as http;

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _bottomNavIndex = 0;

  Map<String, dynamic>? userData;
  bool isLoading = true;

  // Icons for navigation items
  final iconList = <IconData>[
    Icons.home,
    Icons.schedule, // Timetable
    Icons.calendar_month, // Attendance
    Icons.person, // Profile
  ];

  // Titles for each tab
  final titles = ['Home', 'Timetable', 'Attendance', 'Profile'];

  // Different page widgets
  final List<Widget> pages = [
    // Placeholder pages — replace with real views when available
    const Center(child: Text('Home', style: TextStyle(fontSize: 20))),
    const Center(child: Text('Timetable', style: TextStyle(fontSize: 20))),
    const Center(child: Text('Attendance', style: TextStyle(fontSize: 20))),
    // Profile page with logout
    Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Signed in as',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          // Text(
          //   userDat?['email'] ?? 'Unknown',
          //   style: const TextStyle(fontSize: 16),
          // ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('jwt_token');
                await prefs.remove('student_id');

                // if (!mounted) return;

                // Navigator.of(context).pushAndRemoveUntil(
                //   MaterialPageRoute(builder: (_) => const LoginScreen()),
                //   (route) => false,
                // );
              },
            ),
          ),
        ],
      ),
    ),
  ];

  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // final data = await _getProfileData();
    setState(() {
      // userData = data?['user'];
      // isLoading = false;
    });
  }

  // Future<Map<String, dynamic>?> _getProfileData() async {
  //   final url = Uri.parse(kMyDetails);

  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('jwt_token') ?? '';

  //   try {
  //     final res = await http.get(
  //       url,
  //       headers: {
  //         'content-type': 'application/json',
  //         if (token.isNotEmpty) 'authorization': 'Bearer $token',
  //       },
  //     );

  //     print('[_getProfileData] ${res.statusCode} => ${res.body}');

  //     if (res.statusCode == 200) {
  //       final data = jsonDecode(res.body) as Map<String, dynamic>;
  //       final user = data['user'] as Map<String, dynamic>;
  //       userNotifier.value = UserModel.fromJson(user);
  //       return data;
  //     }
  //   } catch (e) {
  //     print("ERROR: $e");
  //   }
  //   return null;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),

      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: iconList,
        activeIndex: _bottomNavIndex,
        gapLocation: GapLocation.none, // No gap since no button
        notchSmoothness: NotchSmoothness.defaultEdge,
        // leftCornerRadius: 50,
        // rightCornerRadius: 50,
        activeColor: Colors.blueAccent,
        inactiveColor: Colors.grey,
        onTap: (index) => setState(() => _bottomNavIndex = index),
      ),

      body: SafeArea(
        child: Column(children: [Expanded(child: pages[_bottomNavIndex])]),
      ),
    );
  }
}
