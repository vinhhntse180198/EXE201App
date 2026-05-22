import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_flags.dart';
import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../models/premium_models.dart';
import '../../services/api_client.dart';
import '../../services/payment_service.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';

const _freeFeatures = [
  'Bài học cơ bản theo cấp độ',
  'Game giới hạn lượt',
  'Chat công khai',
  'Xem bảng xếp hạng',
];

const _premiumFeatures = [
  'Không giới hạn lượt chơi',
  'Tất cả bài học (kể cả nâng cao)',
  'Không quảng cáo',
  'Vật phẩm game mỗi ngày',
  'Nhóm chat riêng & PvP',
  'Huy hiệu Premium',
];

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
          _message = 'Đã tạo mã thanh toán. Chuyển khoản đúng nội dung token.';
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
    return Scaffold(
      backgroundColor: YumeColors.surface,
      appBar: AppBar(title: const Text('Nâng cấp Premium')),
      body: _loading
          ? const LoadingView(message: 'Đang tải gói Premium...')
          : _error != null && _config == null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'So sánh gói đăng ký',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: YumeColors.ink),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Thanh toán chuyển khoản — admin duyệt sau khi xác nhận.',
                        style: TextStyle(color: YumeColors.muted, fontSize: 13),
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_message!, style: TextStyle(color: Colors.green.shade900, fontSize: 13)),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _planCard(
                            title: 'Free',
                            ribbon: 'Gói Miễn phí',
                            price: 'Miễn phí',
                            priceSub: '/ dùng lâu dài',
                            features: _freeFeatures,
                            isCurrent: !_isPremium,
                            isPremiumCard: false,
                            onUpgrade: null,
                          )),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _planCard(
                              title: 'Premium',
                              ribbon: 'Gói cao cấp',
                              price: '${_fmtVnd(_config?.premiumPriceVnd ?? 10000)} đ',
                              priceSub: '/ ${_config?.premiumDurationDays ?? 30} ngày',
                              features: _premiumFeatures,
                              isCurrent: _isPremium,
                              isPremiumCard: true,
                              onUpgrade: _isPremium || (_config?.isActive == false)
                                  ? null
                                  : (_creating ? null : _createIntent),
                              buttonLabel: _isPremium
                                  ? 'Gói hiện tại'
                                  : (_creating ? 'Đang tạo mã…' : 'Nâng cấp Premium'),
                            ),
                          ),
                        ],
                      ),
                      if (!_isPremium && _intent != null) ...[
                        const SizedBox(height: 24),
                        _paymentSection(_config!, _intent!),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _planCard({
    required String title,
    required String ribbon,
    required String price,
    required String priceSub,
    required List<String> features,
    required bool isCurrent,
    required bool isPremiumCard,
    required VoidCallback? onUpgrade,
    String buttonLabel = 'Chọn gói',
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: YumeColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? YumeColors.primary : YumeColors.border,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: [
          if (isPremiumCard)
            BoxShadow(color: YumeColors.primary.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isPremiumCard ? const Color(0xFFFFF7ED) : YumeColors.pinkLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ribbon,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isPremiumCard ? const Color(0xFFB45309) : YumeColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isPremiumCard ? const Color(0xFFB45309) : YumeColors.ink)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: YumeColors.ink, fontSize: 15, fontWeight: FontWeight.w700),
              children: [
                TextSpan(text: price),
                TextSpan(text: ' $priceSub', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: YumeColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ...features.take(4).map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 14, color: isPremiumCard ? const Color(0xFFD97706) : YumeColors.primary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(f, style: const TextStyle(fontSize: 11, height: 1.25))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onUpgrade,
              style: FilledButton.styleFrom(
                backgroundColor: isPremiumCard ? const Color(0xFFD97706) : YumeColors.muted,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(buttonLabel, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentSection(PremiumConfig cfg, PremiumIntent intent) {
    final bank = intent.bankCode.isNotEmpty ? intent.bankCode : cfg.bankCode;
    final acc = intent.accountNo.isNotEmpty ? intent.accountNo : cfg.accountNo;
    final name = intent.accountName.isNotEmpty ? intent.accountName : cfg.accountName;
    final amount = intent.amountVnd > 0 ? intent.amountVnd : cfg.premiumPriceVnd;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YumeColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YumeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thanh toán chuyển khoản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(intent.statusLabel, style: const TextStyle(color: YumeColors.muted, fontSize: 13)),
          const SizedBox(height: 16),
          if (intent.qrImageUrl.isNotEmpty)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  intent.qrImageUrl,
                  height: 200,
                  width: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    width: 200,
                    color: YumeColors.pinkLight,
                    child: const Icon(Icons.qr_code_2, size: 80, color: YumeColors.primary),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          _infoRow('Ngân hàng', bank),
          _infoRow('Số TK', acc),
          _infoRow('Chủ TK', name),
          _infoRow('Số tiền', '${_fmtVnd(amount)} VND'),
          const SizedBox(height: 8),
          const Text('Nội dung chuyển khoản:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: intent.token));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã copy token')));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(intent.token, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                  ),
                  const Icon(Icons.copy, size: 18, color: YumeColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _confirming ? null : _confirmPaid,
              child: Text(_confirming ? 'Đang gửi…' : 'Tôi đã thanh toán'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: YumeColors.muted, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
