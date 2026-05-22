import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/session/app_session.dart';
import '../../services/moderation_service.dart';
import '../../utils/json_field.dart';
import '../auth/login_screen.dart';
import '../../widgets/common/loading_view.dart';

class ModeratorShell extends StatefulWidget {
  const ModeratorShell({super.key});

  @override
  State<ModeratorShell> createState() => _ModeratorShellState();
}

class _ModeratorShellState extends State<ModeratorShell> with SingleTickerProviderStateMixin {
  final _mod = ModerationService(AppSession.instance.api);
  late final TabController _tabs = TabController(length: 5, vsync: this);

  Map<String, dynamic>? _overview;
  List<dynamic> _reports = [];
  List<dynamic> _learners = [];
  List<dynamic> _lessons = [];
  bool _loading = true;
  bool _uploading = false;
  String? _uploadResult;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _mod.fetchStaffOverview(),
        _mod.listReports(),
        _mod.listLearners(),
        _mod.listStaffLessons(),
      ]);
      if (mounted) {
        setState(() {
          _overview = results[0] as Map<String, dynamic>;
          _reports = results[1] as List<dynamic>;
          _learners = results[2] as List<dynamic>;
          _lessons = results[3] as List<dynamic>;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await AppSession.instance.auth.logout();
    AppSession.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _pickAndUpload({required bool extractOnly}) async {
    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'pptx'],
      withData: true,
    );
    if (pick == null || pick.files.isEmpty) return;
    final f = pick.files.first;
    final bytes = f.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không đọc được file.')));
      }
      return;
    }
    setState(() {
      _uploading = true;
      _uploadResult = null;
    });
    try {
      final name = f.name;
      final result = extractOnly
          ? await _mod.extractLessonText(bytes: bytes, filename: name)
          : await _mod.uploadLessonDocument(bytes: bytes, filename: name);
      if (mounted) {
        if (extractOnly) {
          final preview = jsonStr(result, 'preview') ?? jsonStr(result, 'Preview') ?? '';
          setState(() => _uploadResult = 'Trích xong ${preview.length} ký tự preview:\n$preview');
        } else {
          setState(() => _uploadResult = 'URL: ${jsonStr(result, 'url') ?? jsonStr(result, 'Url')}');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _uploadResult = 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderator'),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Báo cáo'),
            Tab(text: 'Học viên'),
            Tab(text: 'Bài học'),
            Tab(text: 'Upload'),
          ],
        ),
      ),
      body: _loading
          ? const LoadingView(message: 'Moderator...')
          : TabBarView(
              controller: _tabs,
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: (_overview ?? {}).entries
                      .map((e) => ListTile(title: Text(e.key), trailing: Text('${e.value}')))
                      .toList(),
                ),
                ListView.builder(
                  itemCount: _reports.length,
                  itemBuilder: (_, i) {
                    final r = _reports[i];
                    if (r is! Map<String, dynamic>) return const SizedBox.shrink();
                    final id = jsonInt(r, 'id') ?? 0;
                    return ListTile(
                      title: Text('Report #$id'),
                      subtitle: Text(jsonStr(r, 'reason') ?? jsonStr(r, 'status') ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.done_all, color: Colors.green),
                        onPressed: () async {
                          await _mod.resolveReport(id);
                          await _load();
                        },
                      ),
                    );
                  },
                ),
                ListView.builder(
                  itemCount: _learners.length,
                  itemBuilder: (_, i) {
                    final u = _learners[i];
                    if (u is! Map<String, dynamic>) return const SizedBox.shrink();
                    return ListTile(
                      title: Text(jsonStr(u, 'username') ?? '—'),
                      subtitle: Text(jsonStr(u, 'levelCode') ?? ''),
                    );
                  },
                ),
                ListView.builder(
                  itemCount: _lessons.length,
                  itemBuilder: (_, i) {
                    final l = _lessons[i];
                    if (l is! Map<String, dynamic>) return const SizedBox.shrink();
                    return ListTile(
                      title: Text(jsonStr(l, 'title') ?? '—'),
                      subtitle: Text(jsonStr(l, 'slug') ?? ''),
                    );
                  },
                ),
                _uploadTab(),
              ],
            ),
    );
  }

  Widget _uploadTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Upload bài học (PDF / DOCX / PPTX)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Giống web Moderator — upload tài liệu hoặc trích văn bản.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _uploading ? null : () => _pickAndUpload(extractOnly: false),
          icon: const Icon(Icons.upload_file),
          label: Text(_uploading ? 'Đang upload...' : 'Upload tài liệu'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _uploading ? null : () => _pickAndUpload(extractOnly: true),
          icon: const Icon(Icons.text_snippet_outlined),
          label: const Text('Trích văn bản (extract-text)'),
        ),
        if (_uploadResult != null) ...[
          const SizedBox(height: 16),
          SelectableText(_uploadResult!, style: const TextStyle(fontSize: 12)),
        ],
      ],
    );
  }
}
