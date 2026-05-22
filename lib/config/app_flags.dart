/// **Design mode** = dữ liệu mẫu, không gọi API.
///
/// Mặc định `false` → dữ liệu thật (cần backend + đăng nhập).
/// Chỉ thiết kế UI: `flutter run --dart-define=DESIGN_MODE=true`
const bool designMode = bool.fromEnvironment('DESIGN_MODE', defaultValue: false);
