import 'dart:async';
// import 'package:frontend_daktmt/apis/api_page.dart';
import 'package:frontend_daktmt/apis/api_page.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();


  Future<String> fetchRefreshToken() async {
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse('http://$baseUrl/refresh-token');
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Lấy refreshToken thay vì accessToken
    final refreshToken = prefs.getString('refreshToken');

    if (refreshToken == null) {
      logger.e("There is no refreshToken. Please log in again.");
      return "";
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

        // Lưu accessToken mới vào SharedPreferences
        await prefs.setString('accessToken', jsonData['accessToken']);
        logger.i("New access token has been created!");
        return jsonData['accessToken'];
      } else {
        logger.w("Token refresh error: ${response.body}");
        return "";
      }
    } catch (e) {
      logger.e("Errors when calling the API: $e");
      return "";
    }
  }

  // Hàm gọi API làm mới token tự động mỗi 30 phút
  // void startRefreshTokenTimer() {
  //   Timer.periodic(const Duration(minutes: 30), (timer) {
  //     fetchRefreshToken();
  //   });
  // }

  void startRefreshTokenTimer(Function updateSensorData) {
    Timer.periodic(const Duration(minutes: 2), (timer) async {
      // Lấy token mới
      print("hh");
      final token = await fetchRefreshToken();

      if (token.isNotEmpty) {
        print('pass123');
        // fetchSensorData();
        fetchHumidityData(token);
        fetchTemperatureData(token);
        fetchLocationData(token);
        updateSensorData();
      }else {
      logger.e("Failed to refresh token. Stopping the timer.");
      timer.cancel();
    }
    });
  }

