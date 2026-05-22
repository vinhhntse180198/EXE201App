import 'package:flutter/material.dart';

/// Nội dung trang chủ — theo mẫu landing YumeGo-ji (mobile).
class HomepageContent {
  static const brandName = 'YumeGo-ji';

  static const heroTitle = 'Học tiếng Nhật';
  static const heroHighlight = 'Thật phong cách.';
  static const heroDescription =
      'Khám phá vẻ đẹp của ngôn ngữ và văn hóa Nhật Bản qua lộ trình học hiện đại, tương tác và đầy cảm hứng.';
  static const heroCtaGuest = 'Bắt đầu ngay thôi';
  static const heroCtaMember = 'Tiếp tục học';

  static const featuresTitle = 'Tính năng nổi bật';
  static const featuresSubtitle =
      'Công cụ được thiết kế để bạn chinh phục tiếng Nhật một cách dễ dàng và thú vị.';

  static const features = <HomepageFeatureCard>[
    HomepageFeatureCard(
      icon: Icons.menu_book_rounded,
      iconColor: Color(0xFF16A34A),
      title: 'Học tập',
      description:
          'Bài giảng có cấu trúc theo năng lực, bám sát JLPT và có bài tập tương tác giúp ghi nhớ từ vựng nhanh.',
      linkLabel: 'Tìm hiểu thêm →',
      tabIndex: 2,
    ),
    HomepageFeatureCard(
      icon: Icons.chat_bubble_rounded,
      iconColor: Color(0xFF7C3AED),
      title: 'Trò chuyện',
      description:
          'Luyện phản xạ hội thoại cùng cộng đồng học viên và giáo viên để tự tin giao tiếp trong ngữ cảnh thực tế.',
      linkLabel: 'Thử ngay →',
      tabIndex: 3,
    ),
    HomepageFeatureCard(
      icon: Icons.sports_esports_rounded,
      iconColor: Color(0xFF7C3AED),
      title: 'Trò chơi',
      description:
          'Mini-game theo chủ điểm giúp ôn Kanji, từ vựng và mẫu câu theo cách vui hơn, nhớ lâu hơn.',
      linkLabel: 'Khám phá kho game →',
      tabIndex: 4,
    ),
  ];

  static const hanamiTitle = 'Phương pháp Hanami';
  static const hanamiSubtitle =
      'Triết lý học tập lấy cảm hứng từ hoa anh đào — từ mầm non đến nở rộ.';

  static const hanamiStages = <HanamiStage>[
    HanamiStage(
      title: 'Gieo Mầm (Tsubomi)',
      subtitle: 'Sprouting',
      description: 'Làm quen bảng chữ cái, từ vựng nền và thói quen học mỗi ngày.',
      imageOnRight: true,
    ),
    HanamiStage(
      title: 'Nở Rộ (Mankai)',
      subtitle: 'Blooming',
      description: 'Luyện nghe–nói, ôn Kanji qua game và thi đấu để củng cố kiến thức.',
      imageOnRight: false,
    ),
  ];

  static const testimonialsTitle = 'Cảm nhận học viên';
  static const testimonialsSubtitle = 'Câu chuyện thành công từ cộng đồng YumeGo-ji.';

  static const testimonials = <HomepageTestimonial>[
    HomepageTestimonial(
      name: 'Lan Anh',
      level: 'Học viên N5',
      quote: 'Lộ trình N5 rất dễ theo dõi, mỗi ngày học một ít vẫn thấy tiến bộ rõ.',
      avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB96mZjhhtdBCO82VL2lwW_fxJea65qRxit1ZsWKRUM_ipNoBom2zifSBLvfcqsCTEqflSwvUcj5mbUwCt6wO-kllK6NYzEwKI2kch8B7piII53Lb5KbCSlrH4Octx3SXCmwCa1Mdq9U2O4WgFR5MzAnXQ1lVO1lev20MRljekd9EhjRKvzTDILAe64D7-hBwH_fYOl31cR725pw61NBnjDU2DCepbc_xpb-eRmhq8xax_ReTUPITqLx2E2FrEym6NPkJzR1Shp65w',
    ),
    HomepageTestimonial(
      name: 'Minh Tuấn',
      level: 'Học viên N3',
      quote: 'Luyện nói và chat giúp mình tự tin hơn khi làm việc với đối tác Nhật.',
      avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCxt1q_dgTjyweQg_C11KrtpRFMhWMpoApdLWhJw-o4dctjQ7H4B3AU6s4UXb9OUALSs1MXAT2fXkY7GR9amLSm-9YC4xcASzmAMsSAjGM46zKqbSmhyK6xm7mRsQgWgB_9kELFfIb7uqLvazvRdY1JK7zcLXCb94ss7RuPm6b5chtCx-Jr8F7RNz3i_hyy3c7N-1dc7b6IBo7LFaA9ElfebynUcg7vaEr4QlbJE6N_BIWL3MqQU1gR67BNTD8Dt-0GC4UurfaLfh8',
    ),
    HomepageTestimonial(
      name: 'Thu Thảo',
      level: 'Học viên N4',
      quote: 'Game ôn Kanji vui, nhớ lâu hơn so với học thuộc lòng truyền thống.',
      avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuD4VoxO11xGzajOEu5GGSNohEyz0nApGunVra-g2RGGqss_cRjnB6u9doLyiywIbTTHKaYS8mJegquffQDY_xUOTetEjB5z9xy8Etl_w8wZpDVRMDaEEDpFdneo_ZPRoRnj7ihgRXPIzXy2KFfFcu70L2c1AOEwCEV6vJmaApkuQbPplmYTw3cBYuc8PiLPEhbegA6Pg_r9pZYwVwqLCwaYjaqhZLil7lF_WrcdvzF2jTaDYoGHKt-lYb46k_wxT9ruufshbIxnvro',
    ),
  ];

  static const footerLinks = ['Cookies', 'Cộng đồng', 'Quyền riêng tư', 'Điều khoản'];
  static const footerCopyright = '© 2026 YumeGo-ji Learning. Keep travelling.';
}

class HomepageFeatureCard {
  const HomepageFeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.linkLabel,
    required this.tabIndex,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String linkLabel;
  final int tabIndex;
}

class HanamiStage {
  const HanamiStage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageOnRight,
  });

  final String title;
  final String subtitle;
  final String description;
  final bool imageOnRight;
}

class HomepageTestimonial {
  const HomepageTestimonial({
    required this.name,
    required this.level,
    required this.quote,
    this.avatarUrl,
  });

  final String name;
  final String level;
  final String quote;
  final String? avatarUrl;
}
