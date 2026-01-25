import 'package:flutter/material.dart';
import 'package:staff_app/api_service.dart';
import 'package:staff_app/constants.dart';

/// Screen for viewing and managing pending student registration approvals.
/// Class teachers see students from their batch only.
/// HODs see students from all department batches.
class StudentApprovalView extends StatefulWidget {
  const StudentApprovalView({super.key});

  @override
  State<StudentApprovalView> createState() => _StudentApprovalViewState();
}

class _StudentApprovalViewState extends State<StudentApprovalView> {
  static const Color primaryColor = Color(0xFF5B8A72);
  static const Color surfaceColor = Color(0xFFF8F6F4);

  List<Map<String, dynamic>> _pendingStudents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingStudents();
  }

  Future<void> _loadPendingStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get(kPendingStudents);
      if (response != null && response['success'] == true) {
        setState(() {
          _pendingStudents = List<Map<String, dynamic>>.from(
            response['data'] ?? [],
          );
        });
      } else {
        // If response is null or unsuccessful, show empty state instead of error
        // This handles cases where staff has no batches assigned
        setState(() {
          _pendingStudents = [];
        });
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStudentStatus(
    String studentId,
    String status, {
    String? registerNumber,
  }) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (registerNumber != null && registerNumber.isNotEmpty) {
        body['register_number'] = registerNumber;
      }

      final response = await ApiService.put(
        '$kUpdateStudentStatus/$studentId/status',
        body,
      );

      if (response != null && response['success'] == true) {
        // Remove from list
        setState(() {
          _pendingStudents.removeWhere((s) => s['_id'] == studentId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Student ${status == 'accept' ? 'accepted' : 'rejected'} successfully',
              ),
              backgroundColor: status == 'accept' ? Colors.green : Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?['message'] ?? 'Failed to update status'),
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

  void _showRejectDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Student?'),
        content: Text(
          'Are you sure you want to reject ${student['name']}? They will not be able to access the system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStudentStatus(student['_id'], 'reject');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAcceptDialog(Map<String, dynamic> student) {
    final registerNumberController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Student'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Accept ${student['name']} and assign a register number.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: registerNumberController,
                decoration: InputDecoration(
                  labelText: 'Register Number *',
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
                _updateStudentStatus(
                  student['_id'],
                  'accept',
                  registerNumber: registerNumberController.text.trim(),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    final name = student['name']?.toString() ?? 'Unknown';
    final email = student['email']?.toString() ?? '';
    final phone = student['phone_number']?.toString() ?? '';
    final gender = student['gender']?.toString() ?? '';
    final dob = student['dob']?.toString() ?? '';
    final address = student['address']?.toString() ?? '';
    final imageUrl =
        student['profile_image_url']?.toString() ??
        student['image_url']?.toString() ??
        '';

    // Batch and course details
    final batchData = student['batch_id'] as Map<String, dynamic>?;
    final batchName = batchData?['name']?.toString() ?? '';
    final startYear = batchData?['start_year']?.toString() ?? '';
    final endYear = batchData?['end_year']?.toString() ?? '';
    final semester = batchData?['current_semester']?.toString() ?? '';

    // Course details
    final courseData = batchData?['course_id'] as Map<String, dynamic>?;
    final courseName = courseData?['name']?.toString() ?? '';

    // Department details
    final deptData = courseData?['department_id'] as Map<String, dynamic>?;
    final deptName = deptData?['name']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Profile image
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.1),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : 'S',
                                        style: TextStyle(
                                          fontSize: 40,
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
                                    fontSize: 40,
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
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Pending Approval',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Academic info section
                    if (courseName.isNotEmpty || batchName.isNotEmpty) ...[
                      _buildSectionTitle('Academic Information'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            if (courseName.isNotEmpty)
                              _buildDetailRow(
                                Icons.school_outlined,
                                'Course',
                                courseName,
                              ),
                            if (deptName.isNotEmpty)
                              _buildDetailRow(
                                Icons.account_balance_outlined,
                                'Department',
                                deptName,
                              ),
                            if (batchName.isNotEmpty)
                              _buildDetailRow(
                                Icons.class_outlined,
                                'Batch',
                                batchName,
                              ),
                            if (startYear.isNotEmpty && endYear.isNotEmpty)
                              _buildDetailRow(
                                Icons.calendar_today_outlined,
                                'Academic Year',
                                '$startYear - $endYear',
                              ),
                            if (semester.isNotEmpty)
                              _buildDetailRow(
                                Icons.schedule_outlined,
                                'Current Semester',
                                'Semester $semester',
                                isLast: true,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Personal info section
                    _buildSectionTitle('Personal Information'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.email_outlined, 'Email', email),
                          if (phone.isNotEmpty)
                            _buildDetailRow(
                              Icons.phone_outlined,
                              'Phone',
                              phone,
                            ),
                          if (gender.isNotEmpty)
                            _buildDetailRow(
                              Icons.person_outline,
                              'Gender',
                              gender.isNotEmpty
                                  ? gender[0].toUpperCase() +
                                        gender.substring(1)
                                  : '-',
                            ),
                          if (dob.isNotEmpty)
                            _buildDetailRow(
                              Icons.cake_outlined,
                              'Date of Birth',
                              dob,
                            ),
                          if (address.isNotEmpty)
                            _buildDetailRow(
                              Icons.location_on_outlined,
                              'Address',
                              address,
                              isLast: true,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showRejectDialog(student);
                            },
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showAcceptDialog(student);
                            },
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: primaryColor),
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
                  value.isNotEmpty ? value : '-',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Student Approvals'),
        actions: [
          IconButton(
            onPressed: _loadPendingStudents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPendingStudents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pendingStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No pending approvals',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text(
              'All student registrations have been processed',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingStudents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingStudents.length,
        itemBuilder: (context, index) =>
            _buildStudentCard(_pendingStudents[index]),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final name = student['name']?.toString() ?? 'Unknown';
    final email = student['email']?.toString() ?? '';
    final phone = student['phone_number']?.toString() ?? '';
    final batchName = student['batch_id']?['name']?.toString() ?? '';
    final imageUrl =
        student['profile_image_url']?.toString() ??
        student['image_url']?.toString() ??
        '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showStudentDetails(student),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.1),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: ClipOval(
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildInitial(name),
                            )
                          : _buildInitial(name),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (batchName.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              batchName,
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (phone.isNotEmpty)
                          Text(
                            phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // View details icon
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(student),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAcceptDialog(student),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitial(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'S',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      ),
    );
  }
}
