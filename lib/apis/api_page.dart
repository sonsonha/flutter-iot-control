import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend_daktmt/pages/home/home.dart';
import 'package:http/http.dart'
    as http; // Import HTTP package for making requests
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for storing data
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';

Future<double> fetchHumidityData(String token) async {
  try {
    final baseUrl = dotenv.env['API_BASE_URL']!;

    final response = await http.get(
      Uri.parse('http://$baseUrl/sensor/get/humi'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      double humidity = result['data']; // Lấy giá trị độ ẩm (double)

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('humidity', humidity); // Lưu độ ẩm dưới dạng double

      return humidity;
    } else {
      final result = json.decode(response.body);
      logger.e('Error: ${result['error']}');
    }
  } catch (error) {
    logger.e('Error fetching humidity data: $error');
  }
  return 0.0; // Trả về giá trị mặc định nếu có lỗi
}

Future<double> fetchTemperatureData(String token) async {
  try {
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final response = await http.get(
      Uri.parse('http://$baseUrl/sensor/get/temp'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      double temperature = result['data']; // Lấy giá trị nhiệt độ (double)

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(
          'temperature', temperature); // Lưu nhiệt độ dưới dạng double

      return temperature; // Trả về giá trị nhiệt độ dạng double
    } else {
      final result = json.decode(response.body);
      logger.e('Error: ${result['error']}');
    }
  } catch (error) {
    logger.e('Error fetching temperature data: $error');
  }
  return 0.0; // Trả về giá trị mặc định nếu có lỗi
}

Future<LatLng> fetchLocationData(String token) async {
  try {
    final baseUrl = dotenv
        .env['API_BASE_URL']!; // Fetch the base URL from environment variables
    final response = await http.get(
      Uri.parse('http://$baseUrl/sensor/get/location'), // Construct the API URL
      headers: {
        'Content-Type': 'application/json', // Set the content type to JSON
        'Authorization': 'Bearer $token', // Include the token in the header
      },
    );
    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      // Sử dụng double.parse() để chuyển chuỗi sang số thập phân
      final double latitude =
          double.parse(result['X']); // Chuyển đổi chuỗi 'X' thành double
      final double longitude =
          double.parse(result['Y']); // Chuyển đổi chuỗi 'Y' thành double
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('X', latitude);
      await prefs.setDouble('Y', latitude);
      return LatLng(latitude, longitude);
    } else {
      final result = json.decode(response.body);
      logger.e('Error from API: ${result['error']}'); // In lỗi từ API
    }
  } catch (error) {
    logger
        .e('Error fetching location data: $error'); // Log any errors that occur
  }

  return const LatLng(0.00, 0.00);
}

// ignore: camel_case_types
class apilogout {
  final String apiUrl =
      'http://${dotenv.env['API_BASE_URL']}/logout'; // URL API đăng xuất

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken'); // Lấy token từ SharedPreferences
  }

  Future<bool> logoutUser() async {
    String? token = await getAccessToken(); // Lấy token

    if (token == null) {
      return false; // Không có token, không thể đăng xuất
    }

    try {
      final response = await http.get(
        // Sử dụng POST thay vì GET
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Gửi token trong header
        },
      );

      if (response.statusCode == 200) {
        // Nếu đăng xuất thành công, xóa token
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('accessToken'); // Xóa token
        await prefs.clear();
        return true; // Trả về true nếu đăng xuất thành công
      } else {
        final result = json.decode(response.body);
        logger.e('Error: ${result['error']}');
        return false; // Trả về false nếu có lỗi
      }
    } catch (error) {
      logger.e('Error logging out: $error');
      return false; // Trả về false nếu có lỗi
    }
  }
}

