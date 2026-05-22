import '../models/game_inventory.dart';

/// Nhãn tiếng Việt cho cửa hàng xu — khớp mockup Sakura / Play Hub.
abstract final class PlayShopContent {
  static const earnXuHint =
      'Xu kiếm khi chơi: mỗi câu đúng +1 xu (tối đa theo số câu trong phiên), cộng thêm phần thưởng cuối phiên nếu có.';

  static const useHint =
      'Mua vật phẩm hỗ trợ khi chơi game. Dùng trong phiên chơi từ thanh power-up.';

  static String displayName(PowerUpItem item) {
    switch (item.slug.trim().toLowerCase()) {
      case 'heart':
        return 'Thêm tim';
      case 'fifty-fifty':
        return 'Gợi ý 50/50';
      case 'double-points':
        return 'Gấp đôi điểm';
      case 'time-freeze':
        return 'Đóng băng thời gian';
      case 'skip':
        return 'Bỏ qua câu';
      default:
        return item.name;
    }
  }

  static String displayDescription(PowerUpItem item) {
    final fromApi = item.description?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    switch (item.slug.trim().toLowerCase()) {
      case 'heart':
        return 'Thêm 1 tim khi chơi game';
      case 'fifty-fifty':
        return 'Loại bỏ 2 đáp án sai';
      case 'double-points':
        return 'Nhân đôi điểm câu tiếp theo';
      case 'time-freeze':
        return 'Đóng băng đồng hồ 5 giây';
      case 'skip':
        return 'Bỏ qua câu, không mất mạng';
      default:
        return '—';
    }
  }
}
