/// Centralized App Configuration for Network Endpoints & Disaster Mesh Settings.
class AppConfig {
  /// Base URL for the FastAPI backend.
  /// Overridable at compile time via:
  /// `--dart-define=BACKEND_URL=http://<HOST_IP>:8000`
  /// Defaults to the local Wi-Fi network IP of the development host.
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://192.168.137.142:8000',
  );

  /// Base URL alias for media and API endpoints
  static String get backendBaseUrl => backendUrl;

  /// Health status endpoint
  static const String healthUrl = '$backendUrl/api/v1/health';

  /// Gateway telemetry and store-and-forward mesh packet upload endpoint
  static const String packetsUrl = '$backendUrl/api/v1/packets';

  /// Gateway telemetry sync endpoint
  static const String telemetrySyncUrl = '$backendUrl/api/v1/telemetry/sync';

  /// Missing persons registry endpoint
  static const String missingPersonsUrl = '$backendUrl/api/v1/missing-persons';

  /// User profile sync endpoint
  static const String usersUrl = '$backendUrl/api/v1/users';

  /// Cloud data fetch by IMEI endpoint
  static String cloudDataUrl(String imei) => '$backendUrl/api/v1/cloud-data/$imei';

  /// Messages endpoint
  static const String messagesUrl = '$backendUrl/api/v1/messages';

  /// Mesh groups endpoints
  static const String groupsUrl = '$backendUrl/api/v1/groups';
  static String groupByIdUrl(String groupId) => '$backendUrl/api/v1/groups/$groupId';
  static String groupJoinUrl(String groupId) => '$backendUrl/api/v1/groups/$groupId/join';

  /// User profile by IMEI endpoint
  static String userByImeiUrl(String imei) => '$backendUrl/api/v1/users/imei/$imei';
}
