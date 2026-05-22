import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../models/friend_models.dart';
import '../../models/social_post.dart';
import '../../utils/account_format.dart';
import '../../utils/image_url.dart';

/// Composer đăng bài — responsive, không tràn ngang (mẫu Cộng đồng Sakura).
class SakuraFeedComposer extends StatelessWidget {
  const SakuraFeedComposer({
    super.key,
    required this.avatarUrl,
    required this.avatarInitial,
    required this.controller,
    required this.onSubmit,
    required this.creating,
    required this.onPickImage,
    this.onEmoji,
    this.imagePreviewBytes,
    this.hintText = 'Chia sẻ khoảnh khắc học tập của bạn...',
    this.designMode = false,
  });

  final String avatarUrl;
  final String avatarInitial;
  final TextEditingController controller;
  final VoidCallback? onSubmit;
  final bool creating;
  final VoidCallback? onPickImage;
  final ValueChanged<String>? onEmoji;
  final Uint8List? imagePreviewBytes;
  final String hintText;
  final bool designMode;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YumeColors.card,
      elevation: 1,
      shadowColor: const Color(0x140F172A),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: YumeColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: YumeColors.pinkLight,
                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Text(avatarInitial, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !designMode,
                    maxLines: 3,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: const TextStyle(color: YumeColors.muted, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: YumeColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: YumeColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: YumeColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: designMode ? null : onPickImage,
                  icon: const Icon(Icons.image_outlined, color: YumeColors.muted),
                  tooltip: 'Ảnh',
                ),
                if (onEmoji != null)
                  IconButton(
                    onPressed: designMode ? null : () => _showEmojiPicker(context),
                    icon: const Icon(Icons.emoji_emotions_outlined, color: YumeColors.muted),
                    tooltip: 'Cảm xúc',
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: designMode || creating ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: YumeColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    minimumSize: const Size(0, 40),
                  ),
                  child: creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Đăng'),
                ),
              ],
            ),
            if (imagePreviewBytes != null && imagePreviewBytes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(imagePreviewBytes!, height: 120, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    const emojis = ['👍', '❤️', '🌸', '🔥', '😆', '✨'];
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: emojis
                .map(
                  (e) => InkWell(
                    onTap: () {
                      onEmoji?.call(e);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

/// Thẻ bài đăng cộng đồng — thích / bình luận / chia sẻ, không dùng hàng emoji cố định.
class SakuraFeedPostCard extends StatelessWidget {
  const SakuraFeedPostCard({
    super.key,
    required this.post,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.authorInitial,
    required this.commentCount,
    required this.liked,
    required this.onLike,
    required this.onComment,
    this.onShare,
    this.onDelete,
    this.designMode = false,
  });

  final SocialPost post;
  final String authorName;
  final String authorAvatarUrl;
  final String authorInitial;
  final int commentCount;
  final bool liked;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final bool designMode;

  @override
  Widget build(BuildContext context) {
    final img = buildImageUrl(post.imageUrl);
    final reactions = post.totalReactions;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: YumeColors.card,
        elevation: 1,
        shadowColor: const Color(0x120F172A),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: YumeColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: YumeColors.pinkLight,
                      backgroundImage: authorAvatarUrl.isNotEmpty ? NetworkImage(authorAvatarUrl) : null,
                      child: authorAvatarUrl.isEmpty
                          ? Text(authorInitial, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: YumeColors.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            formatRelativeTime(post.createdAt),
                            style: const TextStyle(fontSize: 12, color: YumeColors.muted),
                          ),
                        ],
                      ),
                    ),
                    if (post.isOwner && onDelete != null)
                      TextButton(
                        onPressed: designMode ? null : onDelete,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Xóa', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              if (post.content != null && post.content!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Text(
                    post.content!,
                    style: const TextStyle(fontSize: 14, height: 1.45, color: YumeColors.text),
                  ),
                ),
              if (img.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(img, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    _FeedAction(
                      icon: liked ? Icons.favorite : Icons.favorite_border,
                      iconColor: liked ? YumeColors.primary : YumeColors.muted,
                      label: '$reactions',
                      onTap: designMode ? null : onLike,
                    ),
                    _FeedAction(
                      icon: Icons.chat_bubble_outline,
                      label: '$commentCount',
                      onTap: designMode ? null : onComment,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: designMode ? null : onShare,
                      icon: const Icon(Icons.share_outlined, color: YumeColors.muted, size: 22),
                      tooltip: 'Chia sẻ',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedAction extends StatelessWidget {
  const _FeedAction({
    required this.icon,
    required this.label,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: iconColor ?? YumeColors.muted),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: YumeColors.muted)),
          ],
        ),
      ),
    );
  }
}

/// Sheet bình luận — tránh tràn layout trên thẻ bài viết.
Future<void> showSakuraCommentsSheet({
  required BuildContext context,
  required List<SocialComment> comments,
  required TextEditingController inputController,
  required Future<void> Function() onSubmit,
  required bool designMode,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: YumeColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final sorted = [...comments]
        ..sort((a, b) {
          final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return tb.compareTo(ta);
        });
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.55,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text('Bình luận', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              const Divider(height: 1),
              Expanded(
                child: sorted.isEmpty
                    ? const Center(child: Text('Chưa có bình luận', style: TextStyle(color: YumeColors.muted)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: sorted.length,
                        itemBuilder: (_, i) {
                          final c = sorted[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.author.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(c.content, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: inputController,
                        enabled: !designMode,
                        decoration: const InputDecoration(
                          hintText: 'Viết bình luận…',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => onSubmit(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: YumeColors.primary),
                      onPressed: designMode ? null : () => onSubmit(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
