import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare/main.dart';

void main() {
  testWidgets('MindCare app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const MindCareApp());
    expect(find.text('MindCare'), findsOneWidget);
  });
}
