const kBaseUrl = 'http://192.168.1.7:3000/api';

const kStaffLoginRoute = '$kBaseUrl/staff/login';
const kStaffProfile = '$kBaseUrl/staff/profile';
const kStaffMyClass = '$kBaseUrl/staff/my-class';
const kStaffMySubjects = '$kBaseUrl/staff/my-subjects';
const kStaffMyStudents = '$kBaseUrl/staff/my-students';
const kStaffNotifications = '$kBaseUrl/staff/notifications';
const kStaffTodayTimetable = '$kBaseUrl/staff/my-timetable/today';
const kStaffBatchStudents = '$kBaseUrl/staff/students'; // Append /:batch_id
const kAttendanceMarkBulk = '$kBaseUrl/attendance/mark-bulk';
const kAttendanceBatchDateHour =
    '$kBaseUrl/attendance/batch'; // Append /:batch_id/date/:date/hour/:hour
