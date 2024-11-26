import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();

class AuthService {
  Future<void> fetchRefreshToken() async {
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse('http://$baseUrl/refresh-token');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('accessToken');

    if (refreshToken == null) {
      logger.e("There is no refreshToken. Please log in again.");
      return;
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        await prefs.setString('accessToken', jsonData['accessToken']);
        logger.i("The token was refreshed successfully.");
      } else {
        logger.w("Token refresh error: ${response.body}");
      }
    } catch (e) {
      logger.e("Errors when calling the API: $e");
    }
  }

  void startRefreshTokenTimer() {
    Timer.periodic(const Duration(minutes: 30), (timer) {
      fetchRefreshToken(); // Gọi API làm mới token
    });
  }
}
