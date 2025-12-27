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
    setState(() => isLoading = true);

    try {
      final data = await ApiService.get(kStaffMyStudents);

      if (data != null && data['data'] != null) {
        setState(() {
          students = List<Map<String, dynamic>>.from(data['data']);
          print(students);
          filteredStudents = students;
        });
      }
    } catch (e) {
      print('Error loading students: $e');
    } finally {
      setState(() => isLoading = false);
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
          final email = student['email']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              rollNumber.contains(query.toLowerCase()) ||
              email.contains(query.toLowerCase());
        }).toList();
      }
    });
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
    final imageUrl = student['image_url']?.toString() ?? '';

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
    final imageUrl = student['image_url']?.toString() ?? '';

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
      builder: (context) => Container(
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
                              errorBuilder: (context, error, stackTrace) =>
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
                                name.isNotEmpty ? name[0].toUpperCase() : 'S',
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
                  const SizedBox(height: 24),
                  // Details grid
                  _buildDetailTile(Icons.email_outlined, 'Email', email),
                  _buildDetailTile(Icons.phone_outlined, 'Phone', phone),
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
