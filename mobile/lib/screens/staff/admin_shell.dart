import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../services/admin_service.dart';
import '../../services/moderation_service.dart';
import '../../utils/json_field.dart';
import '../auth/login_screen.dart';
import '../../widgets/common/loading_view.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> with SingleTickerProviderStateMixin {
  final _admin = AdminService(AppSession.instance.api);
  final _moderation = ModerationService(AppSession.instance.api);

  static const _kurenai = Color(0xFF8E031D);
  static const _kurenaiDeep = Color(0xFF5C0214);
  static const _cream = Color(0xFFF9F7F2);

  static const _tabs = <_AdminTab>[
    _AdminTab(id: 'overview', label: 'Tổng quan', icon: Icons.dashboard_outlined),
    _AdminTab(id: 'revenue', label: 'Doanh thu', icon: Icons.payments_outlined),
    _AdminTab(id: 'payments', label: 'Thanh toán', icon: Icons.receipt_long_outlined),
    _AdminTab(id: 'users', label: 'Người dùng', icon: Icons.people_alt_outlined),
    _AdminTab(id: 'games', label: 'Trò chơi', icon: Icons.sports_esports_outlined),
    _AdminTab(id: 'moderation', label: 'Kiểm duyệt', icon: Icons.shield_outlined),
    _AdminTab(id: 'system', label: 'Hệ thống', icon: Icons.settings_outlined),
    _AdminTab(id: 'suggestions', label: 'Đề xuất', icon: Icons.lightbulb_outline),
  ];

  String _tab = 'overview';

  Map<String, dynamic>? _overview;
  Map<String, dynamic>? _premiumConfig;
  List<dynamic> _users = [];
  List<dynamic> _games = [];
  List<dynamic> _lockRequests = [];
  List<dynamic> _premiumRequests = [];
  bool _loading = true;
  String? _loadError;

  final _annTitle = TextEditingController();
  final _annBody = TextEditingController();
  String _annType = 'event';
  bool _annPublishing = false;

  final _premiumPriceCtrl = TextEditingController();
  final _premiumDaysCtrl = TextEditingController();
  bool _savingPremiumConfig = false;

  final _userSearchCtrl = TextEditingController();
  String _userRoleFilter = 'all';
  String _userLockFilter = 'all'; // all/open/locked
  String _userPremiumFilter = 'all'; // all/yes/no

  final _gameSearchCtrl = TextEditingController();
  final _gameSlugCtrl = TextEditingController();
  final _gameNameCtrl = TextEditingController();
  final _gameDescCtrl = TextEditingController();
  final _gameSkillCtrl = TextEditingController();
  final _gameHeartsCtrl = TextEditingController(text: '3');
  final _gameSortCtrl = TextEditingController(text: '0');
  bool _creatingGame = false;

  List<dynamic> _reports = [];
  bool _loadingReports = false;
  int _busyReportId = 0;
  final Map<int, String> _reportNotes = {};

  List<dynamic> _keywords = [];
  bool _loadingKeywords = false;
  final _kwCtrl = TextEditingController();
  int _kwSeverity = 1;

  final _policiesCtrl = TextEditingController(text: 'Điều khoản dịch vụ (bản nháp)…\n\nChính sách bảo mật (bản nháp)…');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _annTitle.dispose();
    _annBody.dispose();
    _premiumPriceCtrl.dispose();
    _premiumDaysCtrl.dispose();
    _userSearchCtrl.dispose();
    _gameSearchCtrl.dispose();
    _gameSlugCtrl.dispose();
    _gameNameCtrl.dispose();
    _gameDescCtrl.dispose();
    _gameSkillCtrl.dispose();
    _gameHeartsCtrl.dispose();
    _gameSortCtrl.dispose();
    _kwCtrl.dispose();
    _policiesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _loadingReports = true);
    try {
      final list = await _moderation.listReports(limit: 120);
      if (!mounted) return;
      setState(() => _reports = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loadingReports = false);
    }
  }

  Future<void> _loadKeywords() async {
    setState(() => _loadingKeywords = true);
    try {
      final list = await _admin.listSensitiveKeywords();
      if (!mounted) return;
      setState(() => _keywords = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loadingKeywords = false);
    }
  }

  Future<void> _createGame() async {
    final slug = _gameSlugCtrl.text.trim();
    final name = _gameNameCtrl.text.trim();
    final desc = _gameDescCtrl.text.trim();
    final skill = _gameSkillCtrl.text.trim();
    final hearts = int.tryParse(_gameHeartsCtrl.text.trim()) ?? 3;
    final sort = int.tryParse(_gameSortCtrl.text.trim()) ?? 0;
    if (slug.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập slug và tên game.')));
      return;
    }
    setState(() => _creatingGame = true);
    try {
      await _admin.createGame(
        slug: slug,
        name: name,
        description: desc.isEmpty ? null : desc,
        skillType: skill.isEmpty ? null : skill,
        maxHearts: hearts,
        sortOrder: sort,
      );
      if (!mounted) return;
      _gameSlugCtrl.clear();
      _gameNameCtrl.clear();
      _gameDescCtrl.clear();
      _gameSkillCtrl.clear();
      _gameHeartsCtrl.text = '3';
      _gameSortCtrl.text = '0';
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm game.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _creatingGame = false);
    }
  }

  Future<void> _confirmDeleteGame(int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa game?'),
        content: Text('Xóa game \"$name\"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _admin.deleteGame(id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa game.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _admin.fetchOverview(),
        _admin.listUsers(),
        _admin.listGames(),
        _admin.listLockRequests(),
        _admin.listPremiumRequests(),
        _admin.getPremiumConfig(),
      ]);
      if (mounted) {
        setState(() {
          _overview = results[0] as Map<String, dynamic>;
          _users = results[1] as List<dynamic>;
          _games = results[2] as List<dynamic>;
          _lockRequests = results[3] as List<dynamic>;
          _premiumRequests = results[4] as List<dynamic>;
          _premiumConfig = results[5] as Map<String, dynamic>;
        });
        _syncPremiumConfigInputs();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = '$e';
        _overview = null;
        _users = [];
        _games = [];
        _lockRequests = [];
        _premiumRequests = [];
        _premiumConfig = null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _syncPremiumConfigInputs() {
    final cfg = _premiumConfig ?? {};
    final price = jsonInt(cfg, 'premiumPriceVnd') ?? jsonInt(cfg, 'PremiumPriceVnd');
    final days = jsonInt(cfg, 'premiumDurationDays') ?? jsonInt(cfg, 'PremiumDurationDays');
    if (_premiumPriceCtrl.text.trim().isEmpty && price != null) {
      _premiumPriceCtrl.text = '$price';
    }
    if (_premiumDaysCtrl.text.trim().isEmpty && days != null) {
      _premiumDaysCtrl.text = '$days';
    }
  }

  Future<void> _savePremiumConfig() async {
    final price = int.tryParse(_premiumPriceCtrl.text.trim());
    final days = int.tryParse(_premiumDaysCtrl.text.trim());
    if (price == null || price <= 0 || days == null || days <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập giá và số ngày hợp lệ.')));
      return;
    }

    setState(() => _savingPremiumConfig = true);
    try {
      final updated = await _admin.updatePremiumConfig(
        premiumPriceVnd: price,
        premiumDurationDays: days,
      );
      if (!mounted) return;
      setState(() => _premiumConfig = updated);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật cấu hình Premium.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _savingPremiumConfig = false);
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

  Future<void> _publishAnnouncement() async {
    final title = _annTitle.text.trim();
    final content = _annBody.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập tiêu đề và nội dung.')));
      return;
    }
    setState(() => _annPublishing = true);
    try {
      await _admin.publishAnnouncement(title: title, content: content, type: _annType);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xuất bản thông báo.')));
        _annTitle.clear();
        _annBody.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _annPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AppSession.instance.user?.user;
    final displayName = user?.username ?? user?.email ?? 'Quản trị viên';
    final tabLabel = _tabs.firstWhere((t) => t.id == _tab, orElse: () => _tabs.first).label;

    return Scaffold(
      backgroundColor: _cream,
      drawer: _adminDrawer(context),
      body: _loading
          ? const LoadingView(message: 'Admin...')
          : _loadError != null
              ? _errorView(_loadError!)
              : SafeArea(
                  child: Column(
                    children: [
                      _topBar(tabLabel: tabLabel, displayName: displayName),
                      Expanded(
                        child: _canvas(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: _tabBody(key: ValueKey<String>(_tab)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _tabBody({Key? key}) {
    switch (_tab) {
      case 'overview':
        return _overviewTab(key: key);
      case 'revenue':
        return _revenueTab(key: key);
      case 'payments':
        return _paymentsTab(key: key);
      case 'users':
        return _usersTab(key: key);
      case 'games':
        return _gamesTab(key: key);
      case 'moderation':
        return _moderationTab(key: key);
      case 'system':
        return _systemTab(key: key);
      case 'suggestions':
        return _suggestionsTab(key: key);
      default:
        return _overviewTab(key: key);
    }
  }

  Widget _adminDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_kurenai, Color(0xFFFB7185)],
                      ),
                      boxShadow: [
                        BoxShadow(color: _kurenai.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: const Center(
                      child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _kurenaiDeep)),
                        SizedBox(height: 2),
                        Text('YumeGo-ji Dashboard', style: TextStyle(fontSize: 12, color: Color(0xFF78716C))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  for (final t in _tabs) _drawerItem(context, t),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFF22C55E).withValues(alpha: 0.10),
                      border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.18)),
                    ),
                    child: const Row(
                      children: [
                        _PulseDot(),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Hệ thống hoạt động bình thường',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF15803D)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Làm mới'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Đăng xuất'),
                          style: FilledButton.styleFrom(backgroundColor: YumeColors.ink),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, _AdminTab t) {
    final on = t.id == _tab;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).pop();
          setState(() => _tab = t.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: on ? const LinearGradient(colors: [_kurenai, Color(0xFFB91C1C)]) : null,
            border: Border.all(color: on ? _kurenai.withValues(alpha: 0.35) : Colors.transparent),
            boxShadow: on
                ? [BoxShadow(color: _kurenai.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 6))]
                : null,
          ),
          child: Row(
            children: [
              Icon(t.icon, size: 20, color: on ? Colors.white : const Color(0xFF57534E)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, color: on ? Colors.white : const Color(0xFF57534E)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar({required String tabLabel, required String displayName}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu),
              tooltip: 'Menu',
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tabLabel,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _kurenaiDeep),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Chào mừng, $displayName',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Làm mới'),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: 'Đăng xuất'),
        ],
      ),
    );
  }

  Widget _canvas({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        color: _cream,
        gradient: RadialGradient(
          center: Alignment(0, -1.2),
          radius: 1.15,
          colors: [Color(0x1A8E031D), _cream],
          stops: [0, 0.9],
        ),
      ),
      child: child,
    );
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text('Không tải được dữ liệu Admin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewTab({Key? key}) {
    final o = _overview ?? {};
    if (o.isEmpty) return _emptyState(key: key);

    int i(String k) => (o[k] is num) ? (o[k] as num).toInt() : 0;
    double d(String k) => (o[k] is num) ? (o[k] as num).toDouble() : 0;
    num n(String k) => (o[k] is num) ? (o[k] as num) : 0;
    List<dynamic> list(String k) => (o[k] is List) ? (o[k] as List) : const [];

    final usersByLevel = list('usersByLevel');
    final usersByPackage = list('usersByPackage');
    final revenueLast8 = list('revenueLast8Months');
    final learning = (o['learningActivity'] is Map<String, dynamic>) ? (o['learningActivity'] as Map<String, dynamic>) : const <String, dynamic>{};

    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _sectionTitle('Tổng quan', desc: 'Bức tranh nhanh về người dùng, Premium và hoạt động học/chơi.'),
        const SizedBox(height: 12),
        _kpiGrid([
          _kpi(icon: Icons.people_alt_outlined, iconBg: const Color(0xFF3B82F6).withValues(alpha: 0.12), iconFg: const Color(0xFF2563EB), label: 'Học viên', value: _fmtInt(i('academyUsers'))),
          _kpi(icon: Icons.lock_open_outlined, iconBg: const Color(0xFF22C55E).withValues(alpha: 0.12), iconFg: const Color(0xFF16A34A), label: 'Đang hoạt động', value: _fmtInt(i('activeUsers'))),
          _kpi(icon: Icons.workspace_premium_outlined, iconBg: const Color(0xFF7C3AED).withValues(alpha: 0.12), iconFg: const Color(0xFF7C3AED), label: 'Premium', value: _fmtInt(i('premiumUsers'))),
          _kpi(icon: Icons.payments_outlined, iconBg: const Color(0xFFEA580C).withValues(alpha: 0.12), iconFg: const Color(0xFFEA580C), label: 'Doanh thu hôm nay', value: _fmtMoney(n('revenueTodayVnd'))),
        ]),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _kpiCardCompact(
                title: 'Tỷ lệ Premium',
                value: '${d('premiumConversionRatePercent').toStringAsFixed(0)}%',
                foot: 'Conversion Free → Premium',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCardCompact(
                title: 'Retention 30 ngày',
                value: '${d('retentionRatePercent').toStringAsFixed(0)}%',
                foot: 'User quay lại trong 30 ngày',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _card(
          title: 'Doanh thu 8 tháng gần nhất',
          subtitle: 'Từ giao dịch Premium đã duyệt',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _lineChart(
                revenueLast8,
                valueKey: 'amountVnd',
                labelKey: 'monthLabel',
                color: _kurenai,
              ),
              const SizedBox(height: 12),
              _revenueBars(revenueLast8),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          title: 'Phân bổ gói',
          subtitle: 'Miễn phí vs Premium',
          child: _sliceList(usersByPackage),
        ),
        const SizedBox(height: 16),
        _card(
          title: 'Người dùng theo level',
          subtitle: 'N5 → N1',
          child: _levelList(usersByLevel),
        ),
        const SizedBox(height: 16),
        _card(
          title: 'Hoạt động 30 ngày',
          subtitle: 'Chỉ số học/chơi gần đây',
          child: _learningRow(learning),
        ),
      ],
    );
  }

  Widget _revenueTab({Key? key}) {
    final o = _overview ?? {};
    final revenueLast8 = (o['revenueLast8Months'] is List) ? (o['revenueLast8Months'] as List) : const [];
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _sectionTitle('Doanh thu', desc: 'Theo dõi doanh thu Premium theo tháng.'),
        const SizedBox(height: 12),
        _card(
          title: '8 tháng gần nhất',
          subtitle: 'Premium đã duyệt',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _lineChart(
                revenueLast8,
                valueKey: 'amountVnd',
                labelKey: 'monthLabel',
                color: _kurenai,
              ),
              const SizedBox(height: 12),
              _revenueBars(revenueLast8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentsTab({Key? key}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _sectionTitle('Thanh toán', desc: 'Cấu hình Premium và duyệt yêu cầu thanh toán.'),
        const SizedBox(height: 12),
        _card(
          title: 'Premium',
          subtitle: 'Cấu hình và danh sách yêu cầu',
          child: _paymentTab(),
        ),
      ],
    );
  }

  Widget _usersTab({Key? key}) {
    final myId = AppSession.instance.user?.user.id ?? 0;
    final q = _userSearchCtrl.text.trim().toLowerCase();
    final filtered = _users.where((row) {
      if (row is! Map<String, dynamic>) return false;
      final username = (jsonStr(row, 'username') ?? '').toLowerCase();
      final email = (jsonStr(row, 'email') ?? '').toLowerCase();
      final role = (jsonStr(row, 'role') ?? '').toLowerCase();
      final isLocked = jsonBool(row, 'isLocked');
      final isPremium = jsonBool(row, 'isPremium');
      if (_userRoleFilter != 'all' && role != _userRoleFilter) return false;
      if (_userLockFilter == 'open' && isLocked) return false;
      if (_userLockFilter == 'locked' && !isLocked) return false;
      if (_userPremiumFilter == 'yes' && !isPremium) return false;
      if (_userPremiumFilter == 'no' && isPremium) return false;
      if (q.isEmpty) return true;
      return username.contains(q) || email.contains(q) || role.contains(q) || (jsonInt(row, 'id')?.toString().contains(q) ?? false);
    }).toList();

    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _sectionTitle('Người dùng', desc: 'Danh sách người dùng trong hệ thống.'),
        const SizedBox(height: 12),
        _card(
          title: 'Users',
          subtitle: 'Tổng: ${filtered.length}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _userSearchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Tìm username, email, id…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 520;
                  final role = DropdownButtonFormField<String>(
                    value: _userRoleFilter,
                    decoration: const InputDecoration(labelText: 'Vai trò', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'user', child: Text('Học viên')),
                      DropdownMenuItem(value: 'moderator', child: Text('Moderator')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) => setState(() => _userRoleFilter = v ?? 'all'),
                  );
                  final lock = DropdownButtonFormField<String>(
                    value: _userLockFilter,
                    decoration: const InputDecoration(labelText: 'Khóa', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'open', child: Text('Đang mở')),
                      DropdownMenuItem(value: 'locked', child: Text('Đã khóa')),
                    ],
                    onChanged: (v) => setState(() => _userLockFilter = v ?? 'all'),
                  );
                  final prem = DropdownButtonFormField<String>(
                    value: _userPremiumFilter,
                    decoration: const InputDecoration(labelText: 'Premium', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'yes', child: Text('Có')),
                      DropdownMenuItem(value: 'no', child: Text('Không')),
                    ],
                    onChanged: (v) => setState(() => _userPremiumFilter = v ?? 'all'),
                  );

                  if (narrow) {
                    return Column(children: [role, const SizedBox(height: 10), lock, const SizedBox(height: 10), prem]);
                  }
                  return Row(children: [Expanded(child: role), const SizedBox(width: 10), Expanded(child: lock), const SizedBox(width: 10), Expanded(child: prem)]);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('Kết quả: ${filtered.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                  OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh, size: 18), label: const Text('Làm mới')),
                ],
              ),
              const SizedBox(height: 10),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Không có người dùng khớp bộ lọc.', style: TextStyle(color: Color(0xFF64748B))),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final u = filtered[i];
              if (u is! Map<String, dynamic>) return const SizedBox.shrink();
              final username = jsonStr(u, 'username') ?? '—';
              final email = jsonStr(u, 'email') ?? '';
              final role = (jsonStr(u, 'role') ?? '').toLowerCase();
              final id = jsonInt(u, 'id') ?? 0;
              final isLocked = jsonBool(u, 'isLocked');
              final isPremium = jsonBool(u, 'isPremium');
              final self = id != 0 && id == myId;

              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: _kurenai.withValues(alpha: 0.10),
                  foregroundColor: _kurenaiDeep,
                  child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'U'),
                ),
                title: Text(username, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text([
                  if (role.isNotEmpty) role,
                  if (email.isNotEmpty) email,
                  if (id != 0) 'ID $id',
                ].join(' · ')),
                trailing: PopupMenuButton<String>(
                  enabled: !self && id != 0,
                  onSelected: (v) async {
                    if (v == 'detail') {
                      await _openUserDetail(id);
                      return;
                    }
                    if (v == 'lock') {
                      await _confirmAndUpdateUser(
                        id,
                        title: isLocked ? 'Mở khóa tài khoản?' : 'Khóa tài khoản?',
                        message: 'Bạn chắc chắn muốn ${isLocked ? 'mở khóa' : 'khóa'} @$username?',
                        update: () => _admin.updateUser(id, isLocked: !isLocked),
                      );
                      return;
                    }
                    if (v == 'premium') {
                      await _confirmAndUpdateUser(
                        id,
                        title: isPremium ? 'Gỡ Premium?' : 'Gán Premium?',
                        message: 'Bạn chắc chắn muốn ${isPremium ? 'gỡ' : 'gán'} Premium cho @$username?',
                        update: () => _admin.updateUser(id, isPremium: !isPremium),
                      );
                      return;
                    }
                    if (v.startsWith('role:')) {
                      final newRole = v.substring('role:'.length);
                      await _confirmAndUpdateUser(
                        id,
                        title: 'Đổi vai trò?',
                        message: 'Đổi vai trò của @$username thành "$newRole"?',
                        update: () => _admin.updateUser(id, role: newRole),
                      );
                      return;
                    }
                    if (v == 'delete') {
                      await _confirmAndUpdateUser(
                        id,
                        title: 'Xóa tài khoản?',
                        message: 'Xóa vĩnh viễn @$username? Không thể hoàn tác.',
                        isDanger: true,
                        update: () async {
                          await _admin.deleteUser(id);
                          return <String, dynamic>{};
                        },
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'detail', child: Text('Chi tiết')),
                    const PopupMenuDivider(),
                    PopupMenuItem(value: 'lock', child: Text(isLocked ? 'Mở khóa' : 'Khóa')),
                    PopupMenuItem(value: 'premium', child: Text(isPremium ? 'Gỡ Premium' : 'Gán Premium')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'role:admin', child: Text('Đổi role: Admin')),
                    const PopupMenuItem(value: 'role:moderator', child: Text('Đổi role: Moderator')),
                    const PopupMenuItem(value: 'role:user', child: Text('Đổi role: User')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'delete', child: Text('Xóa tài khoản')),
                  ],
                ),
              );
            },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openUserDetail(int id) async {
    try {
      final u = await _admin.getUserById(id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) {
          final username = jsonStr(u, 'username') ?? '—';
          final email = jsonStr(u, 'email') ?? '—';
          final role = jsonStr(u, 'role') ?? '—';
          final locked = jsonBool(u, 'isLocked');
          final premium = jsonBool(u, 'isPremium');
          final levelId = jsonInt(u, 'levelId');
          return AlertDialog(
            title: Text('Hồ sơ: @$username'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: $email'),
                  Text('Role: $role'),
                  Text('Locked: ${locked ? 'Có' : 'Không'}'),
                  Text('Premium: ${premium ? 'Có' : 'Không'}'),
                  Text('Level: ${levelId ?? '—'}'),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Đóng')),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _confirmAndUpdateUser(
    int id, {
    required String title,
    required String message,
    required Future<Map<String, dynamic>> Function() update,
    bool isDanger = false,
  }) async {
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: isDanger ? Colors.redAccent : _kurenai),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await update();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật người dùng.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Widget _gamesTab({Key? key}) {
    final q = _gameSearchCtrl.text.trim().toLowerCase();
    final filtered = _games.where((row) {
      if (row is! Map<String, dynamic>) return false;
      final name = (jsonStr(row, 'name') ?? '').toLowerCase();
      final slug = (jsonStr(row, 'slug') ?? '').toLowerCase();
      final skill = (jsonStr(row, 'skillType') ?? '').toLowerCase();
      if (q.isEmpty) return true;
      return name.contains(q) || slug.contains(q) || skill.contains(q);
    }).toList();

    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _sectionTitle('Trò chơi', desc: 'Danh sách game trong hệ thống.'),
        const SizedBox(height: 12),
        _card(
          title: 'Games',
          subtitle: 'Tổng: ${filtered.length}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _gameSearchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Tìm theo tên / slug / kỹ năng…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 520;
                  final slug = TextField(
                    controller: _gameSlugCtrl,
                    decoration: const InputDecoration(labelText: 'Slug', border: OutlineInputBorder()),
                  );
                  final name = TextField(
                    controller: _gameNameCtrl,
                    decoration: const InputDecoration(labelText: 'Tên game', border: OutlineInputBorder()),
                  );
                  final skill = TextField(
                    controller: _gameSkillCtrl,
                    decoration: const InputDecoration(labelText: 'Loại kỹ năng', border: OutlineInputBorder()),
                  );
                  final hearts = TextField(
                    controller: _gameHeartsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tối đa tim', border: OutlineInputBorder()),
                  );
                  final sort = TextField(
                    controller: _gameSortCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Thứ tự', border: OutlineInputBorder()),
                  );
                  final desc = TextField(
                    controller: _gameDescCtrl,
                    decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
                  );

                  final form = narrow
                      ? Column(
                          children: [
                            slug,
                            const SizedBox(height: 10),
                            name,
                            const SizedBox(height: 10),
                            skill,
                            const SizedBox(height: 10),
                            hearts,
                            const SizedBox(height: 10),
                            sort,
                            const SizedBox(height: 10),
                            desc,
                          ],
                        )
                      : Column(
                          children: [
                            Row(children: [Expanded(child: slug), const SizedBox(width: 10), Expanded(child: name)]),
                            const SizedBox(height: 10),
                            Row(children: [Expanded(child: skill), const SizedBox(width: 10), Expanded(child: hearts), const SizedBox(width: 10), Expanded(child: sort)]),
                            const SizedBox(height: 10),
                            desc,
                          ],
                        );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thêm game mới', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      form,
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _creatingGame ? null : _createGame,
                              icon: const Icon(Icons.add),
                              label: Text(_creatingGame ? 'Đang thêm…' : 'Thêm game'),
                              style: FilledButton.styleFrom(backgroundColor: _kurenai),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Làm mới'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              const Text('Danh sách game', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Chưa có game nào (hoặc không khớp bộ lọc).', style: TextStyle(color: Color(0xFF64748B))),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final g = filtered[i];
                    if (g is! Map<String, dynamic>) return const SizedBox.shrink();
                    final id = jsonInt(g, 'id') ?? 0;
                    final name = jsonStr(g, 'name') ?? 'Game';
                    final slug = jsonStr(g, 'slug') ?? '';
                    final skill = jsonStr(g, 'skillType') ?? '';
                    final hearts = jsonInt(g, 'maxHearts');
                    final sortOrder = jsonInt(g, 'sortOrder');
                    final isPvp = jsonBool(g, 'isPvp');
                    final isBoss = jsonBool(g, 'isBossMode');

                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.sports_esports_outlined),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: Text([
                        if (slug.isNotEmpty) 'slug: $slug',
                        if (skill.isNotEmpty) 'skill: $skill',
                        if (hearts != null) '❤ $hearts',
                        if (sortOrder != null) 'sort: $sortOrder',
                        if (isPvp) 'PvP',
                        if (isBoss) 'Boss',
                      ].join(' · ')),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'delete') {
                            await _confirmDeleteGame(id, name);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'delete', child: Text('Xóa game')),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _moderationTab({Key? key}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _sectionTitle('Kiểm duyệt', desc: 'Duyệt đề xuất khóa tài khoản + cấu hình từ khóa nhạy cảm.'),
        const SizedBox(height: 12),
        _card(
          title: 'Đề xuất khóa tài khoản',
          subtitle: 'Chờ xử lý: ${_lockRequests.length}',
          child: _lockRequestsPanel(),
        ),
        const SizedBox(height: 16),
        _card(
          title: 'Blacklist từ khóa nhạy cảm',
          subtitle: 'Toàn hệ thống (mức 1–3)',
          child: _keywordsPanel(),
        ),
      ],
    );
  }

  Widget _systemTab({Key? key}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _sectionTitle('Hệ thống', desc: 'Sức khỏe hệ thống, báo cáo và broadcast/backup.'),
        const SizedBox(height: 12),
        _card(
          title: 'Sức khỏe hệ thống',
          subtitle: 'Chỉ số nhanh từ /api/Admin/overview',
          child: _systemHealthPanel(),
        ),
        const SizedBox(height: 16),
        _card(
          title: 'Báo cáo từ người dùng',
          subtitle: 'Xử lý nhanh: resolved / dismissed',
          child: _reportsPanel(),
        ),
        const SizedBox(height: 16),
        _card(title: 'Chính sách (nháp)', subtitle: 'Lưu local trên thiết bị (tạm thời)', child: _policiesPanel()),
        const SizedBox(height: 16),
        _card(title: 'Thông báo toàn hệ thống', subtitle: 'Xuất bản banner/broadcast', child: _announcementPanel()),
        const SizedBox(height: 16),
        _card(title: 'Backup dữ liệu', subtitle: 'Ghi nhận yêu cầu backup trên server', child: _backupPanel()),
      ],
    );
  }

  Widget _suggestionsTab({Key? key}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _sectionTitle('Đề xuất', desc: 'Gợi ý tối ưu hệ thống (UI giống web).'),
        const SizedBox(height: 12),
        _suggestionsPanel(key: key),
      ],
    );
  }

  Widget _lockRequestsPanel() {
    if (_lockRequests.isEmpty) {
      return const Text('Không có đề xuất chờ.', style: TextStyle(color: Color(0xFF64748B)));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _lockRequests.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = _lockRequests[i];
        if (r is! Map<String, dynamic>) return const SizedBox.shrink();
        final id = jsonInt(r, 'id') ?? 0;
        final status = jsonStr(r, 'status') ?? '';
        final userId = jsonInt(r, 'reportedUserId') ?? jsonInt(r, 'userId');
        final reporter = jsonStr(r, 'reporterUsername') ?? jsonStr(r, 'moderatorUsername') ?? '';
        final note = _reportNotes[id] ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Report #$id${userId == null ? '' : ' · user $userId'}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: _kurenai.withValues(alpha: 0.10),
                    ),
                    child: Text(status.isEmpty ? '—' : status, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _kurenaiDeep)),
                  ),
                ],
              ),
              if (reporter.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Moderator: $reporter', style: const TextStyle(color: Color(0xFF64748B))),
              ],
              const SizedBox(height: 8),
              TextField(
                onChanged: (v) => _reportNotes[id] = v,
                controller: TextEditingController(text: note),
                decoration: const InputDecoration(
                  labelText: 'Ghi chú admin',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        await _confirmAndRun(
                          title: 'Phê duyệt khóa?',
                          message: 'Phê duyệt khóa cho report #$id?',
                          run: () => _admin.approveLockRequest(id),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Phê duyệt'),
                      style: FilledButton.styleFrom(backgroundColor: _kurenai),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _confirmAndRun(
                          title: 'Từ chối?',
                          message: 'Từ chối đề xuất khóa report #$id?',
                          run: () => _admin.rejectLockRequest(id),
                        );
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Từ chối'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _keywordsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _kwCtrl,
                decoration: const InputDecoration(labelText: 'Từ khóa', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<int>(
                value: _kwSeverity,
                decoration: const InputDecoration(labelText: 'Mức', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1')),
                  DropdownMenuItem(value: 2, child: Text('2')),
                  DropdownMenuItem(value: 3, child: Text('3')),
                ],
                onChanged: (v) => setState(() => _kwSeverity = v ?? 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  final kw = _kwCtrl.text.trim();
                  if (kw.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập từ khóa.')));
                    return;
                  }
                  try {
                    await _admin.createSensitiveKeyword(keyword: kw, severity: _kwSeverity);
                    _kwCtrl.clear();
                    await _loadKeywords();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm từ khóa.')));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Thêm'),
                style: FilledButton.styleFrom(backgroundColor: _kurenai),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loadingKeywords ? null : _loadKeywords,
                icon: const Icon(Icons.refresh),
                label: Text(_loadingKeywords ? 'Đang tải...' : 'Tải lại'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_keywords.isEmpty)
          const Text('Chưa có từ khóa.', style: TextStyle(color: Color(0xFF64748B)))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _keywords.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final k = _keywords[i];
              if (k is! Map<String, dynamic>) return const SizedBox.shrink();
              final id = jsonInt(k, 'id') ?? jsonInt(k, 'Id') ?? 0;
              final kw = jsonStr(k, 'keyword') ?? jsonStr(k, 'Keyword') ?? '—';
              final sev = jsonInt(k, 'severity') ?? jsonInt(k, 'Severity') ?? 1;
              final active = (k['isActive'] ?? k['IsActive']) == true;
              return ListTile(
                dense: true,
                title: Text(kw, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('Mức $sev · ${active ? 'Đang bật' : 'Đang tắt'}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'toggle') {
                      await _admin.updateSensitiveKeyword(id, isActive: !active);
                      await _loadKeywords();
                      return;
                    }
                    if (v == 'delete') {
                      await _confirmAndRun(
                        title: 'Xóa từ khóa?',
                        message: 'Xóa \"$kw\"?',
                        run: () => _admin.deleteSensitiveKeyword(id),
                        danger: true,
                      );
                      await _loadKeywords();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'toggle', child: Text(active ? 'Tắt' : 'Bật')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _systemHealthPanel() {
    final o = _overview ?? {};
    int i(String k) => (o[k] is num) ? (o[k] as num).toInt() : 0;
    double d(String k) => (o[k] is num) ? (o[k] as num).toDouble() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kpiGrid([
          _kpi(icon: Icons.people_alt_outlined, iconBg: const Color(0xFF3B82F6).withValues(alpha: 0.12), iconFg: const Color(0xFF2563EB), label: 'Tổng user', value: _fmtInt(i('totalUsers'))),
          _kpi(icon: Icons.message_outlined, iconBg: const Color(0xFFEA580C).withValues(alpha: 0.12), iconFg: const Color(0xFFEA580C), label: 'Tin nhắn 24h', value: _fmtInt(i('messagesLast24Hours'))),
          _kpi(icon: Icons.person_add_alt_1_outlined, iconBg: const Color(0xFF22C55E).withValues(alpha: 0.12), iconFg: const Color(0xFF16A34A), label: 'Mới 7 ngày', value: _fmtInt(i('newUsersLast7Days'))),
          _kpi(icon: Icons.timeline_outlined, iconBg: const Color(0xFF7C3AED).withValues(alpha: 0.12), iconFg: const Color(0xFF7C3AED), label: 'Retention 30d', value: '${d('retentionRatePercent').toStringAsFixed(0)}%'),
        ]),
      ],
    );
  }

  Widget _reportsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Tổng: ${_reports.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
            ),
            OutlinedButton.icon(
              onPressed: _loadingReports ? null : _loadReports,
              icon: const Icon(Icons.refresh),
              label: Text(_loadingReports ? 'Đang tải...' : 'Làm mới'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_reports.isEmpty)
          const Text('Chưa có báo cáo nào.', style: TextStyle(color: Color(0xFF64748B)))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reports.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = _reports[i];
              if (r is! Map<String, dynamic>) return const SizedBox.shrink();
              final id = jsonInt(r, 'id') ?? 0;
              final type = jsonStr(r, 'type') ?? '—';
              final status = jsonStr(r, 'status') ?? '—';
              final desc = (jsonStr(r, 'description') ?? '').trim();
              final short = desc.length > 90 ? '${desc.substring(0, 90)}…' : (desc.isEmpty ? '—' : desc);
              final note = _reportNotes[id] ?? '';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('#$id · $type', style: const TextStyle(fontWeight: FontWeight.w900))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: _kurenai.withValues(alpha: 0.10)),
                          child: Text(status, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _kurenaiDeep)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(short, style: const TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: note),
                      onChanged: (v) => _reportNotes[id] = v,
                      decoration: const InputDecoration(labelText: 'Ghi chú xử lý', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _busyReportId == id
                                ? null
                                : () async {
                                    setState(() => _busyReportId = id);
                                    try {
                                      await _moderation.resolveReport(id, status: 'resolved', resolutionNote: _reportNotes[id]);
                                      await _loadReports();
                                    } finally {
                                      if (mounted) setState(() => _busyReportId = 0);
                                    }
                                  },
                            style: FilledButton.styleFrom(backgroundColor: _kurenai),
                            child: const Text('Đã xử lý'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busyReportId == id
                                ? null
                                : () async {
                                    setState(() => _busyReportId = id);
                                    try {
                                      await _moderation.resolveReport(id, status: 'dismissed', resolutionNote: _reportNotes[id]);
                                      await _loadReports();
                                    } finally {
                                      if (mounted) setState(() => _busyReportId = 0);
                                    }
                                  },
                            child: const Text('Bỏ qua'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _policiesPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _policiesCtrl,
          maxLines: 6,
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Điều khoản & chính sách'),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu nháp trên thiết bị (tạm thời).')));
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Lưu nháp'),
          style: FilledButton.styleFrom(backgroundColor: _kurenai),
        ),
      ],
    );
  }

  Widget _announcementPanel() {
    // tránh nested ListView -> dùng lại form nhưng render trong Column
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(controller: _annTitle, decoration: const InputDecoration(labelText: 'Tiêu đề', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: _annBody, maxLines: 4, decoration: const InputDecoration(labelText: 'Nội dung', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _annType,
          decoration: const InputDecoration(labelText: 'Loại', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'maintenance', child: Text('Bảo trì')),
            DropdownMenuItem(value: 'event', child: Text('Sự kiện')),
            DropdownMenuItem(value: 'promo', child: Text('Khuyến mãi')),
          ],
          onChanged: (v) => setState(() => _annType = v ?? 'maintenance'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _annPublishing ? null : _publishAnnouncement,
          style: FilledButton.styleFrom(backgroundColor: _kurenai),
          child: Text(_annPublishing ? 'Đang gửi…' : 'Gửi thông báo'),
        ),
      ],
    );
  }

  Widget _backupPanel() {
    return FilledButton.icon(
      onPressed: () async {
        try {
          final res = await _admin.requestDataBackup();
          if (!mounted) return;
          final msg = (res['message'] ?? res['Message'] ?? 'Đã ghi nhận yêu cầu backup.').toString();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      },
      icon: const Icon(Icons.backup_outlined),
      label: const Text('Chạy backup'),
      style: FilledButton.styleFrom(backgroundColor: YumeColors.ink),
    );
  }

  Widget _suggestionsPanel({Key? key}) {
    return Wrap(
      runSpacing: 12,
      spacing: 12,
      children: [
        _suggestCard(
          tag: 'Growth',
          title: 'Tăng retention 30 ngày',
          body: 'Tạo chuỗi nhiệm vụ hằng ngày + thưởng Xu theo streak để giữ chân người học.',
          color: const Color(0xFF3B82F6),
        ),
        _suggestCard(
          tag: 'Moderation',
          title: 'Giảm báo cáo chat',
          body: 'Bật blacklist từ khóa mức 2–3 và tăng cảnh cáo tự động cho phòng có nhiều vi phạm.',
          color: const Color(0xFFEAB308),
        ),
        _suggestCard(
          tag: 'Revenue',
          title: 'Tối ưu gói Premium',
          body: 'Thử A/B giá Premium theo tháng (giá thấp cho user mới 7 ngày) để tăng conversion.',
          color: const Color(0xFF8B5CF6),
        ),
        _suggestCard(
          tag: 'Ops',
          title: 'Backup & giám sát',
          body: 'Thiết lập lịch backup hằng ngày + log cảnh báo khi có spike tin nhắn 24h.',
          color: const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _suggestCard({required String tag, required String title, required String body, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.96),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tag.toUpperCase(), style: const TextStyle(letterSpacing: 1.1, fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: Color(0xFF64748B), height: 1.35)),
        ],
      ),
    );
  }

  Future<void> _confirmAndRun({
    required String title,
    required String message,
    required Future<void> Function() run,
    bool danger = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: danger ? Colors.redAccent : _kurenai),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await run();
    await _load();
  }

  Widget _emptyState({Key? key}) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_outlined, size: 44, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            const Text('Chưa có dữ liệu', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Hãy đảm bảo bạn đăng nhập role Admin và backend đang chạy.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Tải lại')),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? desc}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _kurenaiDeep)),
        if (desc != null) ...[
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ],
    );
  }

  Widget _card({required String title, String? subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _kpiGrid(List<Widget> items) {
    return LayoutBuilder(
      builder: (context, c) {
        final twoCols = c.maxWidth >= 520;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final w in items) SizedBox(width: twoCols ? (c.maxWidth - 12) / 2 : c.maxWidth, child: w),
          ],
        );
      },
    );
  }

  Widget _kpi({required IconData icon, required Color iconBg, required Color iconFg, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: iconFg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCardCompact({required String title, required String value, required String foot}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _kurenaiDeep)),
          const SizedBox(height: 4),
          Text(foot, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _revenueBars(List<dynamic> rows) {
    if (rows.isEmpty) return const Text('Chưa có dữ liệu doanh thu.');
    final parsed = <({String label, num amount})>[];
    for (final r in rows) {
      if (r is! Map<String, dynamic>) continue;
      final label = (r['monthLabel'] ?? r['MonthLabel'] ?? r['monthKey'] ?? '')?.toString() ?? '';
      final amt = (r['amountVnd'] ?? r['AmountVnd'] ?? 0);
      final amount = amt is num ? amt : num.tryParse('$amt') ?? 0;
      parsed.add((label: label.isEmpty ? '—' : label, amount: amount));
    }
    if (parsed.isEmpty) return const Text('Chưa có dữ liệu doanh thu.');
    final maxVal = parsed.map((e) => e.amount).fold<num>(0, (a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final e in parsed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text(e.label, style: const TextStyle(fontWeight: FontWeight.w700))),
                    Text(_fmtMoney(e.amount), style: const TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: maxVal <= 0 ? 0 : (e.amount / maxVal).clamp(0, 1).toDouble(),
                    minHeight: 10,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(_kurenai.withValues(alpha: 0.75)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _lineChart(
    List<dynamic> rows, {
    required String valueKey,
    required String labelKey,
    required Color color,
  }) {
    final points = <double>[];
    final labels = <String>[];

    for (final r in rows) {
      if (r is! Map<String, dynamic>) continue;
      final rawLabel = (r[labelKey] ?? r[_altKey(labelKey)] ?? r['monthKey'] ?? r['MonthKey'])?.toString() ?? '';
      final rawVal = (r[valueKey] ?? r[_altKey(valueKey)] ?? 0);
      final v = rawVal is num ? rawVal.toDouble() : double.tryParse('$rawVal') ?? 0.0;
      points.add(v);
      labels.add(rawLabel.isEmpty ? '—' : rawLabel);
    }

    if (points.length < 2) {
      return const Text('Chưa đủ dữ liệu để vẽ biểu đồ.');
    }

    final minV = points.reduce((a, b) => a < b ? a : b);
    final maxV = points.reduce((a, b) => a > b ? a : b);
    final cs = Theme.of(context).colorScheme;
    final bg = cs.surfaceContainerHigh;
    final textStrong = cs.onSurface;
    final textMuted = cs.onSurfaceVariant;

    return Container(
      height: 160,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: bg,
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Biểu đồ',
                  style: TextStyle(color: textStrong, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                'Min ${_fmtMoney(minV)} · Max ${_fmtMoney(maxV)}',
                style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: CustomPaint(
              painter: _LineChartPainter(
                values: points,
                lineColor: color,
                gridColor: Colors.black.withValues(alpha: 0.10),
                dotColor: color,
                fillColor: color.withValues(alpha: 0.16),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                labels.first,
                style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                labels.last,
                style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _altKey(String key) {
    if (key.isEmpty) return key;
    return '${key[0].toUpperCase()}${key.substring(1)}';
  }

  Widget _sliceList(List<dynamic> rows) {
    if (rows.isEmpty) return const Text('Chưa có dữ liệu.');
    return Column(
      children: [
        for (final r in rows)
          if (r is Map<String, dynamic>)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _parseHex((r['color'] ?? r['Color'])?.toString()),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text((r['name'] ?? r['Name'] ?? '—').toString(), style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text(_fmtInt((r['count'] ?? r['Count'] ?? 0) is num ? (r['count'] ?? r['Count'] as num).toInt() : int.tryParse('${r['count'] ?? r['Count']}') ?? 0)),
                ],
              ),
            ),
      ],
    );
  }

  Widget _levelList(List<dynamic> rows) {
    if (rows.isEmpty) return const Text('Chưa có dữ liệu.');
    return Column(
      children: [
        for (final r in rows)
          if (r is Map<String, dynamic>)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: _kurenai.withValues(alpha: 0.08),
                      border: Border.all(color: _kurenai.withValues(alpha: 0.14)),
                    ),
                    child: Text((r['label'] ?? r['Label'] ?? '—').toString(), style: const TextStyle(fontWeight: FontWeight.w900, color: _kurenaiDeep)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Level ${(r['levelId'] ?? r['LevelId'] ?? '—')}', style: const TextStyle(color: Color(0xFF64748B)))),
                  Text(_fmtInt((r['count'] ?? r['Count'] ?? 0) is num ? (r['count'] ?? r['Count'] as num).toInt() : int.tryParse('${r['count'] ?? r['Count']}') ?? 0), style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
      ],
    );
  }

  Widget _learningRow(Map<String, dynamic> learning) {
    int ii(String k) => (learning[k] is num) ? (learning[k] as num).toInt() : 0;
    return Wrap(
      runSpacing: 10,
      spacing: 10,
      children: [
        _pill('Game sessions started', _fmtInt(ii('gameSessionsStartedLast30Days'))),
        _pill('Game sessions ended', _fmtInt(ii('gameSessionsEndedLast30Days'))),
        _pill('Completed lessons', _fmtInt(ii('completedLessonsLast30Days'))),
      ],
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  String _fmtInt(int v) => v.toString();

  String _fmtMoney(num v) {
    final s = v.toStringAsFixed(0);
    final chars = s.split('');
    final out = <String>[];
    for (var i = 0; i < chars.length; i++) {
      final posFromEnd = chars.length - i;
      out.add(chars[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) out.add('.');
    }
    return '${out.join()} ₫';
  }

  Color _parseHex(String? hex) {
    final h = (hex ?? '').trim();
    if (h.isEmpty) return const Color(0xFF94A3B8);
    final v = h.startsWith('#') ? h.substring(1) : h;
    if (v.length == 6) return Color(int.parse('FF$v', radix: 16));
    if (v.length == 8) return Color(int.parse(v, radix: 16));
    return const Color(0xFF94A3B8);
  }

  // legacy _lockTab removed (replaced by _lockRequestsPanel)

  Widget _paymentTab() {
    final cfg = _premiumConfig ?? {};
    final price = jsonInt(cfg, 'premiumPriceVnd') ?? jsonInt(cfg, 'PremiumPriceVnd');
    final days = jsonInt(cfg, 'premiumDurationDays') ?? jsonInt(cfg, 'PremiumDurationDays');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kurenai.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kurenai.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium_outlined, color: _kurenaiDeep),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cấu hình Premium', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(
                      'Giá: ${price ?? '—'} VND · Thời hạn: ${days ?? '—'} ngày',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chỉnh cấu hình', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _premiumPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Giá (VND)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _premiumDaysCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số ngày',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _savingPremiumConfig ? null : _savePremiumConfig,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_savingPremiumConfig ? 'Đang lưu...' : 'Lưu cấu hình'),
                      style: FilledButton.styleFrom(backgroundColor: _kurenai),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _savingPremiumConfig
                          ? null
                          : () {
                              setState(() {
                                _premiumPriceCtrl.text = price == null ? '' : '$price';
                                _premiumDaysCtrl.text = days == null ? '' : '$days';
                              });
                            },
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Hoàn tác'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Yêu cầu thanh toán (${_premiumRequests.length})',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Làm mới'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_premiumRequests.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Chưa có yêu cầu nào.', style: TextStyle(color: Color(0xFF64748B))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _premiumRequests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = _premiumRequests[i];
              if (r is! Map<String, dynamic>) return const SizedBox.shrink();
              final id = jsonInt(r, 'id') ?? 0;
              final username = jsonStr(r, 'username') ?? jsonStr(r, 'userName');
              final status = jsonStr(r, 'status') ?? '';
              final amount = jsonInt(r, 'amountVnd') ?? jsonInt(r, 'AmountVnd');

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '#$id${username == null || username.isEmpty ? '' : ' · $username'}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: _kurenai.withValues(alpha: 0.10),
                          ),
                          child: Text(status.isEmpty ? '—' : status, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _kurenaiDeep)),
                        ),
                      ],
                    ),
                    if (amount != null) ...[
                      const SizedBox(height: 6),
                      Text('Số tiền: $amount VND', style: const TextStyle(color: Color(0xFF64748B))),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              await _admin.approvePremiumRequest(id);
                              await _load();
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Duyệt'),
                            style: FilledButton.styleFrom(backgroundColor: _kurenai),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _admin.rejectPremiumRequest(id, reason: 'Từ chối trên mobile');
                              await _load();
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Từ chối'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // legacy _announcementTab removed (replaced by _announcementPanel)
}

class _AdminTab {
  const _AdminTab({required this.id, required this.label, required this.icon});

  final String id;
  final String label;
  final IconData icon;
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF22C55E).withValues(alpha: 0.7 + 0.3 * t),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withValues(alpha: 0.20 + 0.18 * t),
                blurRadius: 10 + 6 * t,
                spreadRadius: 0.5 + 1.5 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
    required this.dotColor,
    required this.fillColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color gridColor;
  final Color dotColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) return;

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.000001 ? 1.0 : (maxV - minV);

    final pad = 6.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final y = pad + h * (i / 4);
      canvas.drawLine(Offset(pad, y), Offset(pad + w, y), grid);
    }

    final line = Paint()
      ..color = lineColor.withValues(alpha: 0.95)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (var idx = 0; idx < values.length; idx++) {
      final t = idx / (values.length - 1);
      final x = pad + w * t;
      final norm = (values[idx] - minV) / range;
      final y = pad + h * (1 - norm);

      if (idx == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, pad + h);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(pad + w, pad + h);
    fillPath.close();
    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, line);

    final dot = Paint()..color = dotColor.withValues(alpha: 0.95);
    for (var idx = 0; idx < values.length; idx++) {
      final t = idx / (values.length - 1);
      final x = pad + w * t;
      final norm = (values[idx] - minV) / range;
      final y = pad + h * (1 - norm);
      canvas.drawCircle(Offset(x, y), 3.2, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.values.length != values.length ||
        oldDelegate.values != values;
  }
}
