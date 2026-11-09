import 'package:flutter/widgets.dart';

/// Placeholder used where the web bridge does not exist (mobile, desktop,
/// tests). The real one is in web_call_web.dart.
class WebCallSession {
  WebCallSession({required this.onEvent});

  final void Function(String event) onEvent;

  Widget get localView => const SizedBox.shrink();
  Widget get remoteView => const SizedBox.shrink();

  Future<void> join({
    required String appId,
    required String channel,
    required int uid,
  }) async {}

  void setMicMuted(bool muted) {}
  void setCameraOff(bool off) {}
  Future<void> leave() async {}
}

