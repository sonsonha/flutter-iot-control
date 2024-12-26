import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../pages/home/home.dart';

Future<void> fetchDeleteProfile(String token, String currentpassword) async {
  final baseUrl = dotenv.env['API_BASE_URL']!;
  try {
    final response = await http.delete(
      Uri.parse('http://$baseUrl/profile/delete'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },  
      body: jsonEncode({'currentpassword': currentpassword}),
    );

    if (response.statusCode == 200) {
      logger.i('Profile deleted successfully');
    } else {
      logger.e('Failed to delete profile: ${response.statusCode}');
      logger.e('Response body: ${response.body}');
    }
  } catch (e) {
    logger.e('An error occurred while deleting the profile: $e');
  }
}