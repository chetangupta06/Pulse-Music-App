import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import '../../constants/innertube_constants.dart';

class InnerTubeClient {
  InnerTubeClient({Dio? dio}) : _dio = dio ?? _buildDio();

  final Dio _dio;
  int _apiKeyIndex = 0;

  static Dio _buildDio() {
    final cacheOptions = CacheOptions(
      store: MemCacheStore(),
      policy: CachePolicy.request,
      maxStale: const Duration(days: 14),
      hitCacheOnErrorCodes: const <int>[400, 403, 429, 500],
      hitCacheOnNetworkFailure: true,
      priority: CachePriority.high,
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: InnerTubeConstants.baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 12),
        headers: InnerTubeConstants.defaultHeaders,
      ),
    );

    dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));
    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        retries: 2,
        retryDelays: const <Duration>[
          Duration(milliseconds: 300),
          Duration(milliseconds: 900),
        ],
      ),
    );

    return dio;
  }

  String get _activeApiKey => InnerTubeConstants
      .apiKeys[_apiKeyIndex % InnerTubeConstants.apiKeys.length];

  Future<Map<String, dynamic>> player(String videoId) {
    return _post(
      '/player',
      InnerTubeConstants.buildPayload(<String, dynamic>{
        'videoId': videoId,
        'contentCheckOk': true,
        'racyCheckOk': true,
      }),
    );
  }

  Future<Map<String, dynamic>> browse(String browseId) {
    return _post(
      '/browse',
      InnerTubeConstants.buildPayload(<String, dynamic>{'browseId': browseId}),
    );
  }

  Future<Map<String, dynamic>> search(String query) {
    return _post(
      '/search',
      InnerTubeConstants.buildPayload(<String, dynamic>{
        'query': query,
        'params': 'EgWKAQIIAWoKEAMQBBAJEAoQBQ%3D%3D',
      }),
    );
  }

  Future<Map<String, dynamic>> next(String videoId) {
    return _post(
      '/next',
      InnerTubeConstants.buildPayload(<String, dynamic>{'videoId': videoId}),
    );
  }

  Future<Map<String, dynamic>> suggestions(String query) {
    return _post(
      '/music/get_search_suggestions',
      InnerTubeConstants.buildPayload(<String, dynamic>{'input': query}),
    );
  }

  Future<Map<String, dynamic>> lyrics(String videoId) async {
    final response = await browse('MPLYt_$videoId');
    return <String, dynamic>{
      'synced': true,
      'source': 'demo-fallback',
      'payload': response,
    };
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        queryParameters: <String, dynamic>{'key': _activeApiKey},
        data: data,
      );
      return response.data ?? <String, dynamic>{'ok': false, 'empty': true};
    } on DioException catch (error) {
      _apiKeyIndex++;
      return <String, dynamic>{
        'ok': false,
        'message': error.message ?? 'Unknown InnerTube error',
        'statusCode': error.response?.statusCode,
        'fallbackToCache': true,
      };
    }
  }
}
