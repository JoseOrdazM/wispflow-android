import 'package:flutter_test/flutter_test.dart';
import 'package:wispflow_android/main.dart';

void main() {
  testWidgets('WispFlow app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WispFlowApp());
    expect(find.text('WispFlow'), findsOneWidget);
  });
}
