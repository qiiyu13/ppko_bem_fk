class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  static String get serverBaseUrl {
    final api = apiBaseUrl;
    if (api.endsWith('/api/v1')) {
      return api.substring(0, api.length - '/api/v1'.length);
    }
    return api;
  }

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://localhost:3000/ws',
  );
}
