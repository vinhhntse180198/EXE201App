-- Đồng bộ PHẦN BÀI HỌC lên Supabase (nguồn: seed Docker / part01).
-- An toàn chạy lại: UPSERT bài + thay từ vựng/kanji/ngữ pháp theo id cố định.
-- Ẩn bài placeholder trống (id 18, 20) khỏi danh sách học viên.

-- lesson_categories
INSERT INTO "lesson_categories" ("id", "level_id", "name", "slug", "type", "thumbnail_url", "sort_order", "is_premium", "created_at", "updated_at") VALUES
  (1, 1, 'Từ vựng N5', 'tu-vung-n5', 'vocabulary', NULL, 1, false, '2026-03-16T07:55:09.6537082', '2026-03-16T07:55:09.6537082'),
  (2, 1, 'Ngữ pháp N5', 'ngu-phap-n5', 'grammar', NULL, 2, false, '2026-03-16T07:55:09.6537082', '2026-03-16T07:55:09.6537082'),
  (3, 1, 'Kanji N5', 'kanji-n5', 'kanji', NULL, 3, false, '2026-03-16T07:55:09.6537082', '2026-03-16T07:55:09.6537082'),
  (4, 2, 'Từ vựng N4', 'tu-vung-n4', 'vocabulary', NULL, 4, false, '2026-03-16T07:55:09.6537082', '2026-03-16T07:55:09.6537082'),
  (5, 2, 'Ngữ pháp N4', 'ngu-phap-n4', 'grammar', NULL, 5, false, '2026-03-16T07:55:09.6537082', '2026-03-16T07:55:09.6537082'),
  (6, 3, 'Từ vựng N3', 'tu-vung-n3', 'vocabulary', NULL, 6, true, '2026-03-16T07:55:09.6537082', '2026-03-16T07:55:09.6537082')
ON CONFLICT ("id") DO UPDATE SET
  "level_id" = EXCLUDED."level_id",
  "name" = EXCLUDED."name",
  "slug" = EXCLUDED."slug",
  "type" = EXCLUDED."type",
  "sort_order" = EXCLUDED."sort_order",
  "is_premium" = EXCLUDED."is_premium",
  "updated_at" = EXCLUDED."updated_at";

-- lessons (nguồn Docker seed — bài 18/20 giữ draft)
INSERT INTO "lessons" ("id", "category_id", "title", "slug", "content", "sort_order", "estimated_minutes", "is_premium", "is_published", "created_at", "updated_at", "created_by") VALUES
  (1, 1, 'Chào hỏi cơ bản', 'chao-hoi-co-ban', E'# Chào hỏi cơ bản\n\n## Mục tiêu\n- Chào buổi sáng / chiều / tối\n- Tự giới thiệu tên\n\n## Hội thoại mẫu\n> A: おはようございます。\n> B: おはようございます。\n\n## Lưu ý\nDùng **です／ます** trong ngữ cảnh lịch sự.', 1, 15, false, true, '2026-03-16T07:55:09.6547085', NOW(), 1),
  (2, 1, 'Số đếm 1-10', 'so-dem-1-10', E'# Số đếm cơ bản\n\nいち(1), に(2), さん(3), し/よん(4), ご(5), ろく(6), なな/しち(7), はち(8), きゅう(9), じゅう(10)', 2, 15, false, true, '2026-03-16T07:55:09.6547085', NOW(), 1),
  (3, 2, 'です - Câu khẳng định', 'desu-cau-khang-dinh', E'# Mẫu câu です\n\nDanh từ + です = "là..."\n\n- 私は学生です。(Tôi là học sinh.)\n- これは本です。(Đây là sách.)', 1, 12, false, true, '2026-03-16T07:55:09.6547085', NOW(), 1),
  (4, 3, 'Kanji cơ bản 1', 'kanji-co-ban-1', E'# Nhân, Nhật, Mộc, Thủy, Hỏa\n\n人(người), 日(nhật/ngày), 木(cây), 水(nước), 火(lửa)', 1, 20, false, true, '2026-03-16T07:55:09.6547085', NOW(), 1),
  (5, 4, 'Từ vựng gia đình N4', 'tu-vung-gia-dinh-n4', E'# Gia đình\n\n家族、父、母、兄、姉、弟、妹', 1, 15, false, true, '2026-03-16T07:55:09.6547085', NOW(), 1),
  (7, 1, 'HIRAGANA', 'HIRAGANA', '<p>あ</p>', 6, 10, false, true, '2026-03-28T17:01:54.5156183', NOW(), 29),
  (11, 1, 'UNIT 2.1', 'UNIT 2.1', '<p>パソコン</p>', 4, 10, false, true, '2026-04-07T06:00:01.0105915', NOW(), 29),
  (12, 3, 'Giáo trình tiếng Nhật - Thể số cơ bản', 'thi-thu-tong-trieu-nhat-the-so-co-ban', '<p><strong>見る</strong>（みる）— xem, nhìn</p><p><strong>勉強</strong></p><p><strong>へんきょう</strong></p><p>học, ôn bài</p>', 2, 30, false, false, '2026-04-07T06:00:01.0105915', NOW(), 29),
  (13, 3, 'Giới thiệu về lịch tiếng Nhật', 'gioi-thi-hu-ve-lich-tieng-jp', '<p><strong>日曜日</strong>（にちようび）— ngày thứ 7 trong tuần, thường được sử dụng để chỉ cuối tuần</p>', 3, 15, false, true, '2026-04-07T06:00:01.0105915', NOW(), 29),
  (15, 1, 'Bảng chữ hiragana', 'bang-chu-hiragana', '<p><strong>み</strong></p><p>mi</p><p>Một kana đọc là âm tương ứng của chữ Nhật gốc.</p>', 5, 10, false, true, '2026-04-07T07:40:08.4120960', NOW(), 29),
  (17, 3, 'Giới thiệu về hệ thống số đếm và chữ viết Nhật Bản', 'he-thong-so-đem-va-chu-viet-nhat-ban', '<p><strong>見る</strong>(みる) — xem, nhìn</p>', 3, 15, false, true, '2026-04-07T06:38:01.3035171', NOW(), 29),
  (18, 3, 'Bài học', 'bai-hoc', '<p>--- Slide 1 ---</p>', 5, 30, false, false, '2026-04-07T06:38:01.3035171', NOW(), 29),
  (20, 1, 'Bài học', 'unit-3-1-st-mom7gbsf', '<p>--- Slide 1 ---</p>', 6, 30, false, false, '2026-04-07T07:40:08.4120960', NOW(), 29)
