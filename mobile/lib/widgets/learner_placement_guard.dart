import 'package:flutter/material.dart';

import '../config/app_flags.dart';
import '../core/session/app_session.dart';
import '../screens/assessment/placement_test_screen.dart';
import '../utils/role_utils.dart';

/// Chặn learner chưa placement — khớp web `PrivateRoute`.
mixin LearnerPlacementGuard<T extends StatefulWidget> on State<T> {
  void guardPlacementOnTab() {
    if (designMode) return;
    final auth = AppSession.instance.user;
    if (auth == null) return;
    if (isStaffUser(auth.user)) return;
    if (!auth.needsPlacementTest) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const PlacementTestScreen()),
        (_) => false,
      );
    });
  }
}
