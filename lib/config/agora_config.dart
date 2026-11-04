/// Agora credentials for video calls.
///
/// 1. Create a free project at https://console.agora.io
/// 2. Choose "Testing mode: APP ID" (no token server needed for a demo)
/// 3. Paste the App ID below (or pass --dart-define=AGORA_APP_ID=xxxx)
///
/// Testing mode is fine for a class demo. For production you must use
/// "Secured mode" and generate short-lived tokens on a backend.
class AgoraConfig {
  const AgoraConfig._();

  static const String appId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: '5e61b1c994634e179959838528ae9d7a', // Testing-mode project
  );

  static bool get isConfigured => appId.isNotEmpty;
}

