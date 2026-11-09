import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../config/agora_config.dart';
import '../config/theme.dart';
import '../services/call_service.dart';
import '../services/web_call.dart';

/// Live video call between a patient and their psychologist.
///
/// Both sides open this screen with the same [channelName] (stored on the
/// call request), so Agora puts them in the same room.
///
/// On web the call runs through Agora's Web SDK directly (WebCallSession);
/// the Flutter plugin's web wrapper could not keep video inside the page. On
/// phones and desktop the Agora Flutter plugin is used.
class VideoCallScreen extends StatefulWidget {
  final String callId;
  final String channelName;
  final String otherName;

  /// True if the psychologist is joining (they mark the call complete when
  /// they hang up).
  final bool asDoctor;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.channelName,
    required this.otherName,
    required this.asDoctor,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  // Shared by both paths.
  bool _joined = false;
  bool _remoteHere = false;
  bool _remoteVideoOn = false;
  bool _muted = false;
  bool _cameraOff = false;
  String? _error;

  /// Latest note from Agora, shown next to the name.
  String? _status;

  // Web path.
  WebCallSession? _web;

  // Phone / desktop path.
  RtcEngine? _engine;
  int? _remoteUid;
  bool _cameraFailed = false;
  VideoViewController? _remoteController;
  int? _remoteControllerUid;
  VideoViewController? _localController;

