/// Web video calls through Agora's own Web SDK (see web/mindcare_call.js).
///
/// The Flutter plugin's web wrapper could not keep video inside the page, so
/// on web the call screen uses this instead. On every other platform the
/// plugin works and this is only a stub.
library;

export 'web_call_stub.dart' if (dart.library.js_interop) 'web_call_web.dart';

