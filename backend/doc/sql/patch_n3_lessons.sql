-- Thêm nội dung JLPT N3 (category 6 đã có nhưng chưa có bài publish).
-- Chạy: dotnet run --project backend/tools/SyncLessonsToDb -- "<connection>" backend/doc/sql/patch_n3_lessons.sql

UPDATE "lesson_categories"
SET "is_premium" = false, "updated_at" = NOW()
WHERE "id" = 6;

INSERT INTO "lesson_categories" ("id", "level_id", "name", "slug", "type", "thumbnail_url", "sort_order", "is_premium", "created_at", "updated_at")
VALUES (7, 3, 'Ngữ pháp N3', 'ngu-phap-n3', 'grammar', NULL, 7, false, NOW(), NOW())
ON CONFLICT ("id") DO UPDATE SET
  "level_id" = 3,
  "name" = EXCLUDED."name",
  "slug" = EXCLUDED."slug",
  "type" = EXCLUDED."type",
  "is_premium" = false,
  "updated_at" = NOW();

INSERT INTO "lesson_categories" ("id", "level_id", "name", "slug", "type", "thumbnail_url", "sort_order", "is_premium", "created_at", "updated_at")
VALUES (8, 3, 'Kanji N3', 'kanji-n3', 'kanji', NULL, 8, false, NOW(), NOW())
ON CONFLICT ("id") DO UPDATE SET
  "level_id" = 3,
  "name" = EXCLUDED."name",
  "slug" = EXCLUDED."slug",
  "type" = EXCLUDED."type",
  "is_premium" = false,
  "updated_at" = NOW();

INSERT INTO "lessons" ("id", "category_id", "title", "slug", "content", "sort_order", "estimated_minutes", "is_premium", "is_published", "created_at", "updated_at", "created_by")
VALUES
  (21, 6, 'Từ vựng công việc N3', 'tu-vung-cong-viec-n3',
   E'# Từ vựng công việc N3\n\n## Mục tiêu\n- Từ vựng văn phòng trung cấp\n- Dùng trong email / họp\n\n## Từ chính\n- 会議（かいぎ）— cuộc họp\n- 報告（ほうこく）— báo cáo\n- 資料（しりょう）— tài liệu\n- 担当（たんとう）— phụ trách\n- 締め切り（しめきり）— hạn chót\n\n## Mẫu câu\n> 明日の会議の資料を準備してください。\n> (Hãy chuẩn bị tài liệu cho cuộc họp ngày mai.)',
   1, 20, false, true, NOW(), NOW(), 1),
  (22, 6, 'Giao thông & du lịch N3', 'giao-thong-du-lich-n3',
   E'# Giao thông & du lịch N3\n\n## Mục tiêu\n- Đọc bảng tàu / biển báo\n- Hỏi đường lịch sự\n\n## Từ chính\n- 乗り換え（のりかえ）— chuyển tuyến\n- 遅延（ちえん）— trễ chuyến\n- 観光（かんこう）— tham quan\n- 予約（よやく）— đặt chỗ\n- 案内（あんない）— hướng dẫn\n\n## Mẫu câu\n> 次の駅で乗り換えます。\n> (Tôi chuyển tuyến ở ga tiếp theo.)',
   2, 18, false, true, NOW(), NOW(), 1),
  (23, 7, '〜ながら — Vừa làm vừa…', 'nagara-vua-lam-vua',
   E'# 〜ながら\n\n## Cấu trúc\n**Vます + ながら + V2** = vừa làm V1 vừa làm V2\n\n## Ví dụ\n- 音楽を聞きながら勉強します。\n  (Vừa nghe nhạc vừa học.)\n- 歩きながら電話をかけないでください。\n  (Đừng gọi điện khi đang đi bộ.)\n\n## Lưu ý\nChủ thể của hai vế thường là **cùng một người**.',
   1, 15, false, true, NOW(), NOW(), 1),
  (24, 8, 'Kanji N3 — 議・報・資', 'kanji-n3-co-ban',
   E'# Kanji N3 cơ bản\n\n## Kanji\n- 議（ぎ）— nghị, bàn bạc → 会議\n- 報（ほう）— báo → 報告\n- 資（し）— tư liệu, vốn → 資料\n\n## Mẹo nhớ\n**議** = ngôn + nghĩa (nói chuyện nghĩa)\n**報** = hướng + bộ thủ (báo tin)\n**資** = tư + bối (tài liệu)',
   1, 20, false, true, NOW(), NOW(), 1),
  (25, 6, 'Hội thoại công sở', 'hoi-thoai-cong-so-n3',
   E'# Hội thoại công sở\n\n## Hội thoại mẫu\n> A: お疲れ様です。会議は何時からですか。\n> B: 三時からです。資料はもう送りました。\n> A: ありがとうございます。確認します。\n\n## Mục tiêu\n- Chào đồng nghiệp\n- Hỏi giờ họp / xác nhận tài liệu',
   3, 15, false, true, NOW(), NOW(), 1)
