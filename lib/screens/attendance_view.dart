import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staff_app/constants.dart';
import 'package:staff_app/models/student_model.dart';
import 'package:staff_app/models/subject_model.dart';

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  static const Color primaryColor = Color(0xFF5B8A72);
  static const Color surfaceColor = Color(0xFFF8F6F4);

  DateTime selectedDate = DateTime.now();
  int selectedHour = 1;
  SubjectModel? selectedSubject;

  List<SubjectModel> subjects = [];
  List<StudentModel> students = [];
  Map<String, String> attendanceMap = {}; // studentId: status

  bool isLoadingSubjects = true;
  bool isLoadingStudents = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => isLoadingSubjects = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    try {
      final res = await http.get(
        Uri.parse(kStaffMySubjects),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['data'] != null) {
          setState(() {
            subjects = (data['data'] as List)
                .map((json) => SubjectModel.fromJson(json))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading subjects: $e');
    } finally {
      setState(() => isLoadingSubjects = false);
    }
  }

  Future<void> _loadStudents() async {
    setState(() {
      isLoadingStudents = true;
      attendanceMap.clear();
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    try {
      final res = await http.get(
        Uri.parse(kStaffMyStudents),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['data'] != null) {
          final studentsList = (data['data'] as List)
              .map((json) => StudentModel.fromJson(json))
              .toList();

          setState(() {
            students = studentsList;
            // Initialize all as present by default
            for (var student in students) {
              attendanceMap[student.id] = 'present';
            }
          });
        }
      }
    } catch (e) {
      print('Error loading students: $e');
    } finally {
      setState(() => isLoadingStudents = false);
    }
  }

  Future<void> _saveAttendance() async {
    if (selectedSubject == null || students.isEmpty) return;

    setState(() => isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    // Prepare bulk attendance data
    final attendanceRecords = students.map((student) {
      return {
        'student_id': student.id,
        'subject_id': selectedSubject!.id,
        'date': DateFormat.E('yyyy-MM-dd').format(selectedDate),
        'hour': selectedHour,
        'attendance_status': attendanceMap[student.id] ?? 'absent',
        'semester_number': selectedSubject!.semesters.first,
      };
    }).toList();

    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/attendance/mark-bulk'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'attendance_records': attendanceRecords}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance marked successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Clear selection
          setState(() {
            students.clear();
            attendanceMap.clear();
          });
        }
      } else {
        throw Exception('Failed to mark attendance');
      }
    } catch (e) {
      print('Error saving attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark attendance'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isSaving = false);
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
                    "Mark Attendance",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(selectedDate),
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Selection Controls
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Date Selector
                  _buildSelectorCard(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: DateFormat('MMM d, yyyy').format(selectedDate),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Hour Selector
                  _buildSelectorCard(
                    icon: Icons.access_time_outlined,
                    label: 'Hour/Period',
                    value: 'Hour $selectedHour',
                    onTap: () => _showHourPicker(),
                  ),
                  const SizedBox(height: 12),

                  // Subject Selector
                  _buildSelectorCard(
                    icon: Icons.book_outlined,
                    label: 'Subject',
                    value: selectedSubject?.subjectName ?? 'Select Subject',
                    onTap: () => _showSubjectPicker(),
                  ),
                  const SizedBox(height: 16),

                  // Load Students Button
                  if (selectedSubject != null)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: isLoadingStudents ? null : _loadStudents,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          isLoadingStudents ? 'Loading...' : 'Load Students',
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Students List
            Expanded(
              child: students.isEmpty
                  ? Center(
                      child: Text(
                        'Select subject and load students',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    )
                  : Column(
                      children: [
                        // Quick Actions
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      for (var student in students) {
                                        attendanceMap[student.id] = 'present';
                                      }
                                    });
                                  },
                                  child: const Text('Mark All Present'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      for (var student in students) {
                                        attendanceMap[student.id] = 'absent';
                                      }
                                    });
                                  },
                                  child: const Text('Mark All Absent'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Student List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: students.length,
                            itemBuilder: (context, index) {
                              return _buildStudentAttendanceCard(
                                students[index],
                              );
                            },
                          ),
                        ),

                        // Save Button
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isSaving ? null : _saveAttendance,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                isSaving ? 'Saving...' : 'Save Attendance',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentAttendanceCard(StudentModel student) {
    final status = attendanceMap[student.id] ?? 'present';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      student.rollNumber,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusChip(
                'present',
                'Present',
                status == 'present',
                student.id,
              ),
              const SizedBox(width: 8),
              _buildStatusChip(
                'absent',
                'Absent',
                status == 'absent',
                student.id,
              ),
              const SizedBox(width: 8),
              _buildStatusChip('late', 'Late', status == 'late', student.id),
              const SizedBox(width: 8),
              _buildStatusChip('leave', 'Leave', status == 'leave', student.id),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    String value,
    String label,
    bool isSelected,
    String studentId,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            attendanceMap[studentId] = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  void _showHourPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Select Hour/Period',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    final hour = index + 1;
                    return InkWell(
                      onTap: () {
                        setState(() => selectedHour = hour);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedHour == hour
                              ? primaryColor
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Hour $hour',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: selectedHour == hour
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSubjectPicker() {
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No subjects available')));
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Subject',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ...subjects.map((subject) {
                return ListTile(
                  title: Text(subject.subjectName),
                  subtitle: Text(
                    '${subject.courseName} - Sem ${subject.semesters.join(', ')}',
                  ),
                  selected: selectedSubject?.id == subject.id,
                  onTap: () {
                    setState(() => selectedSubject = subject);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
