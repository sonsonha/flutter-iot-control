import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend_daktmt/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/home/home.dart';

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

Map<String, dynamic>? profileData;
// const bool _isHovered = false; // To detect hover
const bool _isTapped = false; // To detect tap (for mobile)
int? _hoveredIndex;

// List<Schedule> schedules = [];
List<Schedule> todaySchedules = [];

// ignore: camel_case_types
class nabarright_set extends StatefulWidget {
  const nabarright_set({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _nabarright_setState createState() => _nabarright_setState();
}

// ignore: camel_case_types
class _nabarright_setState extends State<nabarright_set> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
    fetchSchedulesAPI();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final storedProfileData = prefs.getString('profile');

    if (storedProfileData != null) {
      final Map<String, dynamic> profileMap = json.decode(storedProfileData);
      setState(() {
        profileData = {
          'username': profileMap['username'],
          'email': profileMap['email'],
        };
      });
    } else {
      setState(() {
        profileData = {
          'username': 'Guest',
          'email': 'No email available',
        };
      });
      logger.w("No profileData found in SharedPreferences.");
    }
  }

  Future<void> fetchSchedulesAPI() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final responseData = prefs.getString('schedules_home');
    if (responseData != null) {
      try {
        final List<dynamic> jsonSchedules = json.decode(responseData);
        List<Schedule> fetchedSchedules = jsonSchedules
            .map<Schedule>((scheduleJson) => Schedule.fromJson(scheduleJson))
            .toList();
        setState(() {
          todaySchedules = fetchedSchedules;
        });
      } catch (e) {
        logger.e("Error parsing local schedules: $e");
      }
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
                  child: profileData != null
                      ? (profileData!['profileImage'] != null
                          ? Image.memory(
                              base64Decode(profileData!['profileImage']),
                              width: 30,
                              height: 30,
                              fit: BoxFit.cover,
                            )
                          : CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Text(
                                profileData!['username'][0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.primaries[
                                      DateTime.now().second %
                                          Colors.primaries.length],
                                ),
                              ),
                            ))
                      : const Icon(Icons.account_circle, size: 30),
                ),
                SizedBox(width: isRowLayout ? 8 : 0),
                isRowLayout
                    ? Text(
                        profileData?['username'] ?? 'Guest',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Container(),
                SizedBox(width: isRowLayout ? 8 : 0, height: 10),
                

              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: camel_case_types
class Navbar_right extends StatelessWidget {
  const Navbar_right({super.key});

  // final Map<String, dynamic>? profileData;

  // const Navbar_right({
  //   super.key,
  //   required this.profileData,
  // });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              profileData?['username'] ?? 'N/A', // Display username
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(
              profileData?['email'] ?? 'Email not available', // Display email
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: profileData != null
                  ? ClipOval(
                      child: Text(
                        profileData!['username'][0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 40,
                          color: Colors.primaries[
                              DateTime.now().second % Colors.primaries.length],
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.account_circle,
                      size: 80,
                      color: Color.fromARGB(255, 255, 0, 0),
                    ),
            ),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 165, 165, 165),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text(
              'Schedule today',
              style: TextStyle(
                color: Color.fromARGB(255, 7, 23, 80),
                fontFamily: 'avenir',
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth * 0.9;

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
  // Determine the background color and text style based on the "on" state
  Color backgroundColor = todaySchedules[index].isOn
      ? const Color(0xFF6448FE) // Active state (with gradient)
      : const Color.fromARGB(255, 187, 176, 176);

  // Ensure scale is never null, default to 1.0 if no hover/tap effect
  double scale = _hoveredIndex == index || _isTapped ? 1.05 : 1.0;

  return Card(
    margin: const EdgeInsets.all(8.0),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
    ),
    child: Transform.scale(
      scale: scale, // Provide a valid scale value (1.0 by default)
      child: Container(
        decoration: BoxDecoration(
          gradient: todaySchedules[index].isOn
              ? const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 6, 33, 83),
                    Color.fromARGB(255, 11, 9, 160)
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null, // No gradient if inactive
          color: !todaySchedules[index].isOn
              ? backgroundColor
              : null, // Apply gray if inactive
          boxShadow: [
            BoxShadow(
              color: [
                const Color.fromARGB(255, 19, 76, 130),
                const Color(0xFF5FC6FF)
                // ignore: deprecated_member_use
              ].last.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(4, 4),
            ),
          ],
          borderRadius: const BorderRadius.all(Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First Column: Icon or Checkbox
              const Icon(
                Icons.timer_rounded,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(
                  width: 8), // Space between icon/checkbox and next column

              // Second Column: Name, ID, Status
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todaySchedules[index].name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: 'avenir',
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    // const SizedBox(height: 2),
                    // _buildScheduleSubtitle(index), // Displays ID and Status
                  ],
                ),
              ),
              const SizedBox(width: 30), // Space between columns

              // Third Column: Day and Time Info (centered)
              Expanded(
                flex: 2,
                child: Center(
                  child: SizedBox(
                    width: 200,
                    child: _buildScheduleSubtitle(index),
                  ),
                ),
              ),
              const SizedBox(width: 8), // Space between columns

              // Fourth Column: Trailing Actions
              Expanded(
                flex: 2,
                child: Text(
                  todaySchedules[index].time,
                  style: const TextStyle(
                      color: Colors.white, fontFamily: 'avenir'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
