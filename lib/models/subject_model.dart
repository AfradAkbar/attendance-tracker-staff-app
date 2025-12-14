class SubjectModel {
  final String id;
  final String subjectName;
  final String courseName;
  final String courseId;
  final List<int> semesters;

  SubjectModel({
    required this.id,
    required this.subjectName,
    required this.courseName,
    required this.courseId,
    required this.semesters,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['_id']?.toString() ?? '',
      subjectName: json['subject_name']?.toString() ?? '',
      courseName: json['course_id']?['name']?.toString() ?? '',
      courseId: json['course_id']?['_id']?.toString() ?? '',
      semesters: (json['semesters'] as List?)?.cast<int>() ?? [],
    );
  }
}
