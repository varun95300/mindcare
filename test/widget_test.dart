import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindcare/main.dart';

void main() {
  testWidgets('MindCare app starts on the welcome screen when logged out',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MindCareApp());
    await tester.pumpAndSettle();
    expect(find.text('MindCare'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
