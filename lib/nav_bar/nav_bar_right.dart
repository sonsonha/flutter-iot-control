import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_daktmt/apis/api_page.dart';
import 'package:frontend_daktmt/apis/apis_login.dart';
import 'package:frontend_daktmt/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Schedule {
  String id;
  String name;
  bool isOn;
  String day;
  String time;

  Schedule({
    required this.id,
    required this.name,
    required this.isOn,
    required this.day,
    required this.time,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['schedule_id']?.toString() ?? '',
      name: json['schedule_name'] ?? '',
      isOn: json['state'] as bool,
      day: (json['day'] as List<dynamic>).join(', '),
      time: json['time'],
    );
  }
}

final currentDay = DateTime.now().weekday;
final daysOfWeek = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];
final today = daysOfWeek[currentDay - 1];
// List<Schedule> schedules = [];
List<Schedule> todaySchedules = [];

class nabarright_set extends StatefulWidget {
  const nabarright_set({super.key});

  @override
  _nabarright_setState createState() => _nabarright_setState();
}

class _nabarright_setState extends State<nabarright_set> {
  Map<String, dynamic>? profileData;

  @override
  void initState() {
    super.initState();
    _getToken();
    _loadProfile();
    // filterTodaySchedules();
    fetchSchedulesAPI(today);
  }

  String? token;

  void _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('accessToken');
  }

  Future<void> _loadProfile() async {
    try {
      final data = await fetchProfileData(token!);
      setState(() {
        profileData = data;
      });
    } catch (error) {
      logger.e("Error fetching profile: $error");
    }
  }

  Future<void> fetchSchedulesAPI(String day) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('accessToken')!;
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse('http://$baseUrl/schedule/get-home');

    Map<String, dynamic> requestBody = {
      "day": day,
    };

    try {
      var response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData is List) {
          List<Schedule> fetchedSchedules = responseData
              .map<Schedule>((scheduleJson) => Schedule.fromJson(scheduleJson))
              .toList();

          setState(() {
            todaySchedules = fetchedSchedules;
            // filterTodaySchedules(); // Filter today's schedules after updating the list
          });
          print("Success to fetch schedules");
        } else {
          print("Unexpected response format: ${response.body}");
        }
      } else {
        print("Failed to fetch schedules: ${response.body}");
      }
    } catch (e) {
      print("Error occurred: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final bool isRowLayout = isDesktop;

    return Positioned(
      top: isRowLayout ? 14 : 38,
      right: isRowLayout ? 50 : 16,
      child: Builder(
        builder: (context) => GestureDetector(
          onTap: () {
            Scaffold.of(context).openEndDrawer();
          },
          child: Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(143, 255, 255, 255),
              borderRadius: BorderRadius.circular(50),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5.0,
                ),
              ],
            ),
            child: Row(
              children: [
                ClipOval(
                  child: profileData != null &&
                          profileData!['avatar'] != null &&
                          profileData!['avatar']['data'] != null
                      ? Image.memory(
                          base64Decode(profileData!['avatar']['data']),
                          width: 35,
                          height: 35,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/hcmut.png',
                          width: 35,
                          height: 35,
                          fit: BoxFit.cover,
                        ),
                ),
                SizedBox(width: isRowLayout ? 8 : 0),
                isRowLayout
                    ? const Text(
                        "NguyenTrung",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Container(),
                SizedBox(width: isRowLayout ? 8 : 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Navbar_right extends StatelessWidget {
  final Map<String, dynamic> profileData;

  const Navbar_right({super.key, required this.profileData});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('NguyenTrung'),
            accountEmail: const Text('trungvodich@gmail.com'),
            currentAccountPicture: CircleAvatar(
              child: ClipOval(
                child: profileData['avatar'] != null &&
                        profileData['avatar']['data'] != null
                    ? Image.memory(
                        base64Decode(profileData['avatar']['data']),
                        fit: BoxFit.cover,
                      )
                    : Image.asset('assets/hcmut.png'),
              ),
            ),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 165, 165, 165),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Schedule today'),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth *
                  0.9; // Adjusts card size to 90% of the drawer width

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todaySchedules.length,
                itemBuilder: (context, index) {
                  return _buildScheduleCard(index, cardWidth);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

Column _buildScheduleSubtitle(int index) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        todaySchedules[index].isOn ? 'ON' : 'OFF',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: todaySchedules[index].isOn ? Colors.green : Colors.red,
        ),
      ),
    ],
  );
}

Card _buildScheduleCard(int index, double width) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
    elevation: 5,
    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
    child: SizedBox(
      width: width, // Set card width
      child: ListTile(
        leading: const Icon(
          Icons.electrical_services_rounded,
          color: Colors.blueAccent,
          size: 30,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              todaySchedules[index].name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 10),
            Row(
              children: [
                _buildScheduleSubtitle(index),
                Text(todaySchedules[index].time),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
