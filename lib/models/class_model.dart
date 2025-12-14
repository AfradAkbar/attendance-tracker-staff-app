class ClassModel {
  final String id;
  final String batchName;
  final String courseName;
  final String courseId;
  final int startYear;
  final int endYear;
  final int strength;
  final int currentSemester;

  ClassModel({
    required this.id,
    required this.batchName,
    required this.courseName,
    required this.courseId,
    required this.startYear,
    required this.endYear,
    required this.strength,
    required this.currentSemester,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['_id']?.toString() ?? '',
      batchName: json['name']?.toString() ?? '',
      courseName: json['course_id']?['name']?.toString() ?? '',
      courseId: json['course_id']?['_id']?.toString() ?? '',
      startYear: json['start_year'] ?? 0,
      endYear: json['end_year'] ?? 0,
      strength: json['strength'] ?? 0,
      currentSemester: json['current_semester'] ?? 1,
    );
  }
}
