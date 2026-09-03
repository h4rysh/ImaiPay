import 'package:flutter_test/flutter_test.dart';
import 'package:imaipay/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ImaiPayApp());

    // Verify that the welcome screen appears.
    expect(find.text('Welcome to ImaiPay'), findsOneWidget);
  });
}
