import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus status = AuthStatus.unknown;
  UserModel? user;
  String? errorMessage;
  bool isLoading = false;

  final _dio = DioClient.instance;

  // Kiểm tra token khi mở app
  Future<void> checkAuth() async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      status = AuthStatus.authenticated;
    } else {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      await TokenStorage.saveTokens(
        accessToken:  res.data['accessToken'],
        refreshToken: res.data['refreshToken'],
      );
      user   = UserModel.fromJson(res.data);
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      errorMessage = e.response?.data['message'] ?? 'Đăng nhập thất bại';
      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String displayName) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _dio.post('/api/auth/register', data: {
        'email':       email,
        'password':    password,
        'displayName': displayName,
      });
      await TokenStorage.saveTokens(
        accessToken:  res.data['accessToken'],
        refreshToken: res.data['refreshToken'],
      );
      user   = UserModel.fromJson(res.data);
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      errorMessage = e.response?.data['message'] ?? 'Đăng ký thất bại';
      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _dio.post('/api/auth/logout', data: {'refreshToken': refreshToken});
      } catch (_) {}
    }
    await TokenStorage.clearTokens();
    user   = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}