  @override
  void initState() {
    super.initState();
    _start();
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && !_joined && _status == null) {
        setState(() => _status =
            'Still connecting. Check your internet connection.');
      }
    });
  }

  Future<void> _start() async {
    if (!AgoraConfig.isConfigured) {
      setState(() => _error =
          'Video calling is not set up yet. Add your Agora App ID in '
          'lib/config/agora_config.dart (or run with '
          '--dart-define=AGORA_APP_ID=...).');
      return;
    }
    if (kIsWeb) {
      await _startWeb();
    } else {
      await _startNative();
    }
  }

  // ─── Web ─────────────────────────────────────────────────────────

  Future<void> _startWeb() async {
    final session = WebCallSession(onEvent: _onWebEvent);
    setState(() => _web = session);
    await session.join(
      appId: AgoraConfig.appId,
      channel: widget.channelName,
      uid: widget.asDoctor ? 1 : 2,
    );
  }

  void _onWebEvent(String event) {
    debugPrint('Call event: $event');
    if (!mounted) return;
    switch (event) {
      case 'joined':
        setState(() => _joined = true);
        context.read<CallService>().markActive(widget.callId);
      case 'remote-joined':
        setState(() => _remoteHere = true);
      case 'remote-left':
        setState(() {
          _remoteHere = false;
          _remoteVideoOn = false;
        });
      case 'remote-video:on':
        setState(() {
          _remoteHere = true;
          _remoteVideoOn = true;
        });
      case 'remote-video:off':
        setState(() => _remoteVideoOn = false);
      default:
        if (event.startsWith('error:camera')) {
          setState(() {
            _cameraOff = true;
            _status = 'Camera unavailable - others cannot see you. '
                'Check the camera shutter and browser permission.';
          });
        } else if (event.startsWith('error:microphone')) {
          setState(() => _status = 'Microphone unavailable.');
        } else if (event.startsWith('error:')) {
          setState(() => _status = event.substring(6));
        }
    }
  }

  // ─── Phone / desktop ─────────────────────────────────────────────

  Future<void> _startNative() async {
    try {
      final statuses =
          await [Permission.camera, Permission.microphone].request();
      if (statuses.values.any((s) => !s.isGranted)) {
        setState(() =>
            _error = 'Camera and microphone access is needed for the call.');
        return;
      }

      final engine = createAgoraRtcEngine();
      _engine = engine;
      await engine.initialize(const RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) setState(() => _joined = true);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (mounted) {
            setState(() {
              _remoteUid = remoteUid;
              _remoteHere = true;
            });
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (mounted) {
            setState(() {
              _remoteUid = null;
              _remoteHere = false;
              _remoteVideoOn = false;
            });
          }
        },
        onRemoteVideoStateChanged:
            (connection, remoteUid, state, reason, elapsed) {
          if (!mounted) return;
          final on = state == RemoteVideoState.remoteVideoStateDecoding ||
              state == RemoteVideoState.remoteVideoStateStarting;
          if (on != _remoteVideoOn) setState(() => _remoteVideoOn = on);
        },
        onError: (err, msg) {
          debugPrint('Agora error $err: $msg');
          if (mounted && !_joined) {
            setState(() => _status = 'Agora error ${err.name}: $msg');
          }
        },
      ));

      await engine.enableVideo();
      try {
        await engine.startPreview();
      } catch (e) {
        debugPrint('Camera unavailable, continuing without it: $e');
        if (mounted) {
          setState(() {
            _cameraOff = true;
            _status = 'Camera unavailable - joining with audio only.';
          });
        }
        _cameraFailed = true;
      }
      await engine.joinChannel(
        token: '', // testing-mode project: no token needed
        channelId: widget.channelName,
        uid: widget.asDoctor ? 1 : 2,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: !_cameraFailed,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
      if (mounted) {
        context.read<CallService>().markActive(widget.callId);
      }
    } catch (e) {
      debugPrint('Could not start call: $e');
      if (mounted) {
        setState(() => _error = 'Could not start the call: $e');
      }
    }
  }

  // ─── Leaving ─────────────────────────────────────────────────────

  Future<void> _leave({bool finish = false}) async {
    final web = _web;
    _web = null;
    if (web != null) await web.leave();

    final engine = _engine;
    _engine = null;
    if (engine != null) {
      try {
        await engine.leaveChannel();
        await engine.release();
      } catch (e) {
        debugPrint('Error leaving call: $e');
      }
    }
    if (!mounted) return;
    if (finish && widget.asDoctor) {
      context.read<CallService>().complete(widget.callId);
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _web?.leave();
    _web = null;
    final engine = _engine;
    _engine = null;
    if (engine != null) {
      engine.leaveChannel().then((_) => engine.release());
    }
    super.dispose();
  }

  // ─── Views ───────────────────────────────────────────────────────

  /// What to tell the user about the call right now (null when all is well).
  String? get _headline {
    if (!_joined) return 'Connecting...';
    if (!_remoteHere) return 'Waiting for ${widget.otherName} to join...';
    if (!_remoteVideoOn) return "${widget.otherName}'s camera is off";
    return null;
  }

  Widget _remoteView() {
    if (kIsWeb) {
      final web = _web;
      return web == null
          ? const SizedBox.shrink()
          : ClipRect(child: web.remoteView);
    }
    final engine = _engine;
    if (engine == null || _remoteUid == null) {
      return const SizedBox.shrink();
    }
    if (_remoteController == null || _remoteControllerUid != _remoteUid) {
      _remoteControllerUid = _remoteUid;
      _remoteController = VideoViewController.remote(
        rtcEngine: engine,
        canvas: VideoCanvas(uid: _remoteUid),
        connection: RtcConnection(channelId: widget.channelName),
      );
    }
    return AgoraVideoView(
      key: ValueKey('remote_$_remoteUid'),
      controller: _remoteController!,
    );
  }

  Widget _localView() {
    final cameraOffBox = Container(
      color: Colors.black54,
      child: const Center(
        child: Icon(Icons.videocam_off, color: Colors.white54, size: 28),
      ),
    );
    if (kIsWeb) {
      final web = _web;
      if (web == null) return cameraOffBox;
      // Keep the box alive when the camera is off (Agora draws inside it).
      return Stack(
        fit: StackFit.expand,
        children: [
          web.localView,
          if (_cameraOff) cameraOffBox,
        ],
      );
    }
    final engine = _engine;
    if (engine == null || !_joined || _cameraOff) return cameraOffBox;
    _localController ??= VideoViewController(
      rtcEngine: engine,
      canvas: const VideoCanvas(uid: 0),
    );
    return AgoraVideoView(
      key: const ValueKey('local'),
      controller: _localController!,
    );
  }

  void _toggleMic() {
    setState(() => _muted = !_muted);
    if (kIsWeb) {
      _web?.setMicMuted(_muted);
    } else {
      _engine?.muteLocalAudioStream(_muted);
    }
  }

  void _toggleCamera() {
    setState(() {
      _cameraOff = !_cameraOff;
      if (!_cameraOff) _localController = null;
    });
    if (kIsWeb) {
      _web?.setCameraOff(_cameraOff);
    } else {
      _engine?.muteLocalVideoStream(_cameraOff);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: MindCareTheme.background,
        appBar: AppBar(title: const Text('Video call')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off_outlined,
                      size: 48, color: MindCareTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final headline = _headline;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1D19),
      // Nothing is drawn on top of a video (on web a video is a browser
      // element that would hide it): the other person's video has its own
      // area and the controls sit in a separate bar below it.
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${widget.otherName} · v6',
                        style: const TextStyle(color: Colors.white)),
                  ),
                  if (headline != null)
                    Text(headline,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                  if (_status != null)
                    Text(_status!,
                        style: const TextStyle(
                            color: Colors.amber, fontSize: 13)),
                ],
              ),
            ),
            Expanded(child: ClipRect(child: _remoteView())),
            Container(
              color: const Color(0xFF1C1D19),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 112,
                    height: 84,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _localView(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _RoundButton(
                          icon: _muted ? Icons.mic_off : Icons.mic,
                          active: _muted,
                          onTap: _toggleMic,
                        ),
                        _RoundButton(
                          icon: Icons.call_end,
                          color: MindCareTheme.terracotta,
                          size: 64,
                          onTap: () => _leave(finish: true),
                        ),
                        _RoundButton(
                          icon:
                              _cameraOff ? Icons.videocam_off : Icons.videocam,
                          active: _cameraOff,
                          onTap: _toggleCamera,
                        ),
                        if (!kIsWeb)
                          _RoundButton(
                            icon: Icons.cameraswitch,
                            onTap: () => _engine?.switchCamera(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final Color? color;
  final double size;

  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.color,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? (active ? Colors.white : Colors.white24),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: (color == null && active) ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }
}
