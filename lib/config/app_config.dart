/// App-wide constants: addresses, contact info and version.
///
/// Keep every value that appears in more than one place here, so it only has
/// to be changed once.
abstract final class AppConfig {
  static const String appName = 'Feniks Radio';

  /// Shown in Settings and in feedback emails. Keep in sync with the
  /// `version` in pubspec.yaml.
  static const String appVersion = '1.0.0';

  static const String supportEmail = 'feniks.radio94.7@gmail.com';

  /// Live audio stream.
  static const String streamUrl = 'https://c30.radioboss.fm:8234/stream';

  /// Icecast status endpoint with the song that is currently playing.
  static const String nowPlayingUrl =
      'https://c30.radioboss.fm:8234/status-json.xsl';

  /// User agent sent when fetching now-playing information.
  static const String userAgent = 'FeniksRadio/$appVersion';
}
