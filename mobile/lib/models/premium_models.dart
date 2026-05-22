import '../utils/json_field.dart';

class PremiumConfig {
  const PremiumConfig({
    required this.bankCode,
    required this.accountNo,
    required this.accountName,
    required this.premiumPriceVnd,
    required this.premiumDurationDays,
    required this.isActive,
  });

  final String bankCode;
  final String accountNo;
  final String accountName;
  final int premiumPriceVnd;
  final int premiumDurationDays;
  final bool isActive;

  factory PremiumConfig.fromJson(Map<String, dynamic> json) {
    return PremiumConfig(
      bankCode: jsonStr(json, 'bankCode') ?? 'ICB',
      accountNo: jsonStr(json, 'accountNo') ?? '',
      accountName: jsonStr(json, 'accountName') ?? '',
      premiumPriceVnd: jsonInt(json, 'premiumPriceVnd') ?? 10000,
      premiumDurationDays: jsonInt(json, 'premiumDurationDays') ?? 30,
      isActive: jsonBool(json, 'isActive', defaultValue: true),
    );
  }
}

class PremiumIntent {
  const PremiumIntent({
    required this.requestId,
    required this.token,
    required this.amountVnd,
    required this.durationDays,
    required this.bankCode,
    required this.accountNo,
    required this.accountName,
    required this.qrImageUrl,
    required this.status,
  });

  final int requestId;
  final String token;
  final int amountVnd;
  final int durationDays;
  final String bankCode;
  final String accountNo;
  final String accountName;
  final String qrImageUrl;
  final String status;

  factory PremiumIntent.fromJson(Map<String, dynamic> json) {
    return PremiumIntent(
      requestId: jsonInt(json, 'requestId') ?? 0,
      token: jsonStr(json, 'token') ?? '',
      amountVnd: jsonInt(json, 'amountVnd') ?? 0,
      durationDays: jsonInt(json, 'durationDays') ?? 30,
      bankCode: jsonStr(json, 'bankCode') ?? '',
      accountNo: jsonStr(json, 'accountNo') ?? '',
      accountName: jsonStr(json, 'accountName') ?? '',
      qrImageUrl: jsonStr(json, 'qrImageUrl') ?? '',
      status: jsonStr(json, 'status') ?? '',
    );
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Đã duyệt — tài khoản Premium.';
      case 'pending_review':
        return 'Đã gửi — chờ admin duyệt.';
      case 'rejected':
        return 'Bị từ chối — tạo mã mới để thanh toán lại.';
      case 'created':
        return 'Chuyển khoản đúng nội dung token bên dưới.';
      default:
        return status;
    }
  }
}
