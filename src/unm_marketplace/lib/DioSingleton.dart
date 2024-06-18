
// ignore_for_file: file_names

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DioSingleton {
  static final Dio _dio = Dio();

  static Dio getInstance() {
    if (!kIsWeb) {
      var cookieJar = CookieJar();
      _dio.interceptors.add(CookieManager(cookieJar));
    } else {
      // Additional configuration for web
      _dio.options.headers['Accept'] = 'application/json';
      _dio.options.headers['Content-Type'] = 'application/json';
      // Ensure credentials are sent with CORS requests
      _dio.options.extra['withCredentials'] = true;
    }
    return _dio;
  }
}