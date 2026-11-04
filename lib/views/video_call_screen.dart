import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../config/agora_config.dart';
import '../config/theme.dart';
import '../services/call_service.dart';

/// Live video call between a patient and their psychologist.
///
/// Both sides open this screen with the same [channelName] (stored on the
/// call request), so Agora puts them in the same room.
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
  RtcEngine? _engine;
  int? _remoteUid;
  bool _joined = false;
  bool _muted = false;
  bool _cameraOff = false;

  /// True if this device could not open its camera. It can still watch the
  /// other person; it just does not send video.
  bool _cameraFailed = false;

  /// False while the other person's camera is off or not sending.
  bool _remoteVideoOn = false;
  String? _error;

  /// Latest diagnostic from Agora, shown under "Connecting...".
  String? _status;

  @override
  void initState() {
    super.initState();
    _start();
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && !_joined && _status == null) {
        setState(() => _status =
            'Still connecting. Check your internet and that the Agora App ID is valid.');
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
    try {
      if (!kIsWeb) {
        final statuses =
            await [Permission.camera, Permission.microphone].request();
        if (statuses.values.any((s) => !s.isGranted)) {
          setState(() =>
              _error = 'Camera and microphone access is needed for the call.');
          return;
        }
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
          if (mounted) setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (mounted) {
            setState(() {
              _remoteUid = null;
              _remoteVideoOn = false;
            });
          }
        },
        onRemoteVideoStateChanged:
            (connection, remoteUid, state, reason, elapsed) {
          if (!mounted) return;
          setState(() => _remoteVideoOn =
              state == RemoteVideoState.remoteVideoStateDecoding ||
                  state == RemoteVideoState.remoteVideoStateStarting);
        },
        onError: (err, msg) {
          debugPrint('Agora error $err: $msg');
          if (mounted && !_joined) {
            setState(() => _status = 'Agora error ${err.name}: $msg');
          }
        },
        onConnectionStateChanged: (connection, state, reason) {
          debugPrint('Agora connection $state ($reason)');
          if (mounted && !_joined && state == ConnectionStateType.connectionStateFailed) {
            setState(() => _status = 'Connection failed: ${reason.name}. '
                'Check the App ID is in "Testing mode" (no certificate).');
          }
        },
      ));

      await engine.enableVideo();
      try {
        await engine.startPreview();
      } catch (e) {
        // Camera busy (e.g. another tab is using it): continue audio-only.
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
        uid: 0,
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

  Future<void> _leave({bool finish = false}) async {
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
    final engine = _engine;
    _engine = null;
    if (engine != null) {
      engine.leaveChannel().then((_) => engine.release());
    }
    super.dispose();
  }

  Widget _remoteView() {
    final engine = _engine;
    if (engine != null && _remoteUid != null && !_remoteVideoOn) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              '${widget.otherName} is connected, but their camera is off '
              'or unavailable.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      );
    }
    if (engine == null || _remoteUid == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white54),
            const SizedBox(height: 20),
            Text(
              _joined
                  ? 'Waiting for ${widget.otherName} to join...'
                  : 'Connecting...',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _status!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.amber, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: engine,
        canvas: VideoCanvas(uid: _remoteUid),
        connection: RtcConnection(channelId: widget.channelName),
      ),
    );
  }

  Widget _localView() {
    final engine = _engine;
    if (engine == null || !_joined || _cameraOff) {
      return Container(
        color: Colors.black54,
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white54, size: 32),
        ),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: engine,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
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

    return Scaffold(
      backgroundColor: const Color(0xFF1C1D19),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _remoteView()),
            // Name tag
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(widget.otherName,
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
            // Self preview
            Positioned(
              top: 16,
              right: 16,
              width: 110,
              height: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _localView(),
              ),
            ),
            // Controls
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundButton(
                    icon: _muted ? Icons.mic_off : Icons.mic,
                    active: _muted,
                    onTap: () async {
                      setState(() => _muted = !_muted);
                      await _engine?.muteLocalAudioStream(_muted);
                    },
                  ),
                  const SizedBox(width: 20),
                  _RoundButton(
                    icon: Icons.call_end,
                    color: MindCareTheme.terracotta,
                    size: 64,
                    onTap: () => _leave(finish: true),
                  ),
                  const SizedBox(width: 20),
                  _RoundButton(
                    icon: _cameraOff ? Icons.videocam_off : Icons.videocam,
                    active: _cameraOff,
                    onTap: () async {
                      setState(() => _cameraOff = !_cameraOff);
                      await _engine?.muteLocalVideoStream(_cameraOff);
                    },
                  ),
                  if (!kIsWeb) ...[
                    const SizedBox(width: 20),
                    _RoundButton(
                      icon: Icons.cameraswitch,
                      onTap: () => _engine?.switchCamera(),
                    ),
                  ],
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

