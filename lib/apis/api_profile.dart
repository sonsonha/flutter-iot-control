import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
// import 'dart:io';

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

// api_profile.dart
Future<Map<String, dynamic>?> fetchEditProfile(
  String token,
  Map<String, dynamic> updatedData,
  Uint8List? avatarBytes,
  Uint8List? coverPhotoBytes,
) async {
  final baseUrl = dotenv.env['API_BASE_URL']!;
  final uri = Uri.parse('http://$baseUrl/profile/edit');

  // Lấy currentpassword ra riêng
  final String? currentPassword = updatedData['currentpassword']?.toString();

  final request = http.MultipartRequest('PATCH', uri)
    ..headers['Authorization'] = 'Bearer $token';

  // Thêm các field text
  updatedData.forEach((key, value) {
    if (key != 'currentpassword') {
      request.fields[key] = value.toString();
    }
  });

  if (currentPassword != null && currentPassword.isNotEmpty) {
    request.fields['currentpassword'] = currentPassword;
  }

  // Nếu có avatar mới
  if (avatarBytes != null) {
    request.files.add(
      http.MultipartFile.fromBytes(
        'avatar',            // 👈 trùng với req.files['avatar'] trên backend
        avatarBytes,
        filename: 'avatar.png',
      ),
    );
  }

  // Nếu có cover mới
  if (coverPhotoBytes != null) {
    request.files.add(
      http.MultipartFile.fromBytes(
        'coverPhoto',        // 👈 trùng với req.files['coverPhoto']
        coverPhotoBytes,
        filename: 'cover.png',
      ),
    );
  }

  // Nếu không có gì thay đổi thật sự
  if (request.fields.length == (currentPassword == null ? 0 : 1) &&
      avatarBytes == null &&
      coverPhotoBytes == null) {
    logger.e('No data provided to update.');
    return null;
  }

  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);

  logger.i(
      'Update profile response: ${response.statusCode} ${response.body}');

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['data'] as Map<String, dynamic>;
  } else {
    try {
      final decoded = jsonDecode(response.body);
      logger.e(
          'Update profile failed resbody: ${response.statusCode} ${decoded['error'] ?? response.body}');
    } catch (_) {
      logger.e(
          'Update profile failed: ${response.statusCode} raw=${response.body}');
    }
    return null;
  }
}


// api_profile.dart
// Future<Map<String, dynamic>?> fetchEditProfile(
//   String token,
//   Map<String, dynamic> updatedData,
//   Uint8List? avatarBytes,
//   Uint8List? coverPhotoBytes,
//   ) async {
//   final baseUrl = dotenv.env['API_BASE_URL']!;
//   final uri = Uri.parse('http://$baseUrl/profile/edit');

//   final String? currentPassword = updatedData['currentpassword']?.toString();
//   final Map<String, dynamic> body = {};

//   // copy các field text sang body
//   updatedData.forEach((key, value) {
//     if (key != 'currentpassword') {
//       body[key] = value.toString();
//     }
//   });

//   // ảnh base64
//   if (avatarBytes != null) {
//     body['avatarBase64'] = base64Encode(avatarBytes);
//   }
//   if (coverPhotoBytes != null) {
//     body['coverPhotoBase64'] = base64Encode(coverPhotoBytes);
//   }

//   // nếu thật sự không có gì đổi
//   if (body.isEmpty && avatarBytes == null && coverPhotoBytes == null) {
//     logger.e('No data provided to update.');
//     return null;
//   }

//   if (currentPassword != null && currentPassword.isNotEmpty) {
//     body['currentpassword'] = currentPassword;
//   }

//   final response = await http.patch(
//     uri,
//     headers: {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token',
//     },
//     body: jsonEncode(body),
//   );

//   if (response.statusCode == 200) {
//     logger.i('💡 Profile updated: ${response.body}');
//     final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//     return decoded['data'] as Map<String, dynamic>;
//   } else {
//     logger.e('Update profile failed: ${response.statusCode} ${response.body}');
//     return null;
//   }
// }



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
