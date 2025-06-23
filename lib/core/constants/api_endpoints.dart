// const String baseUrl = 'http://192.168.13.239:8000/api';
const String baseUrl = 'http://192.168.13.74:8000/api';
// const String baseUrl = 'https://beta.rrispat.in/api';

const String signupUrl = '$baseUrl/auth/signup';
const String loginUrl = '$baseUrl/auth/login';
const String meUrl = '$baseUrl/auth/me';

const String getDivisionsUrl = '$baseUrl/divisions';
const String addDivisionUrl = '$baseUrl/divisions';

// ---------------- Super Admin Endpoints ----------------
const String getAllUsersSuperAdminUrl = '$baseUrl/super-admin/users';
const String changeUserRoleUrl = '$baseUrl/super-admin/users/:id/role';
const String getAllTasksSuperAdminUrl = '$baseUrl/super-admin/tasks/all';
const String createTaskSuperAdminUrl = '$baseUrl/super-admin/tasks/super-admin';
