import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../pages/home/home.dart';

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
      logger.e('No data found in response');
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
    final errorData = jsonDecode(response.body);
    final errorMessage = errorData['error'] ?? 'Failed to update profile.';
    logger.e('$errorMessage');
  }
}

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
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['error'] ?? 'Unknown error occurred.';
      logger.e('Failed to delete profile: $errorMessage');
    }
  } catch (e) {
    logger.e('An error occurred while deleting the profile: $e');
  }
}
