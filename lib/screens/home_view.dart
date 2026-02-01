import 'package:flutter/material.dart';
import 'package:staff_app/api_service.dart';
import 'package:staff_app/constants.dart';
import 'package:staff_app/notifiers/user_notifier.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  static const Color primaryColor = Color(0xFF5B8A72); // Sage green
  static const Color surfaceColor = Color(0xFFF8F6F4); // Warm off-white

  Map<String, dynamic>? classInCharge;
  List<Map<String, dynamic>> subjects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      // Fetch class in charge
      final classData = await ApiService.get(kStaffMyClass);
      if (classData != null && classData['data'] != null) {
        setState(() {
          classInCharge = classData['data'] as Map<String, dynamic>;
        });
      }
      print(classData);

      // Fetch subjects
      final subjectsData = await ApiService.get(kStaffMySubjects);
      if (subjectsData != null && subjectsData['data'] != null) {
        setState(() {
          subjects = List<Map<String, dynamic>>.from(subjectsData['data']);
        });
      }
    } catch (e) {
      print('Error loading home data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(28),
                            bottomRight: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Dashboard",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ValueListenableBuilder<UserModel?>(
                              valueListenable: userNotifier,
                              builder: (context, userData, child) {
                                return Text(
                                  "Welcome, ${userData?.name ?? 'Staff'}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Class In Charge Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle("Class In Charge"),
                            const SizedBox(height: 12),
                            classInCharge != null
                                ? _buildClassCard(classInCharge!)
                                : _buildNoDataCard(
                                    "No class assigned as in-charge",
                                  ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Subject Allocations Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle("Subject Allocations"),
                            const SizedBox(height: 12),
                            subjects.isEmpty
                                ? _buildNoDataCard("No subjects allocated")
                                : Column(
                                    children: subjects
                                        .map(
                                          (subject) =>
                                              _buildSubjectCard(subject),
                                        )
                                        .toList(),
                                  ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData) {
    final courseName = classData['course_id']?['name']?.toString() ?? '';
    final startYear = classData['start_year']?.toString() ?? '';
    final endYear = classData['end_year']?.toString() ?? '';
    final strength = classData['strength']?.toString() ?? '0';
    final currentSemester = classData['current_semester']?.toString() ?? '1';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.class_outlined, size: 24, color: primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _infoChip(Icons.calendar_today_outlined, "$startYear - $endYear"),
              const SizedBox(width: 12),
              _infoChip(Icons.people_outline, "$strength students"),
              const SizedBox(width: 12),
              _infoChip(Icons.book_outlined, "Sem $currentSemester"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final subjectName = subject['subject_name']?.toString() ?? '';
    // Handle course_ids as a list of objects
    String courseNames = '';
    if (subject['course_ids'] is List) {
      final courses = subject['course_ids'] as List;
      courseNames = courses
          .map((c) => c is Map && c['name'] != null ? c['name'].toString() : '')
          .where((name) => name.isNotEmpty)
          .join(', ');
    }
    // Handle semesters as a list of numbers
    String semesters = '';
    if (subject['semesters'] is List) {
      semesters = (subject['semesters'] as List)
          .map((s) => s.toString())
          .join(', ');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_outlined, size: 24, color: primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjectName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  courseNames,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              semesters.isNotEmpty ? "Sem $semesters" : '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primaryColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
