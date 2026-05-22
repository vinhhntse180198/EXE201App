import '../models/progress_summary.dart';
import '../models/social_post.dart';
import '../utils/image_url.dart';

String accountLevelTitle(String levelCode) {
  switch (levelCode.toUpperCase()) {
    case 'N5':
      return 'N5 Sơ cấp';
    case 'N4':
      return 'N4 Trung cấp';
    case 'N3':
      return 'N3 Trung cao';
    case 'N2':
      return 'N2 Cao cấp';
    case 'N1':
      return 'N1 Thành thạo';
    default:
      return '$levelCode — Học viên';
  }
}

String formatIntVi(int n) {
  final v = n.abs();
  final s = v.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
  return n < 0 ? '-$s' : s;
}

({int completed, int total, int pct}) aggregateLessonProgress(List<LevelCompletion> byLevel) {
  var completed = 0;
  var total = 0;
  for (final row in byLevel) {
    completed += row.completedLessons;
    total += row.totalPublishedLessons;
  }
  final safeDone = completed > total ? total : completed;
  final pct = total > 0 ? ((safeDone / total) * 100).round().clamp(0, 100) : 0;
  return (completed: safeDone, total: total, pct: pct);
}

class MemoryLaneCell {
  const MemoryLaneCell({required this.imageUrl, required this.kind, this.postId});

  final String imageUrl;
  final String kind;
  final int? postId;
}

List<MemoryLaneCell> buildMemoryLaneCells({
  required List<SocialPost> posts,
  required String coverUrl,
  required String avatarUrl,
}) {
  final seen = <String>{};
  final cells = <MemoryLaneCell>[];

  bool push(String? path, String kind, {int? postId}) {
    if (path == null || path.isEmpty) return false;
    final full = buildImageUrl(path);
    if (full.isEmpty) return false;
    final key = full.split('?').first;
    if (seen.contains(key)) return false;
    seen.add(key);
    cells.add(MemoryLaneCell(imageUrl: full, kind: kind, postId: postId));
    return cells.length >= 4;
  }

  final sorted = [...posts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  for (final p in sorted) {
    if (push(p.imageUrl, 'post', postId: p.id)) break;
  }
  if (cells.length < 4 && coverUrl.isNotEmpty) {
    push(coverUrl, 'cover');
  }
  if (cells.length < 4 && avatarUrl.isNotEmpty) {
    push(avatarUrl, 'avatar');
  }
  return cells;
}

String formatRelativeTime(DateTime? createdAt) {
  if (createdAt == null) return '';
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  final d = createdAt.toLocal();
  return '${d.day}/${d.month}/${d.year}';
}

String formatPostVisibility(DateTime? createdAt) {
  if (createdAt == null) return 'Công khai';
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) return 'Vừa mới đăng • Công khai';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước • Công khai';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước • Công khai';
  final d = createdAt.toLocal();
  return '${d.day}/${d.month}/${d.year} • Công khai';
}