ON CONFLICT ("id") DO UPDATE SET
  "category_id" = EXCLUDED."category_id",
  "title" = EXCLUDED."title",
  "slug" = EXCLUDED."slug",
  "content" = EXCLUDED."content",
  "sort_order" = EXCLUDED."sort_order",
  "estimated_minutes" = EXCLUDED."estimated_minutes",
  "is_premium" = false,
  "is_published" = true,
  "updated_at" = NOW();

DELETE FROM "vocabulary_items" WHERE "lesson_id" IN (21, 22, 23, 25);
INSERT INTO "vocabulary_items" ("lesson_id", "word_jp", "reading", "meaning_vi", "meaning_en", "example_sentence", "audio_url", "sort_order", "created_at", "updated_at") VALUES
  (21, '会議', 'kaigi', 'Cuộc họp', 'Meeting', '会議は三時からです。', NULL, 1, NOW(), NOW()),
  (21, '報告', 'houkoku', 'Báo cáo', 'Report', '週次報告を提出する。', NULL, 2, NOW(), NOW()),
  (21, '資料', 'shiryou', 'Tài liệu', 'Materials', '資料をメールで送る。', NULL, 3, NOW(), NOW()),
  (21, '担当', 'tantou', 'Phụ trách', 'In charge', '私が担当します。', NULL, 4, NOW(), NOW()),
  (21, '締め切り', 'shimekiri', 'Hạn chót', 'Deadline', '締め切りは金曜日です。', NULL, 5, NOW(), NOW()),
  (22, '乗り換え', 'norikae', 'Chuyển tuyến', 'Transfer', '次の駅で乗り換えます。', NULL, 1, NOW(), NOW()),
  (22, '遅延', 'chien', 'Trễ chuyến', 'Delay', '電車が遅延しています。', NULL, 2, NOW(), NOW()),
  (22, '観光', 'kankou', 'Tham quan', 'Sightseeing', '京都を観光する。', NULL, 3, NOW(), NOW()),
  (22, '予約', 'yoyaku', 'Đặt chỗ', 'Reservation', 'ホテルを予約した。', NULL, 4, NOW(), NOW()),
  (22, '案内', 'annai', 'Hướng dẫn', 'Guidance', '駅員が案内してくれた。', NULL, 5, NOW(), NOW()),
  (23, 'ながら', 'nagara', 'Vừa… vừa…', 'While doing', '歩きながら話す。', NULL, 1, NOW(), NOW()),
  (25, 'お疲れ様', 'otsukaresama', 'Cảm ơn vì đã làm việc', 'Good work', 'お疲れ様です。', NULL, 1, NOW(), NOW()),
  (25, '確認', 'kakunin', 'Xác nhận', 'Confirmation', '内容を確認します。', NULL, 2, NOW(), NOW());

DELETE FROM "kanji_items" WHERE "lesson_id" = 24;
INSERT INTO "kanji_items" ("lesson_id", "character", "readings_on", "readings_kun", "meaning_vi", "meaning_en", "stroke_count", "jlpt_level", "sort_order", "created_at", "updated_at") VALUES
  (24, '議', 'ギ', NULL, 'nghị, bàn', 'deliberation', 20, 'N3', 1, NOW(), NOW()),
  (24, '報', 'ホウ', 'むく', 'báo', 'report', 12, 'N3', 2, NOW(), NOW()),
  (24, '資', 'シ', NULL, 'tư liệu, vốn', 'resources', 13, 'N3', 3, NOW(), NOW());

DELETE FROM "grammar_items" WHERE "lesson_id" = 23;
INSERT INTO "grammar_items" ("lesson_id", "pattern", "structure", "meaning_vi", "meaning_en", "example_sentences", "level_id", "sort_order", "created_at", "updated_at") VALUES
  (23, '〜ながら', 'Vます + ながら + V', 'Vừa làm V1 vừa làm V2', 'While doing', '["音楽を聞きながら勉強します"]', 3, 1, NOW(), NOW());

SELECT setval(pg_get_serial_sequence('"lesson_categories"', 'id'), COALESCE((SELECT MAX(id) FROM "lesson_categories"), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('"lessons"', 'id'), COALESCE((SELECT MAX(id) FROM "lessons"), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('"vocabulary_items"', 'id'), COALESCE((SELECT MAX(id) FROM "vocabulary_items"), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('"kanji_items"', 'id'), COALESCE((SELECT MAX(id) FROM "kanji_items"), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('"grammar_items"', 'id'), COALESCE((SELECT MAX(id) FROM "grammar_items"), 0) + 1, false);
