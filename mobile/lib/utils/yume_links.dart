import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fanpage Facebook chính thức của YumeGo-Ji.
const kYumeFacebookUrl = 'https://www.facebook.com/people/Yumego-Ji/61589902962841/';

Future<void> openYumeFacebookPage(BuildContext context) async {
  final uri = Uri.parse(kYumeFacebookUrl);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không mở được Facebook. Vui lòng thử lại.')),
    );
  }
}

String friendRequestStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return 'Đang chờ phản hồi';
    case 'accepted':
      return 'Đã chấp nhận';
    case 'rejected':
      return 'Đã từ chối';
    default:
      return status;
  }
}
