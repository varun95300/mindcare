// MindCare video calls on the web.
//
// Talks to Agora's own Web SDK directly. The Flutter plugin's web wrapper
// could not place video inside the page reliably (full-window video, then
// blank video), so the web build uses this small bridge instead. Dart calls
// into window.mcCall; this reports back through a single callback with short
// text events:
//   joined | remote-joined | remote-left | remote-video:on | remote-video:off
//   published | error:<what> <message>
(function () {
  var client = null;
  var mic = null;
  var cam = null;

  window.mcCall = {
    join: async function (appId, channel, uid, localEl, remoteEl, cb) {
      var emit = function (m) {
        try { cb(m); } catch (e) { /* ignore */ }
      };
      try {
        client = AgoraRTC.createClient({ mode: 'rtc', codec: 'vp8' });

        client.on('user-joined', function () { emit('remote-joined'); });
        client.on('user-left', function () {
          emit('remote-left');
          emit('remote-video:off');
        });
        client.on('user-published', async function (user, type) {
          try {
            await client.subscribe(user, type);
            if (type === 'video') {
              user.videoTrack.play(remoteEl, { fit: 'cover' });
              emit('remote-video:on');
            } else if (type === 'audio') {
              user.audioTrack.play();
            }
          } catch (e) {
            emit('error:subscribe ' + (e && e.message));
          }
        });
        client.on('user-unpublished', function (user, type) {
          if (type === 'video') emit('remote-video:off');
        });

        await client.join(appId, channel, null, uid);
        emit('joined');

        var tracks = [];
        try {
          mic = await AgoraRTC.createMicrophoneAudioTrack();
          tracks.push(mic);
        } catch (e) {
          emit('error:microphone ' + (e && e.message));
        }
        try {
          cam = await AgoraRTC.createCameraVideoTrack();
          cam.play(localEl, { fit: 'cover' });
          tracks.push(cam);
        } catch (e) {
          // No camera (busy, blocked, shutter closed): carry on with audio.
          emit('error:camera ' + (e && e.message));
        }
        if (tracks.length) {
          await client.publish(tracks);
          emit('published');
        }
      } catch (e) {
        emit('error:join ' + ((e && (e.code || '')) + ' ' + (e && e.message)));
      }
    },

    setMicMuted: function (muted) {
      if (mic) mic.setEnabled(!muted);
    },

    setCameraOff: function (off) {
      if (cam) cam.setEnabled(!off);
    },

    leave: async function () {
      try {
        if (mic) { mic.stop(); mic.close(); }
        if (cam) { cam.stop(); cam.close(); }
        if (client) await client.leave();
      } catch (e) { /* ignore */ }
      mic = null;
      cam = null;
      client = null;
    },
  };
})();

