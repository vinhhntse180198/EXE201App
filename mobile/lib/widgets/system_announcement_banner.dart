import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../config/app_flags.dart';
import '../core/session/app_session.dart';
import '../models/system_announcement.dart';
import '../services/public_service.dart';

/// Banner thông báo hệ thống — khớp web `SystemAnnouncementBanner`.
class SystemAnnouncementBanner extends StatefulWidget {
  const SystemAnnouncementBanner({super.key});

  @override
  State<SystemAnnouncementBanner> createState() => _SystemAnnouncementBannerState();
}

class _SystemAnnouncementBannerState extends State<SystemAnnouncementBanner> {
  SystemAnnouncement? _announcement;

  @override
  void initState() {
    super.initState();
    if (!designMode) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (mounted) _load();
        });
      });
    }
  }

  Future<void> _load() async {
    final a = await PublicService(AppSession.instance.api).fetchLatestAnnouncement();
    if (mounted && a != null && a.title.isNotEmpty) {
      setState(() => _announcement = a);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _announcement;
    if (a == null) return const SizedBox.shrink();
    return Dismissible(
      key: ValueKey(a.title),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => setState(() => _announcement = null),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDBA74)),
        ),
        child: Row(
          children: [
            const Icon(Icons.campaign_outlined, color: Color(0xFF9A3412), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  if (a.body.isNotEmpty)
                    Text(a.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
