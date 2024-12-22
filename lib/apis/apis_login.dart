import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();
Future<bool> fetchSignIn(TextEditingController emailController,
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

      Navigator.pushReplacementNamed(context, '/home');
      return true;
    } else {
      final result = json.decode(response.body);
      logger.e('Error: ${result['error']}');
      throw Exception('Failed to load data: ${result['error']}');
    }
  } catch (e) {
    logger.e('Error fetching data: $e');
    return false;
  }
}

Future<bool> fetchRegister(
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
        const SnackBar(content: Text('Đăng kí tài khoản thành công')),
      );
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/signin');
      return true;
    } else {
      final errorMessage =
          json.decode(response.body)['message'] ?? 'Tài khoản này đã tồn tại';

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
      return false;
    }
  } catch (e) {
    // Handle any exceptions
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Lỗi kết nối với server')));
    return false;
  }
}

Future<bool> fetchForgetPassword(TextEditingController emailController,
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
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu thành công')),
      );
      Navigator.pushReplacementNamed(context, '/signin');
      return true;
    } else {
      if (!context.mounted) return false;
      final errorMessage =
          json.decode(response.body)['message'] ?? 'Tài khoản không tồn tại';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
      return false;
    }
  } catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Lỗi kết nối với server')));
    return false;
  }
}

Future<bool> fetchSendcode(String email) async {
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
      logger.i("Success");
      // print('Response body: ${response.body}');
      return true;
    } else {
      logger.e("Failed to send verification code");
      return false;
    }
  } catch (error) {
    logger.e("Error: $error");
    return false;
  }
}

Future<bool> fetchConfirmcode(String email, String code) async {
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
      return true;
    } else {
      return false;
    }
  } catch (error) {
    return false;
  }
}
