import 'dart:convert';
import 'package:frontend_daktmt/pages/home/home.dart';
import 'package:http/http.dart'
    as http; // Import HTTP package for making requests
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<Map<String, dynamic>>> fetchhistorydata(
    String token, DateTime start, DateTime end) async {
  final prefs = await SharedPreferences.getInstance();
  final cabinetId = prefs.getString('selectedCabinetId')!;
  final baseUrl = dotenv.env['API_BASE_URL']!;
  final response = await http.post(
    Uri.parse('http://$baseUrl/log/${cabinetId}/get'),
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
