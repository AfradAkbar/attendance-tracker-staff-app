class StudentModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String rollNumber;
  final String batchName;

  StudentModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.rollNumber,
    required this.batchName,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      rollNumber: json['roll_number']?.toString() ?? '',
      batchName: json['batch_id']?['name']?.toString() ?? '',
    );
  }
}
