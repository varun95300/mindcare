import 'dart:async';
import 'package:mindcare/config/theme.dart';

/// Tests run offline and must be deterministic: never touch Google Fonts.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  MindCareTheme.offlineFonts = true;
  await testMain();
}
