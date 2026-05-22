import '../models/user.dart';

bool isStaffUser(User? user) {
  final r = (user?.role ?? '').toLowerCase();
  return r == 'admin' || r == 'moderator';
}

bool isAdminUser(User? user) => (user?.role ?? '').toLowerCase() == 'admin';

bool isModeratorUser(User? user) => (user?.role ?? '').toLowerCase() == 'moderator';
