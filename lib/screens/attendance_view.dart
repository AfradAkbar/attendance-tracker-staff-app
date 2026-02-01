import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staff_app/api_service.dart';
import 'package:staff_app/constants.dart';

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  static const Color primaryColor = Color(0xFF5B8A72);
  static const Color surfaceColor = Color(0xFFF8F6F4);

  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> timetableSlots = [];
  Map<String, dynamic>? selectedSlot;
  List<Map<String, dynamic>> students = [];
  Map<String, String> attendanceMap = {}; // studentId: status

  bool isLoadingTimetable = true;
  bool isLoadingStudents = false;
  bool isSaving = false;
  String? currentDay;
  String? currentDate;

  @override
  void initState() {
    super.initState();
    _loadTimetableForDate();
  }

  Future<void> _loadTimetableForDate() async {
    setState(() => isLoadingTimetable = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final data = await ApiService.get('$kStaffTodayTimetable?date=$dateStr');

      if (data != null && data['data'] != null) {
        setState(() {
          timetableSlots = List<Map<String, dynamic>>.from(data['data']);
          currentDay = data['day']?.toString();
          currentDate = data['date']?.toString();
        });
      }
    } catch (e) {
      print('Error loading timetable: $e');
    } finally {
      setState(() => isLoadingTimetable = false);
    }
  }

  Future<void> _loadStudentsForSlot(Map<String, dynamic> slot) async {
    final batchId = slot['batch']?['_id']?.toString();
    final hour = slot['hour'];
    if (batchId == null) return;

    setState(() {
      selectedSlot = slot;
      isLoadingStudents = true;
      students.clear();
      attendanceMap.clear();
    });

    try {
      // Load students
      final studentsData = await ApiService.get(
        '$kStaffBatchStudents/$batchId',
      );

      // Load existing attendance for this slot
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final attendanceData = await ApiService.get(
        '$kAttendanceBatchDateHour/$batchId/date/$dateStr/hour/$hour',
      );

      if (studentsData != null && studentsData['data'] != null) {
        // Build map of existing attendance records
        Map<String, String> existingAttendance = {};
        if (attendanceData != null && attendanceData['data'] != null) {
          for (var record in attendanceData['data']) {
            final studentId =
                record['student_id']?['_id']?.toString() ??
                record['student_id']?.toString() ??
                '';
            final status = record['attendance_status']?.toString() ?? 'present';
            if (studentId.isNotEmpty) {
              existingAttendance[studentId] = status;
            }
          }
        }

        setState(() {
          students = List<Map<String, dynamic>>.from(studentsData['data']);
          // Set attendance status from existing records, or default to 'present'
          for (var student in students) {
            final studentId = student['_id']?.toString() ?? '';
            attendanceMap[studentId] =
                existingAttendance[studentId] ?? 'present';
          }
        });
      }
    } catch (e) {
      print('Error loading students: $e');
    } finally {
      setState(() => isLoadingStudents = false);
    }
  }

  Future<void> _saveAttendance() async {
    if (selectedSlot == null || students.isEmpty) return;

    setState(() => isSaving = true);

    final batchId = selectedSlot!['batch']?['_id']?.toString() ?? '';
    final subjectId = selectedSlot!['subject']?['_id']?.toString() ?? '';
    final hour = selectedSlot!['hour'];
    final semesterNumber = selectedSlot!['semester_number'] ?? 1;

    // Prepare bulk attendance data
    final attendanceRecords = students.map((student) {
      final studentId = student['_id']?.toString() ?? '';
      return {
        'student_id': studentId,
        'attendance_status': attendanceMap[studentId] ?? 'absent',
      };
    }).toList();

    try {
      final res = await ApiService.post(kAttendanceMarkBulk, {
        'batch_id': batchId,
        'subject_id': subjectId,
        'date': currentDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'hour': hour,
        'semester_number': semesterNumber,
        'students': attendanceRecords,
      });

      if (res != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance marked successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Go back to slot list
          setState(() {
            selectedSlot = null;
            students.clear();
            attendanceMap.clear();
          });
          // Refresh timetable to update marked status
          _loadTimetableForDate();
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

  String _getDateDisplayText() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final diff = today.difference(selected).inDays;

    if (diff == 0) {
      return 'Today, ${DateFormat('MMM d').format(selectedDate)}';
    } else if (diff == 1) {
      return 'Yesterday, ${DateFormat('MMM d').format(selectedDate)}';
    } else {
      return DateFormat('EEE, MMM d').format(selectedDate);
    }
  }

  bool _canGoToNextDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    return selected.isBefore(today);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (selectedSlot != null)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              selectedSlot = null;
                              students.clear();
                              attendanceMap.clear();
                            });
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      if (selectedSlot != null) const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedSlot != null
                              ? "Mark Attendance"
                              : "Attendance",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Date Selector Row
                  if (selectedSlot == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Previous Day
                          IconButton(
                            onPressed: () {
                              setState(() {
                                selectedDate = selectedDate.subtract(
                                  const Duration(days: 1),
                                );
                              });
                              _loadTimetableForDate();
                            },
                            icon: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          // Date Display & Picker
                          GestureDetector(
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
                                _loadTimetableForDate();
                              }
                            },
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getDateDisplayText(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Next Day
                          IconButton(
                            onPressed: _canGoToNextDay()
                                ? () {
                                    setState(() {
                                      selectedDate = selectedDate.add(
                                        const Duration(days: 1),
                                      );
                                    });
                                    _loadTimetableForDate();
                                  }
                                : null,
                            icon: Icon(
                              Icons.chevron_right,
                              color: _canGoToNextDay()
                                  ? Colors.white
                                  : Colors.white38,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      "Hour ${selectedSlot!['hour']} - ${selectedSlot!['subject']?['name'] ?? ''}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: isLoadingTimetable
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : selectedSlot == null
                  ? _buildTimetableSlotsList()
                  : _buildAttendanceMarkingUI(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableSlotsList() {
    if (timetableSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              "No classes assigned for today",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTimetableForDate,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: timetableSlots.length,
        itemBuilder: (context, index) {
          return _buildSlotCard(timetableSlots[index]);
        },
      ),
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    final hour = slot['hour']?.toString() ?? '';
    final subjectName =
        slot['subject']?['name']?.toString() ?? 'Unknown Subject';
    final batchName = slot['batch']?['name']?.toString() ?? '';
    final courseName = slot['batch']?['course']?.toString() ?? '';
    final totalStudents = slot['total_students'] ?? 0;
    final markedCount = slot['marked_count'] ?? 0;
    final isMarked = slot['is_marked'] == true;

    return GestureDetector(
      onTap: () => _loadStudentsForSlot(slot),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMarked ? Colors.green.shade200 : Colors.grey.shade100,
            width: isMarked ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Hour badge
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: isMarked
                    ? Colors.green.shade50
                    : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  hour,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isMarked ? Colors.green : primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subjectName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    batchName.isNotEmpty ? batchName : courseName,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalStudents students',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (isMarked) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$markedCount marked',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              isMarked ? Icons.check_circle : Icons.chevron_right,
              color: isMarked ? Colors.green : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceMarkingUI() {
    if (isLoadingStudents) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (students.isEmpty) {
      return Center(
        child: Text(
          'No students in this batch',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return Column(
      children: [
        // Quick Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      for (var student in students) {
                        final studentId = student['_id']?.toString() ?? '';
                        attendanceMap[studentId] = 'present';
                      }
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                  child: const Text('All Present'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      for (var student in students) {
                        final studentId = student['_id']?.toString() ?? '';
                        attendanceMap[studentId] = 'absent';
                      }
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('All Absent'),
                ),
              ),
            ],
          ),
        ),

        // Students List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: students.length,
            itemBuilder: (context, index) {
              return _buildStudentAttendanceCard(students[index]);
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
    );
  }

  Widget _buildStudentAttendanceCard(Map<String, dynamic> student) {
    final studentId = student['_id']?.toString() ?? '';
    final studentName = student['name']?.toString() ?? '';
    final imageUrl = student['profile_image_url']?.toString() ?? '';
    final status = attendanceMap[studentId] ?? 'present';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.1),
            ),
            child: ClipOval(
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          studentName.isNotEmpty
                              ? studentName[0].toUpperCase()
                              : 'S',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        studentName.isNotEmpty
                            ? studentName[0].toUpperCase()
                            : 'S',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Text(
              studentName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          // Status buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusButton(
                'present',
                'P',
                status == 'present',
                studentId,
                Colors.green,
              ),
              const SizedBox(width: 6),
              _buildStatusButton(
                'absent',
                'A',
                status == 'absent',
                studentId,
                Colors.red,
              ),
              const SizedBox(width: 6),
              _buildStatusButton(
                'late',
                'L',
                status == 'late',
                studentId,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
    String value,
    String label,
    bool isSelected,
    String studentId,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          attendanceMap[studentId] = value;
        });
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}
