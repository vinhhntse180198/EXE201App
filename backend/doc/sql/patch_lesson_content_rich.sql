-- Bổ sung nội dung bài học đầy đủ (thay bản import AI còn 1 dòng).
-- Chạy sau sync_lessons_only_supabase.sql hoặc độc lập trên Supabase.

-- ===== Lesson 13: Lịch tiếng Nhật =====
UPDATE "lessons" SET
  "content" = E'# Giới thiệu về lịch tiếng Nhật\n\n## Mục tiêu\n- Học tên 7 ngày trong tuần\n- Nhận biết kanji 〜曜日\n\n## Ngày trong tuần\n- 日曜日（にちようび）— Chủ nhật\n- 月曜日（げつようび）— Thứ hai\n- 火曜日（かようび）— Thứ ba\n- 水曜日（すいようび）— Thứ tư\n- 木曜日（もくようび）— Thứ năm\n- 金曜日（きんようび）— Thứ sáu\n- 土曜日（どようび）— Thứ bảy\n\n## Mẫu câu\n> 今日は月曜日です。\n> (Hôm nay là thứ hai.)\n\n> 日曜日は休みです。\n> (Chủ nhật nghỉ.)\n\n## Lưu ý\nKanji **曜** (よう) có nghĩa ngày trong tuần. 日 = mặt trời, 月 = mặt trăng, 火 = lửa, 水 = nước, 木 = cây, 金 = kim loại, 土 = đất.',
  "updated_at" = NOW()
WHERE "id" = 13;

DELETE FROM "vocabulary_items" WHERE "lesson_id" = 13;
INSERT INTO "vocabulary_items" ("id", "lesson_id", "word_jp", "reading", "meaning_vi", "meaning_en", "example_sentence", "audio_url", "sort_order", "created_at", "updated_at") VALUES
  (15, 13, '日曜日', 'nichiyoubi', 'Chủ nhật', 'Sunday', '日曜日は休みです。', NULL, 1, NOW(), NOW()),
  (16, 13, '月曜日', 'getsuyoubi', 'Thứ hai', 'Monday', '今日は月曜日です。', NULL, 2, NOW(), NOW()),
  (17, 13, '火曜日', 'kayoubi', 'Thứ ba', 'Tuesday', NULL, NULL, 3, NOW(), NOW()),
  (18, 13, '水曜日', 'suiyoubi', 'Thứ tư', 'Wednesday', NULL, NULL, 4, NOW(), NOW()),
  (19, 13, '木曜日', 'mokuyoubi', 'Thứ năm', 'Thursday', NULL, NULL, 5, NOW(), NOW()),
  (20, 13, '金曜日', 'kinyoubi', 'Thứ sáu', 'Friday', NULL, NULL, 6, NOW(), NOW()),
  (21, 13, '土曜日', 'doyoubi', 'Thứ bảy', 'Saturday', NULL, NULL, 7, NOW(), NOW()),
  (22, 13, '今日', 'kyou', 'Hôm nay', 'Today', '今日は何曜日ですか。', NULL, 8, NOW(), NOW()),
  (23, 13, '明日', 'ashita', 'Ngày mai', 'Tomorrow', '明日は火曜日です。', NULL, 9, NOW(), NOW());

DELETE FROM "kanji_items" WHERE "lesson_id" = 13;
INSERT INTO "kanji_items" ("id", "lesson_id", "character", "readings_on", "readings_kun", "meaning_vi", "meaning_en", "stroke_count", "jlpt_level", "sort_order", "created_at", "updated_at") VALUES
  (7, 13, '曜', 'ヨウ', NULL, 'ngày (trong tuần)', 'day of week', 18, 'N5', 1, NOW(), NOW()),
  (8, 13, '月', 'ゲツ, ガツ', 'つき', 'tháng, mặt trăng', 'month, moon', 4, 'N5', 2, NOW(), NOW());

-- ===== Lesson 5: Gia đình N4 =====
UPDATE "lessons" SET
  "content" = E'# Từ vựng gia đình N4\n\n## Mục tiêu\n- Học từ chỉ thành viên gia đình\n- Dùng trong câu giới thiệu\n\n## Từ vựng chính\n- 家族（かぞく）— gia đình\n- 父（ちち）— bố (nói về bố mình)\n- 母（はは）— mẹ (nói về mẹ mình)\n- 兄（あに）— anh trai\n- 姉（あね）— chị gái\n- 弟（おとうと）— em trai\n- 妹（いもうと）— em gái\n\n## Mẫu câu\n> わたしの家族は四人です。\n> (Gia đình tôi có 4 người.)',
  "updated_at" = NOW()
