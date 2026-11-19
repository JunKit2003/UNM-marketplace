import 'package:dio/dio.dart';

import '../config.dart';

/// One Dio for the whole app. On the web the browser sends the session cookie
/// automatically because the API is on the same origin.
Dio createDio({String? baseUrl}) => Dio(
  BaseOptions(
    baseUrl: '${baseUrl ?? apiBase()}/api',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Accept': 'application/json'},
  ),
);
