import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DioClient {
  late final Dio jamendoDio;
  late final Dio lrclibDio;

  DioClient() {
    jamendoDio = Dio(BaseOptions(
      baseUrl: 'https://api.jamendo.com/v3.0',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ));

    lrclibDio = Dio(BaseOptions(
      baseUrl: 'https://lrclib.net/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));

    // Logging interceptor (debug only)
    assert(() {
      jamendoDio.interceptors.add(LogInterceptor(responseBody: false));
      return true;
    }());
  }
}

final dioClientProvider = Provider<DioClient>((ref) => DioClient());
