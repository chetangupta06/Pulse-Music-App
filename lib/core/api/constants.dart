import 'dart:convert';

/// Self-healing endpoints and InnerTube templates for the exact Android_MUSIC client context
class InnerTubeConstants {
  static const String baseUrl = 'https://music.youtube.com/youtubei/v1';

  static Map<String, dynamic> generateAndroidMusicContext() {
    return {
      "client": {
        "clientName": "ANDROID_MUSIC",
        "clientVersion": "7.04.51", // Up-to-date version
        "osName": "Android",
        "osVersion": "12",
        "hl": "en",
        "gl": "IN",
        "deviceMake": "Samsung",
        "deviceModel": "SM-G998B",
      }
    };
  }

  static String get endpointPlayer => '$baseUrl/player';
  static String get endpointBrowse => '$baseUrl/browse';
  static String get endpointSearch => '$baseUrl/search';
  static String get endpointNext => '$baseUrl/next';

  /// A basic signature generator stub, in a real env this self-heals
  static String generateSignature() {
    return "mock_sig_for_dev_env";
  }
}
