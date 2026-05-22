import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';

/// Hướng dẫn chơi — khớp web `/play/guide`.
class PlayGuideScreen extends StatelessWidget {
  const PlayGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hướng dẫn chơi')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text('Play Hub — Yume', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: YumeColors.ink)),
          SizedBox(height: 12),
          _GuideSection(
            title: 'Game kana / quiz',
            body: 'Chọn game trong tab Game → CHƠI. Mỗi phiên có tim, câu hỏi romaji/kana, nhận EXP và Xu khi kết thúc.',
          ),
          _GuideSection(
            title: 'Kanji Memory',
            body: 'Lật cặp thẻ kanji–nghĩa. Hoàn thành để gửi điểm lên server.',
          ),
          _GuideSection(
            title: 'Daily Challenge',
            body: 'Thử thách mỗi ngày — thưởng EXP/Xu bonus khi hoàn thành lần đầu trong ngày.',
          ),
          _GuideSection(
            title: 'PvP',
            body: 'Tạo phòng hoặc nhập mã phòng để thi đấu với bạn bè.',
          ),
          _GuideSection(
            title: 'Cửa hàng xu',
            body: 'Dùng Xu mua power-up (tim thêm, gợi ý, v.v.) và kích hoạt trong phiên chơi.',
          ),
          _GuideSection(
            title: 'Bảng xếp hạng',
            body: 'BXH tuần/tháng theo điểm game và BXH EXP tổng.',
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: YumeColors.primary)),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}
