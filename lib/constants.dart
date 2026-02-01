const kBaseUrl = 'http://192.168.1.7:3000/api';

const kStaffLoginRoute = '$kBaseUrl/staff/login';
const kStaffProfile = '$kBaseUrl/staff/profile';
const kStaffProfilePhoto = '$kBaseUrl/staff/profile/photo';
const kStaffMyClass = '$kBaseUrl/staff/my-class';
const kStaffMySubjects = '$kBaseUrl/staff/my-subjects';
const kStaffMyStudents = '$kBaseUrl/staff/my-students';
const kStaffTodayTimetable = '$kBaseUrl/staff/my-timetable/today';
const kStaffBatchStudents = '$kBaseUrl/staff/students'; // Append /:batch_id
const kAttendanceMarkBulk = '$kBaseUrl/attendance/mark-bulk';
const kAttendanceBatchDateHour =
    '$kBaseUrl/attendance/batch'; // Append /:batch_id/date/:date/hour/:hour

// Notifications (unified - works for all user types)
const kNotifications = '$kBaseUrl/notification';

// HOD notification endpoints
const kHodSendNotification = '$kBaseUrl/staff/hod/notifications';
const kHodBatches = '$kBaseUrl/staff/hod/batches';

// Attendance requests (face verification failures)
const kAttendanceRequests = '$kBaseUrl/staff/attendance-requests';

// Pending student approval requests
const kPendingStudents = '$kBaseUrl/staff/pending-students';
const kUpdateStudentStatus =
    '$kBaseUrl/staff/students'; // Append /:student_id/status
const kUpdateStudentRegisterNumber =
    '$kBaseUrl/staff/students'; // Append /:student_id/register-number