WHERE "id" = 5;

DELETE FROM "vocabulary_items" WHERE "lesson_id" = 5;
INSERT INTO "vocabulary_items" ("id", "lesson_id", "word_jp", "reading", "meaning_vi", "meaning_en", "example_sentence", "audio_url", "sort_order", "created_at", "updated_at") VALUES
  (24, 5, '家族', 'kazoku', 'Gia đình', 'Family', 'わたしの家族は四人です。', NULL, 1, NOW(), NOW()),
  (25, 5, '父', 'chichi', 'Bố (của mình)', 'My father', NULL, NULL, 2, NOW(), NOW()),
  (26, 5, '母', 'haha', 'Mẹ (của mình)', 'My mother', NULL, NULL, 3, NOW(), NOW()),
  (27, 5, '兄', 'ani', 'Anh trai', 'Older brother', NULL, NULL, 4, NOW(), NOW()),
  (28, 5, '姉', 'ane', 'Chị gái', 'Older sister', NULL, NULL, 5, NOW(), NOW()),
  (29, 5, '弟', 'otouto', 'Em trai', 'Younger brother', NULL, NULL, 6, NOW(), NOW()),
  (30, 5, '妹', 'imouto', 'Em gái', 'Younger sister', NULL, NULL, 7, NOW(), NOW());

-- ===== Lesson 7: Hiragana cơ bản =====
UPDATE "lessons" SET
  "title" = 'Hiragana cơ bản',
  "content" = E'# Hiragana cơ bản\n\n## Mục tiêu\n- Làm quen bảng chữ Hiragana\n- Đọc hàng あ (a)\n\n## Hàng あ\n- あ（a）— âm a\n- い（i）— âm i\n- う（u）— âm u\n- え（e）— âm e\n- お（o）— âm o\n\n## Lưu ý\nHiragana dùng viết từ thuần Nhật. Luyện viết từng nét để nhớ lâu.',
  "updated_at" = NOW()
WHERE "id" = 7;

DELETE FROM "vocabulary_items" WHERE "lesson_id" = 7;
INSERT INTO "vocabulary_items" ("id", "lesson_id", "word_jp", "reading", "meaning_vi", "meaning_en", "example_sentence", "audio_url", "sort_order", "created_at", "updated_at") VALUES
  (31, 7, 'あ', 'a', 'Âm a', 'Vowel a', NULL, NULL, 1, NOW(), NOW()),
  (32, 7, 'い', 'i', 'Âm i', 'Vowel i', NULL, NULL, 2, NOW(), NOW()),
  (33, 7, 'う', 'u', 'Âm u', 'Vowel u', NULL, NULL, 3, NOW(), NOW()),
  (34, 7, 'え', 'e', 'Âm e', 'Vowel e', NULL, NULL, 4, NOW(), NOW()),
  (35, 7, 'お', 'o', 'Âm o', 'Vowel o', NULL, NULL, 5, NOW(), NOW());

-- ===== Lesson 11: UNIT 2.1 =====
UPDATE "lessons" SET
  "title" = 'UNIT 2.1 — Máy tính & công việc',
  "content" = E'# UNIT 2.1 — Máy tính & công việc\n\n## Mục tiêu\n- Từ vựng về thiết bị và học tập\n\n## Từ vựng\n- パソコン — máy tính (PC)\n- 勉強（べんきょう）— học, ôn bài\n- 仕事（しごと）— công việc\n- 学校（がっこう）— trường học\n\n## Mẫu câu\n> パソコンで勉強します。\n> (Tôi học bằng máy tính.)',
  "updated_at" = NOW()
WHERE "id" = 11;

DELETE FROM "vocabulary_items" WHERE "lesson_id" = 11;
INSERT INTO "vocabulary_items" ("id", "lesson_id", "word_jp", "reading", "meaning_vi", "meaning_en", "example_sentence", "audio_url", "sort_order", "created_at", "updated_at") VALUES
  (36, 11, 'パソコン', 'pasokon', 'Máy tính', 'Computer', 'パソコンで勉強します。', NULL, 1, NOW(), NOW()),
  (37, 11, '勉強', 'benkyou', 'Học, ôn bài', 'Study', '毎日勉強します。', NULL, 2, NOW(), NOW()),
  (38, 11, '仕事', 'shigoto', 'Công việc', 'Work, job', NULL, NULL, 3, NOW(), NOW()),
  (39, 11, '学校', 'gakkou', 'Trường học', 'School', NULL, NULL, 4, NOW(), NOW());

