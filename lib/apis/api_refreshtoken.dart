import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Logger logger = Logger();

/// Gọi API /refresh-token, lưu lại accessToken (và refreshToken nếu backend trả về)
Future<String> fetchRefreshToken() async {
  final baseUrl = dotenv.env['API_BASE_URL']!;
  final url = Uri.parse('http://$baseUrl/refresh-token');

  final prefs = await SharedPreferences.getInstance();

  final accessToken = prefs.getString('accessToken');
  final refreshToken = prefs.getString('refreshToken');

  if (accessToken == null || refreshToken == null) {
    logger.e("No accessToken or refreshToken. Please log in again.");
    return "";
  }

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({
        'refreshToken': refreshToken,
      }),
    );

    if (response.statusCode == 200) {
      logger.i("Successfully refreshed token");
      final jsonData = json.decode(response.body) as Map<String, dynamic>;

      final newAccessToken = jsonData['accessToken'] as String?;
      final newRefreshToken = jsonData['refreshToken'] as String?;

      if (newAccessToken != null) {
        await prefs.setString('accessToken', newAccessToken);
        logger.i("New access token saved");
      }
      if (newRefreshToken != null) {
        await prefs.setString('refreshToken', newRefreshToken);
        logger.i("New refresh token saved");
      }

      return newAccessToken ?? "";
    } else {
      logger.w(
          "Token refresh error: ${response.statusCode} - ${response.body}");
      return "";
    }
  } catch (e) {
    logger.e("Error when calling refresh-token API: $e");
    return "";
  }
}

/// Tự động gọi refresh-token mỗi 15 phút.
/// Nếu fail nhiều lần (trả về token rỗng) thì dừng timer.
void startRefreshTokenTimer() {
  Timer.periodic(const Duration(minutes: 15), (timer) async {
    final token = await fetchRefreshToken();

    if (token.isEmpty) {
      logger.e("Failed to refresh token. Stopping the timer.");
      timer.cancel();
    }
  });
}
