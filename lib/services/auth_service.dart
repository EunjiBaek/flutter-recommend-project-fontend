import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

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

class AuthService {
  final String baseUrl = getBaseUrl();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': data['message'],
        'token': data['token'],
        'user': data['user'],
      };
    }

    return {
      'success': false,
      'message': data['message'] ?? '로그인 실패',
    };
  }
}