-- ===== Lesson 15: Bảng chữ hiragana =====
UPDATE "lessons" SET
  "content" = E'# Bảng chữ Hiragana — hàng ま\n\n## Mục tiêu\n- Học thêm kana hàng ま\n\n## Hàng ま\n- ま（ma）— âm ma\n- み（mi）— âm mi\n- む（mu）— âm mu\n- め（me）— âm me\n- も（mo）— âm mo\n\n## Ví dụ\n- みず（水）— nước\n- もも — đào',
  "updated_at" = NOW()
WHERE "id" = 15;

DELETE FROM "vocabulary_items" WHERE "lesson_id" = 15;
INSERT INTO "vocabulary_items" ("id", "lesson_id", "word_jp", "reading", "meaning_vi", "meaning_en", "example_sentence", "audio_url", "sort_order", "created_at", "updated_at") VALUES
  (40, 15, 'み', 'mi', 'Âm mi', 'Syllable mi', NULL, NULL, 1, NOW(), NOW()),
  (41, 15, 'ま', 'ma', 'Âm ma', 'Syllable ma', NULL, NULL, 2, NOW(), NOW()),
  (42, 15, 'む', 'mu', 'Âm mu', 'Syllable mu', NULL, NULL, 3, NOW(), NOW()),
  (43, 15, 'みず', 'mizu', 'Nước', 'Water', NULL, NULL, 4, NOW(), NOW());

-- ===== Lesson 17: Hệ thống số & chữ viết =====
UPDATE "lessons" SET
  "content" = E'# Hệ thống số đếm và chữ viết Nhật Bản\n\n## Ba hệ chữ viết\n- **Hiragana**（ひらがな）— từ thuần Nhật\n- **Katakana**（カタカナ）— từ ngoại lai\n- **Kanji**（漢字）— chữ Hán\n\n## Số đếm cơ bản\n- 一（いち）— 1\n- 二（に）— 2\n- 三（さん）— 3\n- 十（じゅう）— 10\n\n## Mẫu câu\n> 見る（みる）— xem, nhìn\n> 本を見ます。— Tôi xem sách.',
  "updated_at" = NOW()
WHERE "id" = 17;

DELETE FROM "vocabulary_items" WHERE "lesson_id" = 17;
INSERT INTO "vocabulary_items" ("id", "lesson_id", "word_jp", "reading", "meaning_vi", "meaning_en", "example_sentence", "audio_url", "sort_order", "created_at", "updated_at") VALUES
  (44, 17, '見る', 'miru', 'Xem, nhìn', 'To see, to look', '本を見ます。', NULL, 1, NOW(), NOW()),
  (45, 17, '一', 'ichi', 'Một (1)', 'One', NULL, NULL, 2, NOW(), NOW()),
  (46, 17, '十', 'juu', 'Mười (10)', 'Ten', NULL, NULL, 3, NOW(), NOW());

-- ===== Lesson 14: sửa nội dung AI lỗi → bài về số 千 =====
UPDATE "lessons" SET
  "title" = 'Số đếm lớn — 千 (sen)',
  "content" = E'# Số đếm lớn — 千 (sen)\n\n## Mục tiêu\n- Hiểu cách đọc số lớn trong tiếng Nhật\n\n## Đơn vị cơ bản\n- 十（じゅう）— 10\n- 百（ひゃく）— 100\n- 千（せん）— 1.000\n- 万（まん）— 10.000\n\n## Ví dụ\n- 千円（せんえん）— 1.000 yên\n- 三千（さんぜん）— 3.000\n\n## Lưu ý\n**千** đọc là *sen* (âm Hán) hoặc *chi* trong một số từ ghép.',
  "updated_at" = NOW()
WHERE "id" = 14;

DELETE FROM "vocabulary_items" WHERE "lesson_id" = 14;
INSERT INTO "vocabulary_items" ("id", "lesson_id", "word_jp", "reading", "meaning_vi", "meaning_en", "example_sentence", "audio_url", "sort_order", "created_at", "updated_at") VALUES
  (47, 14, '千', 'sen', 'Nghìn (1.000)', 'Thousand', '千円', NULL, 1, NOW(), NOW()),
  (48, 14, '百', 'hyaku', 'Trăm (100)', 'Hundred', NULL, NULL, 2, NOW(), NOW()),
  (49, 14, '万', 'man', 'Vạn (10.000)', 'Ten thousand', NULL, NULL, 3, NOW(), NOW());

SELECT setval(pg_get_serial_sequence('"vocabulary_items"', 'id'), COALESCE((SELECT MAX(id) FROM "vocabulary_items"), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('"kanji_items"', 'id'), COALESCE((SELECT MAX(id) FROM "kanji_items"), 0) + 1, false);