Future<List<Map<String, dynamic>>> fetchloghumidata(
    String token, int time) async {
  try {
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final response = await http.post(
      Uri.parse('http://$baseUrl/log/humi'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'time': time,
      }),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);

      return data.map((item) {
        // Đảm bảo 'date' là DateTime hợp lệ
        DateTime date = DateTime.parse(item['date']);
        double yValue = (item['value'] == null || item['value'] == '')
            ? 0.0
            : (item['value'] is String
                ? double.tryParse(item['value']) ?? 0.0
                : item['value']?.toDouble() ?? 0.0);
        double xValue = (date.millisecondsSinceEpoch -
                DateTime.parse(data.first['date']).millisecondsSinceEpoch) /
            (1000 * 60 * 60 * 24);

        return {
          'spot': FlSpot(xValue, yValue),
          'date': date,
        };
      }).toList();
    } else {
      final result = json.decode(response.body);
      logger.e('Error: ${result['error']}');
      throw Exception('Failed to load data: ${result['error']}');
    }
  } catch (error) {
    logger.e('Error fetching data: $error');
    throw Exception('Error fetching data');
  }
}

Future<List<Map<String, dynamic>>> fetchlogtempdata(
    String token, int time) async {
  try {
    final baseUrl = dotenv.env['API_BASE_URL']!;

    final response = await http.post(
      Uri.parse('http://$baseUrl/log/temp'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Sử dụng token
      },
      body: json.encode({
        'time': time,
      }),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
  
      return data.map((item) {
        // Đảm bảo 'date' là DateTime hợp lệ

        DateTime date = DateTime.parse(item['date']);

        double yValue = (item['value'] == null || item['value'] == '')
            ? 0.0
            : (item['value'] is String
                ? double.tryParse(item['value']) ?? 0.0
                : item['value']?.toDouble() ?? 0.0);
        double xValue = (date.millisecondsSinceEpoch -
                DateTime.parse(data.first['date']).millisecondsSinceEpoch) /
            (1000 * 60 * 60 * 24);

        return {
          'spot': FlSpot(xValue, yValue),
          'date': date,
        };
      }).toList();
    } else {
      final result = json.decode(response.body);
      logger.e('Error: ${result['error']}');
      throw Exception('Failed to load data: ${result['error']}');
    }
  } catch (error) {
    logger.e('Error fetching data: $error');
    throw Exception('Error fetching data');
  }
}

Future<List<Map<String, dynamic>>> fetchhistorydata(
    String token, DateTime start, DateTime end) async {
  final baseUrl = dotenv.env['API_BASE_URL']!;
  final response = await http.post(
    Uri.parse('http://$baseUrl/log/get'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode({
      'start': '${start.year}/${start.month}/${start.day}',
      'end': '${end.year}/${end.month}/${end.day}'
    }),
  );

  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    
    return data.map((item) {
      if (item.containsKey('Date')) {
        try {
          // Assuming the format in response is "HH/mm/ss dd/MM/yyyy"
          final date = DateFormat('HH/mm/ss dd/MM/yyyy').parse(item['Date']);
          item['Date'] =
              date.toIso8601String(); // Convert to ISO or preferred format
        } catch (e) {
          logger.e("Failed to parse date: $e");
        }
      }
      return item as Map<String, dynamic>;
    }).toList();
  } else {
    final result = json.decode(response.body);
    throw Exception('Failed to load data: ${result['error']}');
  }
}

Future<Map<String, dynamic>> fetchProfileData(String token) async {
  final baseUrl = dotenv.env['API_BASE_URL']!;
  final response = await http.get(
    Uri.parse('http://$baseUrl/profile'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return json.decode(response.body)['data'];
  } else {
    final decodedBody = json.decode(response.body);
    if (decodedBody.containsKey('data')) {
      return decodedBody['data'];
    } else {
      throw Exception('No data found in response');
    }
  }
}

Future<void> fetchEditProfile(
  String token,
  Map<String, dynamic> updatedData,
  File? avatarImageFile,
  File? coverPhotoFile,
) async {
  final baseUrl = dotenv.env['API_BASE_URL']!;
  final uri = Uri.parse('http://$baseUrl/profile/edit');

  final request = http.MultipartRequest('PATCH', uri)
    ..headers['Authorization'] = 'Bearer $token';

  updatedData.forEach((key, value) {
    request.fields[key] = value.toString();
  });

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode != 200) {
    throw Exception('Failed to update profile');
  }
}
