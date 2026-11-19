import 'package:dio/dio.dart';

import '../api/api_error.dart';
import '../api/models.dart';

class SignupData {
  const SignupData({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phone,
    required this.password,
  });
  final String firstName, lastName, username, email, phone, password;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
      };
}

class AuthRepository {
  AuthRepository(this._dio);
  final Dio _dio;

  User _user(Response r) => User.fromJson(r.data as Map<String, dynamic>);

  /// The logged-in user, or null when there is no session.
  Future<User?> me() async {
    try {
      return await guard(() async => _user(await _dio.get('/auth/me')));
    } on ApiError catch (e) {
      if (e.isUnauthenticated) return null;
      rethrow;
    }
  }

  Future<User> login(String email, String password) =>
      guard(() async => _user(await _dio.post('/auth/login', data: {'email': email, 'password': password})));

  Future<User> signup(SignupData data) => guard(() async => _user(await _dio.post('/auth/signup', data: data.toJson())));

  Future<User> demo() => guard(() async => _user(await _dio.post('/auth/demo')));

  Future<void> logout() => guard(() => _dio.post('/auth/logout'));

  Future<User> updateProfile({String? firstName, String? lastName, String? phone}) => guard(() async => _user(
        await _dio.patch('/me', data: {
          'firstName': ?firstName,
          'lastName': ?lastName,
          'phone': ?phone,
        }),
      ));

  Future<void> changePassword(String current, String next) =>
      guard(() => _dio.put('/me/password', data: {'currentPassword': current, 'newPassword': next}));

  Future<User> uploadAvatar(PickedPhoto photo) => guard(() async => _user(await _dio.put(
        '/me/photo',
        data: FormData.fromMap({'photo': MultipartFile.fromBytes(photo.bytes, filename: photo.name)}),
      )));
}
