import 'package:flutter/material.dart';
import 'package:staff_app/api_service.dart';
import 'package:staff_app/constants.dart';

class StudentsView extends StatefulWidget {
  const StudentsView({super.key});

  @override
  State<StudentsView> createState() => _StudentsViewState();
}

class _StudentsViewState extends State<StudentsView> {
  static const Color primaryColor = Color(0xFF5B8A72); // Sage green
  static const Color surfaceColor = Color(0xFFF8F6F4); // Warm off-white

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final data = await ApiService.get(kStaffMyStudents);

      if (!mounted) return;
      if (data != null && data['data'] != null) {
        // Only include students whose status is 'approved'
        final allStudents = List<Map<String, dynamic>>.from(data['data']);
        students = allStudents.toList();
        print(students);
        filteredStudents = students;
        setState(() {});
      }
    } catch (e) {
      print('Error loading students: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _filterStudents(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredStudents = students;
      } else {
        filteredStudents = students.where((student) {
          final name = student['name']?.toString().toLowerCase() ?? '';
          final rollNumber =
              student['roll_number']?.toString().toLowerCase() ?? '';
          final registerNumber =
              student['register_number']?.toString().toLowerCase() ?? '';
          final email = student['email']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              rollNumber.contains(query.toLowerCase()) ||
              registerNumber.contains(query.toLowerCase()) ||
              email.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _updateRegisterNumber(
    String studentId,
    String registerNumber,
  ) async {
    try {
      final response = await ApiService.put(
        '$kUpdateStudentRegisterNumber/$studentId/register-number',
        {'register_number': registerNumber},
      );

      if (response != null && response['success'] == true) {
        // Update local state
        setState(() {
          final index = students.indexWhere((s) => s['_id'] == studentId);
          if (index != -1) {
            students[index]['register_number'] = registerNumber;
          }
          final filteredIndex = filteredStudents.indexWhere(
            (s) => s['_id'] == studentId,
          );
          if (filteredIndex != -1) {
            filteredStudents[filteredIndex]['register_number'] = registerNumber;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Register number updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response?['message'] ?? 'Failed to update register number',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditRegisterNumberDialog(Map<String, dynamic> student) {
    final controller = TextEditingController(
      text: student['register_number']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Register Number'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update register number for ${student['name']}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Register Number',
                  hintText: 'e.g., 2024CS001',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Register number is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                _updateRegisterNumber(student['_id'], controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
                  const Text(
                    "My Students",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${students.length} students in your class",
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  TextField(
                    onChanged: _filterStudents,
                    decoration: InputDecoration(
                      hintText: 'Search by name, roll number, or email',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 227, 239, 233),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20), // Students List
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : filteredStudents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isEmpty
                                ? "No students in your class"
                                : "No students found",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStudents,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          return _buildStudentCard(filteredStudents[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final name = student['name']?.toString() ?? '';
    final email = student['email']?.toString() ?? '';
    final phone = student['phone_number']?.toString() ?? '';
    // Check both field names for profile image
    final imageUrl =
        student['profile_image_url']?.toString() ??
        student['image_url']?.toString() ??
        '';
    final registerNumber = student['register_number']?.toString() ?? '';

    // Batch and course details
    final batchData = student['batch_id'] as Map<String, dynamic>?;
    final courseName =
        batchData?['course_id']?['name']?.toString() ??
        batchData?['course']?['name']?.toString() ??
        '';
    final startYear = batchData?['start_year']?.toString() ?? '';
    final endYear = batchData?['end_year']?.toString() ?? '';
    final semester = batchData?['current_semester']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _showStudentDetails(student),
      child: Container(
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
              height: 48,
              width: 48,
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
                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
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
                          name.isNotEmpty ? name[0].toUpperCase() : 'S',
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
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (courseName.isNotEmpty)
                    Text(
                      '$courseName • $startYear-$endYear • Sem $semester',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (registerNumber.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        registerNumber,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        phone,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.email_outlined,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          email,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    final name = student['name']?.toString() ?? '';
    final email = student['email']?.toString() ?? '';
    final phone = student['phone_number']?.toString() ?? '';
    final gender = student['gender']?.toString() ?? '';
    final dob = student['dob']?.toString() ?? '';
    final address = student['address']?.toString() ?? '';
    // Check both field names for profile image
    final imageUrl =
        student['profile_image_url']?.toString() ??
        student['image_url']?.toString() ??
        '';
    final registerNumber = student['register_number']?.toString() ?? '';
    final studentId = student['_id']?.toString() ?? '';

    // Batch and course details
    final batchData = student['batch_id'] as Map<String, dynamic>?;
    final courseName =
        batchData?['course_id']?['name']?.toString() ??
        batchData?['course']?['name']?.toString() ??
        '';
    final startYear = batchData?['start_year']?.toString() ?? '';
    final endYear = batchData?['end_year']?.toString() ?? '';
    final semester = batchData?['current_semester']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // State for attendance data within the bottom sheet
        List<Map<String, dynamic>> semesterAttendance = [];
        Map<String, dynamic>? overallAttendance;
        bool isAttendanceLoading = true;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Fetch attendance on first build
            if (isAttendanceLoading && studentId.isNotEmpty) {
              ApiService.get(kStudentOverallAttendance(studentId))
                  .then((data) {
                    if (data != null &&
                        data['success'] == true &&
                        data['data'] != null) {
                      final result = data['data'] as Map<String, dynamic>;
                      setSheetState(() {
                        semesterAttendance = List<Map<String, dynamic>>.from(
                          result['semesters'] ?? [],
                        );
                        overallAttendance =
                            result['overall'] as Map<String, dynamic>?;
                        isAttendanceLoading = false;
                      });
                    } else {
                      setSheetState(() => isAttendanceLoading = false);
                    }
                  })
                  .catchError((e) {
                    print('Failed to fetch student overall attendance: $e');
                    setSheetState(() => isAttendanceLoading = false);
                  });
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Profile image
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor.withOpacity(0.1),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Center(
                                                child: Text(
                                                  name.isNotEmpty
                                                      ? name[0].toUpperCase()
                                                      : 'S',
                                                  style: TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.w600,
                                                    color: primaryColor,
                                                  ),
                                                ),
                                              ),
                                    )
                                  : Center(
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : 'S',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Name
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Course info
                          if (courseName.isNotEmpty)
                            Text(
                              '$courseName • $startYear-$endYear • Semester $semester',
                              style: TextStyle(
                                fontSize: 14,
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          const SizedBox(height: 12),
                          // Register number with edit button
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _showEditRegisterNumberDialog(student);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: registerNumber.isNotEmpty
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: registerNumber.isNotEmpty
                                      ? Colors.blue.withOpacity(0.3)
                                      : Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    size: 16,
                                    color: registerNumber.isNotEmpty
                                        ? Colors.blue
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    registerNumber.isNotEmpty
                                        ? registerNumber
                                        : 'No Register Number',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: registerNumber.isNotEmpty
                                          ? Colors.blue
                                          : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 14,
                                    color: registerNumber.isNotEmpty
                                        ? Colors.blue
                                        : Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Overall Attendance Section
                          _buildStudentAttendanceSection(
                            semesterAttendance,
                            overallAttendance,
                            isAttendanceLoading,
                          ),

                          const SizedBox(height: 20),
                          // Details grid
                          _buildDetailTile(
                            Icons.email_outlined,
                            'Email',
                            email,
                          ),
                          _buildDetailTile(
                            Icons.phone_outlined,
                            'Phone',
                            phone,
                          ),
                          _buildDetailTile(
                            Icons.person_outline,
                            'Gender',
                            gender.isNotEmpty
                                ? gender[0].toUpperCase() + gender.substring(1)
                                : '-',
                          ),
                          _buildDetailTile(
                            Icons.cake_outlined,
                            'Date of Birth',
                            dob.isNotEmpty ? dob : '-',
                          ),
                          if (address.isNotEmpty)
                            _buildDetailTile(
                              Icons.location_on_outlined,
                              'Address',
                              address,
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getAttendanceColor(int percentage) {
    if (percentage >= 75) return const Color(0xFF2E7D32);
    if (percentage >= 50) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  Widget _buildStudentAttendanceSection(
    List<Map<String, dynamic>> semesterAttendance,
    Map<String, dynamic>? overallAttendance,
    bool isLoading,
  ) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: primaryColor,
            ),
          ),
        ),
      );
    }

    if (semesterAttendance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.grey.shade400),
            const SizedBox(width: 10),
            Text(
              'No attendance records yet',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final overallPct = overallAttendance?['attendance_percentage'] ?? 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with overall percentage
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _getAttendanceColor(overallPct).withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 18,
                  color: _getAttendanceColor(overallPct),
                ),
                const SizedBox(width: 10),
                Text(
                  "Overall Attendance",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getAttendanceColor(overallPct).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "$overallPct%",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _getAttendanceColor(overallPct),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Semester rows
          ...semesterAttendance.map((sem) {
            final semNum = sem['semester'] ?? 0;
            final pct = sem['attendance_percentage'] ?? 0;
            final total = sem['total_classes'] ?? 0;
            final present = (sem['present'] ?? 0) + (sem['late'] ?? 0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _getAttendanceColor(pct).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        "S$semNum",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _getAttendanceColor(pct),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Semester $semNum",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct / 100.0,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getAttendanceColor(pct),
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$pct%",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _getAttendanceColor(pct),
                        ),
                      ),
                      Text(
                        "$present/$total",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
