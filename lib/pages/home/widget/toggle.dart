import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../home.dart';

class Relay {
  final int id;
  final String name;
  final bool isOn;

  Relay({required this.id, required this.name, this.isOn = false});

  factory Relay.fromJson(Map<String, dynamic> json) {
    return Relay(
      id: json['relay_id'] ?? 0,
      name: json['relay_name'] ?? 'Unnamed Relay',
      isOn: json['state'] ?? false,
    );
  }
}

// ignore: camel_case_types
class toggle extends StatefulWidget {
  final double toggleHeight;
  final double toggleWidth;
  final int numOfRelay;

  const toggle({
    super.key,
    required this.toggleHeight,
    required this.toggleWidth,
    required this.numOfRelay,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ToggleState createState() => _ToggleState();
}

class _ToggleState extends State<toggle> {
  List<Relay> homeRelays = [];

  @override
  void initState() {
    super.initState();
    fetchHomeRelays();
  }

  // Future<void> fetchHomeRelays() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final responseData = prefs.getString('relays_home');

  //   if (responseData != null) {
  //     try {
  //       final decodedData = json.decode(responseData);
  //       if (decodedData is List) {
  //         setState(() {
  //           homeRelays = decodedData
  //               .map<Relay>((relayJson) => Relay.fromJson(relayJson))
  //               .toList();
  //         });
  //       }
  //     } catch (e) {
  //       logger.e("Error parsing relays_home data: $e");
  //     }
  //   } else {
  //     logger.i("No relays_home data found.");
  //   }
  // }

    Future<void> fetchHomeRelays() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('accessToken')!;
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse('http://$baseUrl/relay/get-home');
    try {
      var response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data is List<dynamic>) {
          List<Relay> fetchedRelays = data.map((relay) {
            return Relay(
              id: relay['relay_id'],
              name: relay['relay_name'],
              isOn: relay['state'],
            );
          }).toList();
          if (mounted) {
            setState(() {
              homeRelays = fetchedRelays;
            });
          }
        } else {
          setState(() {
            homeRelays = [];
          });
          logger.w("Unexpected response format: ${response.body}");
        }
      } else {
        logger.w("Failed to fetch home relays: ${response.body}");
      }
    } catch (e) {
      logger.e("Error occurred: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (homeRelays.isEmpty) {
      return const Center(child: Text(""));
    }

    return Center(
      child: SizedBox(
        width: widget.toggleWidth,
        height: widget.toggleHeight,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10.0, // Horizontal spacing between widgets
          runSpacing: 10.0, // Vertical spacing between widgets
          children: List.generate(homeRelays.length, (index) {
            return SizedBox(
              width: widget.toggleWidth / widget.numOfRelay - 10,
              height: 100.0,
              child: OnOffSwitch(
                label: homeRelays[index].name,
                state: homeRelays[index].isOn,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class OnOffSwitch extends StatelessWidget {
  final String label;
  final bool state;

  const OnOffSwitch({super.key, required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 253, 253, 253),
            Color.fromARGB(255, 255, 255, 255),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20.0,
              color: Color.fromARGB(255, 42, 5, 113),
            ),
            overflow:
                TextOverflow.ellipsis, // Adds "..." if the text is too long
            maxLines: 1, // Limits to a single line
            softWrap: false, // Prevents wrapping to a new line
          ),
          const SizedBox(height: 2),
          Text(
            state ? 'On' : 'Off',
            style: TextStyle(
              color: state ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
        ],
      ),
    );
  }
}
