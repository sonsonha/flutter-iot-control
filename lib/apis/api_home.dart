import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend_daktmt/pages/home/home.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';

// Lấy độ ẩm hiện tại
Future<double> fetchHumidityData(String token, String cabinetId) async {
  try {
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final response = await http.get(
      Uri.parse('http://$baseUrl/sensor/$cabinetId/get/humi'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      final double humidity = (result['data'] as num).toDouble();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('humidity', humidity);

      return humidity;
    } else {
      final result = json.decode(response.body);
      logger.e('Error: ${result['error']}');
    }
  } catch (error) {
    logger.e('Error fetching humidity data: $error');
  }
  return 0.0;
}

// Lấy nhiệt độ hiện tại
Future<double> fetchTemperatureData(String token, String cabinetId) async {
  try {
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final response = await http.get(
      Uri.parse('http://$baseUrl/sensor/$cabinetId/get/temp'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      final double temperature = (result['data'] as num).toDouble();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('temperature', temperature);

      return temperature;
    } else {
      final result = json.decode(response.body);
      logger.e('Error: ${result['error']}');
    }
  } catch (error) {
    logger.e('Error fetching temperature data: $error');
  }
  return 0.0;
}

// Lấy vị trí hiện tại
Future<LatLng> fetchLocationData(String token, String cabinetId) async {
  try {
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final response = await http.get(
      Uri.parse('http://$baseUrl/sensor/$cabinetId/get/location'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      final double latitude = double.parse(result['X']);
      final double longitude = double.parse(result['Y']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('X', latitude);
      await prefs.setDouble('Y', longitude);

      return LatLng(latitude, longitude);
    } else if (response.statusCode == 404) {
      // ✅ Không có location → dùng default, không log error nữa
      logger.w('No location data for this cabinet, using default location');
      const double defaultLat = 10.8797474;
      const double defaultLng = 106.8064651;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('X', defaultLat);
      await prefs.setDouble('Y', defaultLng);

      return const LatLng(defaultLat, defaultLng);
    } else {
      final result = json.decode(response.body);
      logger.e('Error from API location: ${result['error']}');
    }
  } catch (error) {
    logger.e('Error fetching location data: $error');
  }

  // fallback an toàn
  return const LatLng(0.00, 0.00);
}


/// =======================
///   HISTORY – CHART API
/// =======================

Future<List<Map<String, dynamic>>> fetchloghumidata(int time) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final String? token = prefs.getString('accessToken');
    final String? cabinetId = prefs.getString('selectedCabinetId');

    if (token == null || cabinetId == null) {
      logger.e('Missing token or cabinetId when fetchloghumidata');
      return [];
    }

    final baseUrl = dotenv.env['API_BASE_URL']!;
    final response = await http.post(
      Uri.parse('http://$baseUrl/log/$cabinetId/humi'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'time': time.toString(), // backend đang dùng string
      }),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);

      return data.map((item) {
        DateTime date = DateTime.parse(item['date']);

        double yValue;
        final raw = item['value'];
        if (raw == null || raw == '') {
          yValue = 0.0;
        } else if (raw is String) {
          yValue = double.tryParse(raw) ?? 0.0;
        } else if (raw is num) {
          yValue = raw.toDouble();
        } else {
          yValue = 0.0;
        }

        // x sẽ được Chart convert lại theo index, nên tạm cho 0
        return {
          'spot': FlSpot(0, yValue),
          'date': date,
        };
      }).toList();
    } else {
      final result = json.decode(response.body);
      logger.e('Error log humidity: ${result['error']}');
      return [];
    }
  } catch (error) {
    logger.e('Error fetching log humidata: $error');
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchlogtempdata(int time) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final String? token = prefs.getString('accessToken');
    final String? cabinetId = prefs.getString('selectedCabinetId');

    if (token == null || cabinetId == null) {
      logger.e('Missing token or cabinetId when fetchlogtempdata');
      return [];
    }

    final baseUrl = dotenv.env['API_BASE_URL']!;
    final response = await http.post(
      Uri.parse('http://$baseUrl/log/$cabinetId/temp'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'time': time.toString(),
      }),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);

      return data.map((item) {
        DateTime date = DateTime.parse(item['date']);

        double yValue;
        final raw = item['value'];
        if (raw == null || raw == '') {
          yValue = 0.0;
        } else if (raw is String) {
          yValue = double.tryParse(raw) ?? 0.0;
        } else if (raw is num) {
          yValue = raw.toDouble();
        } else {
          yValue = 0.0;
        }

        return {
          'spot': FlSpot(0, yValue),
          'date': date,
        };
      }).toList();
    } else {
      final result = json.decode(response.body);
      logger.e('Error log Temperature: ${result['error']}');
      return [];
    }
  } catch (error) {
    logger.e('Error fetching log tempedata: $error');
    return [];
  }
}
