import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend_daktmt/pages/home/home.dart';
import 'package:http/http.dart'
    as http; // Import HTTP package for making requests
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

      return humidity; // Trả về giá trị độ ẩm dạng double
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

Future<List<FlSpot>> fetchloghumidata(String token, int time) async {
  try {
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final response = await http.post(
      Uri.parse('http://$baseUrl/log/humi'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Sử dụng token
      },
      body: json.encode({
        'time': time, // Định nghĩa thời gian cần lấy dữ liệu
      }),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body); // Parse JSON response

      logger.i('Data fetched: $data'); // In dữ liệu đã nhận
      double firstTimestamp =
          DateTime.parse(data.first['date']).millisecondsSinceEpoch.toDouble();
      // Map dữ liệu thành danh sách FlSpot
      return data.map((item) {
        // double xValue =
        //     DateTime.parse(item['date']).millisecondsSinceEpoch.toDouble();
        double xValue =
            (DateTime.parse(item['date']).millisecondsSinceEpoch.toDouble() -
                    firstTimestamp) /
                (1000 * 60 * 60 * 24);
        // Chuyển đổi giá trị 'value', kiểm tra cả khi value là chuỗi
        double? yValue = item['value'] is String
            ? double.tryParse(item['value'])
            : item['value']?.toDouble();

        // Nếu không parse được thì trả về giá trị mặc định là 0.0
        return FlSpot(xValue, yValue ?? 0.0);
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

Future<List<FlSpot>> fetchlogtempdata(String token, int time) async {
  try {
    final baseUrl = dotenv.env['API_BASE_URL']!;

    final response = await http.post(
      Uri.parse('http://$baseUrl/log/temp'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Sử dụng token
      },
      body: json.encode({
        'time': time, // Định nghĩa thời gian cần lấy dữ liệu
      }),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body); // Parse JSON response

      logger.i('Data fetched: $data'); // In dữ liệu đã nhận
      double firstTimestamp =
          DateTime.parse(data.first['date']).millisecondsSinceEpoch.toDouble();
      // Map dữ liệu thành danh sách FlSpot
      return data.map((item) {
        // double xValue =
        //     DateTime.parse(item['date']).millisecondsSinceEpoch.toDouble();
        double xValue =
            (DateTime.parse(item['date']).millisecondsSinceEpoch.toDouble() -
                    firstTimestamp) /
                (1000 * 60 * 60 * 24);
        // Chuyển đổi giá trị 'value', kiểm tra cả khi value là chuỗi
        double? yValue = item['value'] is String
            ? double.tryParse(item['value'])
            : item['value']?.toDouble();

        // Nếu không parse được thì trả về giá trị mặc định là 0.0
        return FlSpot(xValue, yValue ?? 0.0);
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
    return data
        .map((item) => item as Map<String, dynamic>)
        .toList(); // Convert each item to Map
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
    final result = json.decode(response.body);
    throw Exception('Failed to load profile: ${result['error']}');
  }
}
