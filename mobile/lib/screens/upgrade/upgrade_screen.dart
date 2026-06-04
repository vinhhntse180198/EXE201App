import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_flags.dart';
import '../../config/yume_colors.dart';
import '../../config/yume_decorations.dart';
import '../../core/session/app_session.dart';
import '../../models/premium_models.dart';
import '../../services/api_client.dart';
import '../../services/payment_service.dart';
import '../../utils/image_url.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/upgrade/premium_upgrade_widgets.dart';
import '../../widgets/yume/yume_sakura_background.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  final _payment = PaymentService(AppSession.instance.api);

  PremiumConfig? _config;
  PremiumIntent? _intent;
  bool _loading = false;
  bool _creating = false;
  bool _confirming = false;
  String? _error;
  String? _message;

  bool get _isPremium => AppSession.instance.user?.user.isPremium ?? false;

  @override
  void initState() {
    super.initState();
    if (!designMode) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cfg = await _payment.getPremiumConfig();
      PremiumIntent? latest;
      try {
        latest = await _payment.getMyLatestPremiumIntent();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _config = cfg;
          _intent = latest;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtVnd(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final pos = s.length - i;
      buf.write(s[i]);
      if (pos > 1 && pos % 3 == 1) buf.write('.');
    }
    return buf.toString();
  }

  Future<void> _createIntent() async {
    setState(() {
      _creating = true;
      _error = null;
      _message = null;
    });
    try {
      final intent = await _payment.createPremiumIntent();
      if (mounted) {
        setState(() {
          _intent = intent;
          _message = 'Đã tạo mã thanh toán. Chuyển khoản đúng nội dung token bên dưới.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : e.toString());
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _confirmPaid() async {
    final token = _intent?.token;
    if (token == null || token.isEmpty) return;
    setState(() {
      _confirming = true;
      _error = null;
      _message = null;
    });
    try {
      final dto = await _payment.confirmPremiumPayment(token);
      if (mounted) {
        setState(() {
          _intent = dto;
          _message = 'Đã gửi xác nhận. Chờ admin duyệt để kích hoạt Premium.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : e.toString());
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingView(message: 'Đang tải gói Premium...'));
    }
    if (_error != null && _config == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nâng cấp Premium')),
        body: ErrorView(message: _error!, onRetry: _load),
      );
    }

    final cfg = _config;
    final price = _fmtVnd(cfg?.premiumPriceVnd ?? 99000);
    final days = cfg?.premiumDurationDays ?? 30;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.72),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Nâng cấp Premium',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: YumeColors.ink),
        ),
      ),
      body: YumeSakuraBackground(
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: YumeDecorations.dashboardGradient),
          child: RefreshIndicator(
            color: YumeColors.primary,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 12, 20, 32),
              children: [
                PremiumHeroBanner(isPremium: _isPremium),
                const SizedBox(height: 16),
                YumeGlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_outlined, size: 20, color: YumeColors.primary.withValues(alpha: 0.85)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Thanh toán chuyển khoản — admin duyệt sau khi xác nhận.',
                          style: TextStyle(color: YumeColors.text, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  _StatusBanner(text: _message!, ok: true),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _StatusBanner(text: _error!, ok: false),
                ],
                const SizedBox(height: 20),
                const Text(
                  'So sánh gói đăng ký',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: YumeColors.ink),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chọn gói phù hợp — nâng cấp bất cứ lúc nào.',
                  style: TextStyle(color: YumeColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 18),
                PremiumPlanCard(
                  title: 'Premium',
                  ribbon: 'Gói cao cấp',
                  price: '$price đ',
                  priceSub: '/ $days ngày',
                  features: premiumFeatures,
                  isPremiumStyle: true,
                  isCurrent: _isPremium,
                  recommended: !_isPremium,
                  buttonLabel: _isPremium
                      ? 'Gói hiện tại'
                      : (_creating ? 'Đang tạo mã…' : 'Nâng cấp Premium'),
                  onPressed: _isPremium || cfg?.isActive == false ? null : (_creating ? null : _createIntent),
                ),
                const SizedBox(height: 16),
                PremiumPlanCard(
                  title: 'Free',
                  ribbon: 'Gói miễn phí',
                  price: 'Miễn phí',
                  priceSub: '/ dùng lâu dài',
                  features: freeFeatures,
                  isPremiumStyle: false,
                  isCurrent: !_isPremium,
                  buttonLabel: !_isPremium ? 'Gói hiện tại' : 'Chọn gói',
                  onPressed: null,
                ),
                const SizedBox(height: 20),
                const PremiumComparisonTable(),
                if (!_isPremium && _intent != null && cfg != null) ...[
                  const SizedBox(height: 20),
                  _PaymentSection(
                    cfg: cfg,
                    intent: _intent!,
                    fmtVnd: _fmtVnd,
                    confirming: _confirming,
                    onConfirm: _confirmPaid,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.text, required this.ok});

  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ok ? const Color(0xFF86EFAC) : YumeColors.pinkLight),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: ok ? const Color(0xFF166534) : YumeColors.primaryHover,
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({
    required this.cfg,
    required this.intent,
    required this.fmtVnd,
    required this.confirming,
    required this.onConfirm,
  });

  final PremiumConfig cfg;
  final PremiumIntent intent;
  final String Function(int) fmtVnd;
  final bool confirming;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final bank = intent.bankCode.isNotEmpty ? intent.bankCode : cfg.bankCode;
    final acc = intent.accountNo.isNotEmpty ? intent.accountNo : cfg.accountNo;
    final name = intent.accountName.isNotEmpty ? intent.accountName : cfg.accountName;
    final amount = intent.amountVnd > 0 ? intent.amountVnd : cfg.premiumPriceVnd;
    final qrUrl = buildImageUrl(intent.qrImageUrl);

    return YumeGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: premiumGoldLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code_2_rounded, color: premiumGold, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Thanh toán chuyển khoản',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: YumeColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(intent.statusLabel, style: const TextStyle(color: YumeColors.muted, fontSize: 13, height: 1.35)),
          if (qrUrl.isNotEmpty) ...[
            const SizedBox(height: 18),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: YumeColors.border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.network(
                    qrUrl,
                    height: 220,
                    width: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      width: 220,
                      color: YumeColors.pinkLight,
                      child: const Icon(Icons.qr_code_2, size: 80, color: YumeColors.primary),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _InfoRow(label: 'Ngân hàng', value: bank),
          _InfoRow(label: 'Số TK', value: acc),
          _InfoRow(label: 'Chủ TK', value: name),
          _InfoRow(label: 'Số tiền', value: '${fmtVnd(amount)} VND'),
          const SizedBox(height: 10),
          const Text('Nội dung chuyển khoản', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: YumeColors.ink)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: intent.token));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã copy token')));
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: YumeColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      intent.token,
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  const Icon(Icons.copy_rounded, size: 18, color: YumeColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: confirming ? null : onConfirm,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: confirming ? null : YumeDecorations.playHeroGradient,
                  color: confirming ? const Color(0xFFF1F5F9) : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  child: Text(
                    confirming ? 'Đang gửi…' : 'Tôi đã thanh toán',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: confirming ? YumeColors.muted : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: const TextStyle(color: YumeColors.muted, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: YumeColors.ink))),
        ],
      ),
    );
  }
}
