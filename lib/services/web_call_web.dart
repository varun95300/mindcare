import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

@JS('mcCall.join')
external JSPromise<JSAny?> _jsJoin(
  String appId,
  String channel,
  int uid,
  web.HTMLElement localEl,
  web.HTMLElement remoteEl,
  JSFunction callback,
);

@JS('mcCall.setMicMuted')
external void _jsSetMicMuted(bool muted);

@JS('mcCall.setCameraOff')
external void _jsSetCameraOff(bool off);

@JS('mcCall.leave')
external JSPromise<JSAny?> _jsLeave();

int _sessionCounter = 0;

/// One video call on the web. Owns two boxes (yours and theirs) that Agora
/// draws video into, and reports what happens through [onEvent]:
/// joined, remote-joined, remote-left, remote-video:on, remote-video:off,
/// published, and error events that start with `error:`.
class WebCallSession {
  WebCallSession({required this.onEvent}) {
    final id = _sessionCounter++;
    _localType = 'mindcare-call-local-$id';
    _remoteType = 'mindcare-call-remote-$id';
    ui_web.platformViewRegistry.registerViewFactory(
      _localType,
      (int viewId) => _local = _box(),
    );
    ui_web.platformViewRegistry.registerViewFactory(
      _remoteType,
      (int viewId) => _remote = _box(),
    );
  }

  final void Function(String event) onEvent;

  late final String _localType;
  late final String _remoteType;
  web.HTMLElement? _local;
  web.HTMLElement? _remote;

  // A box that stays its own size and clips whatever Agora puts inside it.
  static web.HTMLElement _box() {
    final div = web.document.createElement('div') as web.HTMLDivElement;
    div.style
      ..width = '100%'
      ..height = '100%'
      ..position = 'relative'
      ..overflow = 'hidden'
      ..background = '#1c1d19';
    return div;
  }

  Widget get localView => HtmlElementView(viewType: _localType);
  Widget get remoteView => HtmlElementView(viewType: _remoteType);

  Future<void> join({
    required String appId,
    required String channel,
    required int uid,
  }) async {
    // The boxes are created when their widgets first appear on screen.
    for (var i = 0; i < 100 && (_local == null || _remote == null); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    final local = _local;
    final remote = _remote;
    if (local == null || remote == null) {
      onEvent('error:join the video area did not appear');
      return;
    }
    try {
      await _jsJoin(
        appId,
        channel,
        uid,
        local,
        remote,
        ((String event) => onEvent(event)).toJS,
      ).toDart;
    } catch (e) {
      onEvent('error:join $e');
    }
  }

  void setMicMuted(bool muted) => _jsSetMicMuted(muted);
  void setCameraOff(bool off) => _jsSetCameraOff(off);

  Future<void> leave() async {
    try {
      await _jsLeave().toDart;
    } catch (_) {}
  }
}

