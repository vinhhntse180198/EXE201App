import 'package:flutter/material.dart';

import '../models/auth_response.dart';
import '../screens/assessment/placement_test_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/staff/admin_shell.dart';
import '../screens/staff/moderator_shell.dart';
import '../widgets/navigation/main_shell.dart';
import 'role_utils.dart';

/// Màn hình sau đăng nhập / khôi phục phiên — khớp web `getPostLoginRoute` + placement gate.
Widget buildPostLoginScreen(AuthResponse? auth) {
  if (auth == null) return const LoginScreen();
  if (isAdminUser(auth.user)) return const AdminShell();
  if (isModeratorUser(auth.user)) return const ModeratorShell();
  if (auth.needsPlacementTest && !isStaffUser(auth.user)) {
    return const PlacementTestScreen();
  }
  return const MainShell();
}

void navigatePostLogin(BuildContext context, AuthResponse auth) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => buildPostLoginScreen(auth)),
    (_) => false,
  );
}
