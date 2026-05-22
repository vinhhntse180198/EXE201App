import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_test/app.dart';

void main() {
  testWidgets('Splash hiển thị Yume', (WidgetTester tester) async {
    await tester.pumpWidget(const YumeApp());
    expect(find.text('Yume'), findsOneWidget);
  });
}
