class InnerTubeConstants {
  const InnerTubeConstants._();

  static const String baseUrl = 'https://music.youtube.com/youtubei/v1';

  static const List<String> apiKeys = <String>[
    'AIzaSyA-PLACEHOLDER-PRIMARY',
    'AIzaSyA-PLACEHOLDER-SECONDARY',
    'AIzaSyA-PLACEHOLDER-TERTIARY',
  ];

  static const Map<String, String> defaultHeaders = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Origin': 'https://music.youtube.com',
    'Referer': 'https://music.youtube.com/',
    'User-Agent':
        'com.google.android.apps.youtube.music/7.26.51 (Linux; U; Android 14) gzip',
    'X-Goog-Api-Format-Version': '2',
    'X-Goog-Visitor-Id': 'CgtGdXR0ZXItRGVtbw==',
  };

  static const Map<String, dynamic> androidMusicContext = <String, dynamic>{
    'context': <String, dynamic>{
      'client': <String, dynamic>{
        'clientName': 'ANDROID_MUSIC',
        'clientVersion': '7.26.51',
        'platform': 'MOBILE',
        'osName': 'Android',
        'osVersion': '14',
        'androidSdkVersion': 34,
        'hl': 'en',
        'gl': 'IN',
      },
      'user': <String, dynamic>{'lockedSafetyMode': false},
      'request': <String, dynamic>{
        'internalExperimentFlags': <Map<String, dynamic>>[],
        'useSsl': true,
      },
    },
  };

  static Map<String, dynamic> buildPayload(Map<String, dynamic> body) {
    return <String, dynamic>{...androidMusicContext, ...body};
  }
}