ON CONFLICT ("id") DO UPDATE SET
  "category_id" = EXCLUDED."category_id",
  "title" = EXCLUDED."title",
  "slug" = EXCLUDED."slug",
  "content" = EXCLUDED."content",
  "sort_order" = EXCLUDED."sort_order",
  "estimated_minutes" = EXCLUDED."estimated_minutes",
  "is_premium" = EXCLUDED."is_premium",
  "is_published" = EXCLUDED."is_published",
  "updated_at" = NOW();

-- learning_materials
DELETE FROM "learning_materials" WHERE "id" IN (1, 2);
INSERT INTO "learning_materials" ("id", "lesson_id", "level_id", "title", "type", "file_url", "file_size_kb", "is_premium", "status", "download_count", "created_at", "updated_at") VALUES
  (1, 1, 1, 'PDF Chào hỏi cơ bản', 'pdf', '/materials/chao-hoi-n5.pdf', 120, false, 'approved', 0, '2026-03-16T07:55:09.7717475', NOW()),
  (2, 3, 1, 'PDF Ngữ pháp です', 'pdf', '/materials/desu-grammar.pdf', 85, false, 'approved', 0, '2026-03-16T07:55:09.7717475', NOW());

-- vocabulary_items
DELETE FROM "vocabulary_items" WHERE "id" BETWEEN 1 AND 14;
INSERT INTO "vocabulary_items" ("id", "lesson_id", "word_jp", "reading", "meaning_vi", "meaning_en", "example_sentence", "audio_url", "sort_order", "created_at", "updated_at") VALUES
  (1, 1, 'おはようございます', 'ohayou gozaimasu', 'Chào buổi sáng', 'Good morning', 'おはようございます。今日はいい天気ですね。', NULL, 1, '2026-03-16T07:55:09.6557216', NOW()),
  (2, 1, 'こんにちは', 'konnichiwa', 'Xin chào (ban ngày)', 'Hello / Good afternoon', 'こんにちは。お元気ですか。', NULL, 2, '2026-03-16T07:55:09.6557216', NOW()),
  (3, 1, 'ありがとう', 'arigatou', 'Cảm ơn', 'Thank you', 'ありがとうございます。', NULL, 3, '2026-03-16T07:55:09.6557216', NOW()),
  (4, 2, 'いち', 'ichi', 'Một', 'One', 'いち、に、さん、し、ご。', NULL, 1, '2026-03-16T07:55:09.6557216', NOW()),
  (5, 2, 'に', 'ni', 'Hai', 'Two', NULL, NULL, 2, '2026-03-16T07:55:09.6557216', NOW()),
  (6, 2, 'さん', 'san', 'Ba', 'Three', NULL, NULL, 3, '2026-03-16T07:55:09.6557216', NOW()),
  (7, 1, 'おはよう', 'ohayou', 'Chào buổi sáng (thân)', 'Good morning (casual)', 'おはよう！', NULL, 4, '2026-03-28T17:01:54.5156183', NOW()),
  (8, 2, 'し／よん', 'shi / yon', 'Bốn (4)', NULL, NULL, NULL, 7, '2026-03-28T18:31:57.8277436', NOW()),
  (9, 2, 'ご', 'go', 'Năm (5)', NULL, NULL, NULL, 8, '2026-03-28T18:31:57.8277436', NOW()),
  (10, 2, 'ろく', 'roku', 'Sáu (6)', NULL, NULL, NULL, 9, '2026-03-28T18:31:57.8277436', NOW()),
  (11, 2, 'なな／しち', 'nana / shichi', 'Bảy (7)', NULL, NULL, NULL, 10, '2026-03-28T18:31:57.8277436', NOW()),
  (12, 2, 'はち', 'hachi', 'Tám (8)', NULL, NULL, NULL, 11, '2026-03-28T18:31:57.8277436', NOW()),
  (13, 2, 'きゅう', 'kyū', 'Chín (9)', NULL, NULL, NULL, 12, '2026-03-28T18:31:57.8277436', NOW()),
  (14, 2, 'じゅう', 'jū', 'Mười (10)', NULL, NULL, NULL, 13, '2026-03-28T18:31:57.8277436', NOW());

