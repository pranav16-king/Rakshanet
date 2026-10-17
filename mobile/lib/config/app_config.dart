/// Centralized App Configuration for Network Endpoints & Disaster Mesh Settings.
class AppConfig {
  /// Base URL for the FastAPI backend.
  /// Overridable at compile time via:
  /// `--dart-define=BACKEND_URL=http://<HOST_IP>:8000`
  /// Defaults to the local Wi-Fi network IP of the development host.
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.130.184.61:8000',
  );

  /// Base URL alias for media and API endpoints
  static String get backendBaseUrl => backendUrl;

  /// Health status endpoint
  static const String healthUrl = '$backendUrl/api/v1/health';

  /// Gateway telemetry and store-and-forward mesh packet upload endpoint
  static const String packetsUrl = '$backendUrl/api/v1/packets';

  /// Missing persons registry endpoint
  static const String missingPersonsUrl = '$backendUrl/api/v1/missing-persons';

  /// User profile sync endpoint
  static const String usersUrl = '$backendUrl/api/v1/users';
}
