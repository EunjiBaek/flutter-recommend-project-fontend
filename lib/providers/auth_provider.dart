import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

String getBaseUrl() {
  if (Platform.isAndroid) {
    return "http://10.0.2.2:8000";
  } else if (Platform.isIOS) {
    return "http://localhost:8000";
  } else {
    // 나중에 운영환경으로 바꿈
    return "http://localhost:8000";
  }
}

class AuthProvider with ChangeNotifier {
  static String baseUrl = getBaseUrl();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  bool _isLoading = false;
  // ignore: prefer_final_fields
  bool _isLoggedIn = false;
  String? _token;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<Map<String, dynamic>> signup(
      {required String email, required String password}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? '회원가입 성공',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? '회원가입 실패',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '서버 연결에 실패했습니다. $e',
      };
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> login(
      {required String email, required String password}) async {
    _setLoading(true);
    try {
      final result = await _authService.login(email: email, password: password);

      if (result['success'] == true) {
        final token = result['token'] as String;

        await _storageService.saveToken(token);

        _isLoggedIn = true;
        _user = result['user'];
        notifyListeners();
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': '로그인 중 오류가 발생했습니다.',
      };
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> tryAutoLogin() async {
    _setLoading(true);

    try {
      final token = await _storageService.getToken();

      if (token == null) {
        _isLoggedIn = false;
        notifyListeners();
        return false;
      }

      final isExpired = JwtDecoder.isExpired(token);

      if (isExpired) {
        await _storageService.clearToken();
        _isLoggedIn = false;
        _user = null;
        notifyListeners();
        return false;
      }

      final decodedToken = JwtDecoder.decode(token);

      _isLoggedIn = true;
      _user = {
        'id': decodedToken['userId'],
        'email': decodedToken['email'],
      };
      notifyListeners();
      return true;
    } catch (e) {
      await _storageService.clearToken();
      _isLoggedIn = false;
      _user = null;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void logout() {
    _token = null;
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
