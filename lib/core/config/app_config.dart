class AppConfig {
  const AppConfig({required this.poemsBaseUrl, required this.poemsApiKey});

  /// Values come from `--dart-define-from-file=dart_defines.json`.
  factory AppConfig.fromEnvironment() => const AppConfig(
    poemsBaseUrl: String.fromEnvironment('POEMS_BASE_URL'),
    poemsApiKey: String.fromEnvironment('POEMS_API_KEY'),
  );

  final String poemsBaseUrl;
  final String poemsApiKey;

  bool get isSyncEnabled => poemsBaseUrl.isNotEmpty;
}
