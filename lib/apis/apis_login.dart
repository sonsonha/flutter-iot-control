import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();
Future<String?> fetchSignIn(TextEditingController emailController,
    TextEditingController passwordController, BuildContext context) async {
  final baseUrl = dotenv.env['API_BASE_URL']!;
  final url = Uri.parse('http://$baseUrl/login');

  try {
    String convertEmail = emailController.text.toLowerCase();
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'emailOrusername': convertEmail,
        'password': passwordController.text,
      }),
    );
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('accessToken', jsonData['accessToken']);
      await prefs.setString('refreshToken', jsonData['refreshToken']);
      // Kiểm tra và xử lý giá trị của temperature
      if (jsonData['temperature'] is double) {
        await prefs.setDouble('temperature', jsonData['temperature']);
      } else if (jsonData['temperature'] is String) {
        jsonData['temperature'] =
            double.tryParse(jsonData['temperature']) ?? 0.0;
        await prefs.setDouble('temperature', jsonData['temperature']);
      }

// Kiểm tra và xử lý giá trị của humidity
      if (jsonData['humidity'] is double) {
        await prefs.setDouble('humidity', jsonData['humidity']);
      } else if (jsonData['humidity'] is String) {
        jsonData['humidity'] = double.tryParse(jsonData['humidity']) ?? 0.0;
        await prefs.setDouble('humidity', jsonData['humidity']);
      }

      await prefs.setString('location', jsonData['location']);
      await prefs.setString('relays', json.encode(jsonData['relays']));
      await prefs.setString(
          'relays_home', json.encode(jsonData['relays_home']));
      await prefs.setString('schedules', json.encode(jsonData['schedules']));
      await prefs.setString(
          'schedules_home', json.encode(jsonData['schedules_home']));
      await prefs.setString('profile', json.encode(jsonData['profile']));

      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/home');
      return null;
    } else {
      final result = json.decode(response.body);
      logger.e('Error: ${result['error']}');
      String errorMessage = result['error'] ?? 'Unknown error occurred.';
      return errorMessage;
    }
  } catch (e) {
    logger.e('Error fetching data: $e');
    return 'Error fetching data: $e';
  }
}

Future<String> fetchRegister(
    TextEditingController fullname,
    TextEditingController username,
    TextEditingController emailController,
    TextEditingController passwordController,
    TextEditingController aiouser,
    TextEditingController aiokey,
    TextEditingController phone,
    BuildContext context) async {
  final baseUrl = dotenv.env['API_BASE_URL']!;
  final url = Uri.parse('http://$baseUrl/register');

  try {
    String convertUsername = username.text.toLowerCase();
    String convertEmail = emailController.text.toLowerCase();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'fullname': fullname.text,
        'username': convertUsername,
        'email': convertEmail,
        'password': passwordController.text,
        'aioUser': aiouser.text,
        'aioKey': aiokey.text,
        'phone': phone.text,
      }),
    );
    if (response.statusCode == 200) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully registered')),
      );
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/signin');
      return 'Successfully registered';
    } else {
      final errorMessage =
          json.decode(response.body)['error'] ?? 'This account already exists';

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
      return errorMessage;
    }
  } catch (e) {
    // Handle any exceptions
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot connect to server')));
    return 'Cannot connect to server';
  }
}

Future<String> fetchForgetPassword(TextEditingController emailController,
    TextEditingController passwordController, BuildContext context) async {
  final baseUrl = dotenv.env['API_BASE_URL']!;
  final url = Uri.parse('http://$baseUrl/forgot-password');

  try {
    String convertEmail = emailController.text.toLowerCase();
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'emailOrusername': convertEmail,
        'newPassword': passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      if (!context.mounted) return '';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully changed password')),
      );
      Navigator.pushReplacementNamed(context, '/signin');
      return 'Successfully changed password';
    } else {
      if (!context.mounted) return '';
      final errorMessage =
          json.decode(response.body)['error'] ?? 'This account does not exist';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
      return errorMessage;
    }
  } catch (e) {
    if (!context.mounted) return '';
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot connect to server')));
    return 'Cannot connect to server';
  }
}

Future<String> fetchSendcode(String email) async {
  final baseUrl = dotenv.env['API_BASE_URL']!;
  final url = Uri.parse('http://$baseUrl/email/send-code');
  try {
    String convertEmail = email.toLowerCase();
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': convertEmail,
      }),
    );
    if (response.statusCode == 200) {
      logger.i("Successful code submission");
      // print('Response body: ${response.body}');
      return 'Successful code submission';
    } else {
      logger.e("Failed to send verification code");
      return 'Failed to send verification code';
    }
  } catch (error) {
    logger.e("Error: $error");
    return 'Error: $error';
  }
}

Future<String> fetchConfirmcode(String email, String code) async {
  final baseUrl = dotenv.env['API_BASE_URL']!;
  final url = Uri.parse('http://$baseUrl/email/confirm-code');
  try {
    String convertEmail = email.toLowerCase();
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': convertEmail,
        'verificationCode': code,
      }),
    );

    if (response.statusCode == 200) {
      return 'Success verification code';
    } else {
      return 'Failed to confirm verification code';
    }
  } catch (error) {
    return 'Error: $error';
  }
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
