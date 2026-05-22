import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../data/homepage_content.dart';

/// Cảm nhận học viên — thẻ trắng, 5 sao, avatar.
class HomeTestimonialsSection extends StatelessWidget {
  const HomeTestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: Column(
        children: [
          const Text(
            HomepageContent.testimonialsTitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            HomepageContent.testimonialsSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.45),
          ),
          const SizedBox(height: 20),
          ...HomepageContent.testimonials.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TestimonialCard(item: t),
              )),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.item});

  final HomepageTestimonial item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (_) => const Icon(Icons.star_rounded, size: 18, color: Color(0xFFD81B60)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '"${item.quote}"',
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Color(0xFF334155),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: YumeColors.pinkLight,
                backgroundImage: item.avatarUrl != null ? NetworkImage(item.avatarUrl!) : null,
                child: item.avatarUrl == null
                    ? Text(item.name.isNotEmpty ? item.name[0] : '?', style: const TextStyle(fontWeight: FontWeight.w700))
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(item.level, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