-- grammar_items
DELETE FROM "grammar_items" WHERE "id" BETWEEN 1 AND 3;
INSERT INTO "grammar_items" ("id", "lesson_id", "pattern", "structure", "meaning_vi", "meaning_en", "example_sentences", "level_id", "sort_order", "created_at", "updated_at") VALUES
  (1, 3, 'N です', 'Danh từ + です', 'Là... (câu khẳng định lịch sự)', 'is/am/are (polite)', '私は学生です。| これは本です。', 1, 1, '2026-03-16T07:55:09.6577206', NOW()),
  (2, 5, 'Vて ください', 'Động từ thể て + ください', 'Hãy làm (yêu cầu lịch sự)', 'Please do...', '待ってください。| 書いてください。', 2, 1, '2026-03-16T07:55:09.6577206', NOW()),
  (3, 1, 'おはようございます', NULL, 'Xin chào (buổi sáng, lịch sự)', 'Good morning (polite)', 'おはようございます、先生。', 1, 2, '2026-03-28T17:01:54.5166256', NOW());

-- kanji_items
DELETE FROM "kanji_items" WHERE "id" BETWEEN 1 AND 6;
INSERT INTO "kanji_items" ("id", "lesson_id", "character", "readings_on", "readings_kun", "meaning_vi", "meaning_en", "stroke_count", "jlpt_level", "sort_order", "created_at", "updated_at") VALUES
  (1, 4, '人', 'ジン, ニン', 'ひと, り', 'người', 'person', 2, 'N5', 1, '2026-03-16T07:55:09.6567205', NOW()),
  (2, 4, '日', 'ニチ, ジツ', 'ひ, か', 'ngày, mặt trời', 'day, sun', 4, 'N5', 2, '2026-03-16T07:55:09.6567205', NOW()),
  (3, 4, '水', 'スイ', 'みず', 'nước', 'water', 4, 'N5', 3, '2026-03-16T07:55:09.6567205', NOW()),
  (4, 4, '火', 'カ', 'ひ, ほ', 'lửa', 'fire', 4, 'N5', 4, '2026-03-16T07:55:09.6567205', NOW()),
  (5, 4, '木', 'ボク, モク', 'き, こ', 'cây, gỗ', 'tree, wood', 4, 'N5', 5, '2026-03-16T07:55:09.6567205', NOW()),
  (6, 1, '朝', 'チョウ', 'あさ', 'buổi sáng', 'morning', 12, 'N5', 1, '2026-03-28T17:01:54.5157406', NOW());

SELECT setval(pg_get_serial_sequence('"lesson_categories"', 'id'), COALESCE((SELECT MAX(id) FROM "lesson_categories"), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('"lessons"', 'id'), COALESCE((SELECT MAX(id) FROM "lessons"), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('"learning_materials"', 'id'), COALESCE((SELECT MAX(id) FROM "learning_materials"), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('"vocabulary_items"', 'id'), COALESCE((SELECT MAX(id) FROM "vocabulary_items"), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('"grammar_items"', 'id'), COALESCE((SELECT MAX(id) FROM "grammar_items"), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('"kanji_items"', 'id'), COALESCE((SELECT MAX(id) FROM "kanji_items"), 0) + 1, false);
