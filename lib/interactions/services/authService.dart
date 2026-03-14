import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class AuthService {
  static const String baseUrl = "http://168.231.83.47:2000";

  final storage = const FlutterSecureStorage();

  Future<AuthModel> login({
    required String login,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/auth/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"login": login, "password": password}),
    );

    if (response.statusCode != 200) {
      throw const AuthException("Erreur d'authentification");
    }

    final data = jsonDecode(response.body);

    final authData = AuthModel.fromJson(data);

    // 🔐 stockage sécurisé des tokens
    await storage.write(key: "access_token", value: authData.accessToken);
    await storage.write(key: "access_token", value: authData.accessToken);
    await storage.write(key: "role", value: authData.user.role);

    return authData;
  }

  Future<String?> getAccessToken() async {
    return await storage.read(key: "access_token");
  }

  Future<void> logout() async {
    await storage.deleteAll();
  }
}
