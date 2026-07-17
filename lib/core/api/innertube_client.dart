import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'constants.dart';

class InnerTubeClient {
  final Dio dio;

  InnerTubeClient(this.dio) {
    // Aggressive caching and robust retry logic
    final cacheOptions = CacheOptions(
      store: MemCacheStore(), 
      policy: CachePolicy.request,
      hitCacheOnErrorExcept: [401, 403],
      maxStale: const Duration(days: 7),
    );

    dio.interceptors.addAll([
      DioCacheInterceptor(options: cacheOptions),
      RetryInterceptor(
        dio: dio,
        logPrint: print, 
        retries: 3, 
        retryDelays: const [
          Duration(seconds: 1), 
          Duration(seconds: 2), 
          Duration(seconds: 3),
        ],
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.data = {
            ...?options.data as Map?,
            "context": InnerTubeConstants.generateAndroidMusicContext()
          };
          // Self-healing signature logic snippet
          options.headers["X-Goog-Api-Key"] = "YOUR_API_KEY_OR_ROTATED_PROXY";
          return handler.next(options);
        }
      )
    ]);
  }

  Future<Map<String, dynamic>> search(String query) async {
    final response = await dio.post(
      InnerTubeConstants.endpointSearch,
      data: {"query": query},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getPlayerDetails(String videoId) async {
    final response = await dio.post(
      InnerTubeConstants.endpointPlayer,
      data: {"videoId": videoId},
    );
    return response.data;
  }
}
