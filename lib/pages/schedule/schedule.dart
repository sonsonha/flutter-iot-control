// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend_daktmt/custom_card.dart';
import 'package:frontend_daktmt/nav_bar/nav_bar_left.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/home.dart';
// import 'dart:math' as math;

class Relay {
  String id;
  String name;
  bool isOn;
  bool isSetChedule;

  Relay(
      {required this.id,
      required this.name,
      this.isOn = false,
      this.isSetChedule = false});
}

class Action {
  int relayId;
  String action;

  Action({required this.relayId, required this.action});

  factory Action.fromJson(Map<String, dynamic> json) {
    return Action(
      relayId: json['relayId'] as int,
      action: json['action'] as String,
    );
  }
}

class Schedule {
  String id;
  String name;
  bool isOn;
  List<String> day;
  String time;
  List<Action> actions;

  Schedule({
    required this.id,
    required this.name,
    required this.isOn,
    required this.day,
    required this.time,
    required this.actions,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['schedule_id']?.toString() ?? '',
      name: json['schedule_name'] ?? '',
      isOn: json['state'] as bool,
      day: List<String>.from(json['day']), // Parse `day` as List<String>
      time: json['time'],
      actions: (json['actions'] as List<dynamic>)
          .map((actionJson) => Action.fromJson(actionJson))
          .toList(),
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // final bool _isHovered = false; // To detect hover
  final bool _isTapped = false; // To detect tap (for mobile)
  int? _hoveredIndex;
  final TextEditingController _nameController = TextEditingController();
  final List<String> _days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];
  TimeOfDay selectedTime = TimeOfDay.now();
  Map<String, bool> _selectedDays = {};

  List<Relay> selectedRelays = []; // Relays selected add to schedule
  List<Schedule> schedules = [];
  List<Relay> relays = [];
  List<Relay> relaysAddedToSchedule = [];

  bool _showDeleteIcon = false;
  bool _showEditIcon = false;
  bool _selectMode = false;
  List<bool> _isSelected = []; // Schedules is selected
  List<bool> _isSelectedRelays =
      []; // Check whether the relay is checked or not bruh

  int indexScheduleEdit = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _nameError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    for (var day in _days) {
      _selectedDays[day] = false;
    }
    _isSelectedRelays = List<bool>.filled(relays.length, false);
    // fetchSchedulesAPI(); // Fetch relays when the screen initializes
    loadSchedulesFromPrefs();
    _isSelected = List.generate(
      schedules.length,
      (index) => false,
    );
  }

  // Future<void> fetchSchedulesAPI() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   var token = prefs.getString('accessToken')!;
  //   final baseUrl = dotenv.env['API_BASE_URL']!;
  //   final url = Uri.parse('http://$baseUrl/schedule/get');
  //   try {
  //     final response = await http.get(url, headers: {
  //       'Authorization': 'Bearer $token',
  //     });

  //     if (response.statusCode == 200) {
  //       final responseData = json.decode(response.body);

  //       if (responseData is List) {
  //         List<Schedule> fetchedSchedules = responseData
  //             .map<Schedule>((scheduleJson) => Schedule.fromJson(scheduleJson))
  //             .toList();

  //         await prefs.setString('schedules', json.encode(responseData));

  //         setState(() {
  //           schedules = fetchedSchedules;
  //           _isSelected = List.generate(schedules.length, (_) => false);
  //         });
  //         print("Success to fetch schedules");
  //       } else {
  //         setState(() {
  //           relays = [];
  //           _isSelected = [];
  //         });
  //         print("Unexpected response format: ${response.body}");
  //       }
  //     } else {
  //       print("Failed to fetch relays: ${response.body}");
  //     }
  //   } catch (e) {
  //     print("Error occurred: $e");
  //   }
  // }

  Future<void> fetchSchedulesAPI() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('accessToken')!;
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse('http://$baseUrl/schedule/get');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData is List) {
          List<Schedule> fetchedSchedules = responseData
              .map<Schedule>((scheduleJson) => Schedule.fromJson(scheduleJson))
              .toList();

          // Save schedules to SharedPreferences
          await prefs.setString('schedules', json.encode(responseData));

          setState(() {
            schedules = fetchedSchedules;
            _isSelected = List.generate(schedules.length, (_) => false);
          });

          logger.i("Success to fetch schedules");
        } else {
          setState(() {
            schedules = [];
            _isSelected = [];
          });
          logger.w("Unexpected response format: ${response.body}");
        }
      } else {
        logger.e("Failed to fetch schedules: ${response.body}");
      }
    } catch (e) {
      logger.e("Error occurred: $e");
    }
  }

  Future<void> loadSchedulesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String? schedulesJson = prefs.getString('schedules');

    if (schedulesJson != null) {
      List<dynamic> decoded = json.decode(schedulesJson);
      List<Schedule> loadedSchedules = decoded
          .map<Schedule>((scheduleJson) => Schedule.fromJson(scheduleJson))
          .toList();

      setState(() {
        schedules = loadedSchedules;
        _isSelected = List.generate(schedules.length, (_) => false);
      });

      logger.i("Schedules loaded from SharedPreferences");
    } else {
      logger.w("No schedules found in SharedPreferences.");
      fetchSchedulesAPI(); // Fallback to API if no cached data
    }
  }

  Future<void> _addScheduleAPI(String scheduleName, List<String> day,
      List<Map<String, dynamic>> actions) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('accessToken')!;
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse('http://$baseUrl/schedule/add');
    // Collect selected days and relay actions

    String timeString = formatTimeOfDay(selectedTime);

    Map<String, dynamic> requestBody = {
      "schedule_name": _nameController.text,
      "day": day,
      "time": timeString,
      "actions": actions,
    };

    try {
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        logger.i("Schedule added successfully");
        await fetchSchedulesAPI(); // Fetch updated schedules after adding
      } else {
        logger.w("Failed to add schedule: ${response.body}");
      }
    } catch (e) {
      logger.e("Error adding schedule: $e");
    }
  }

  TimeOfDay parseTimeString(String time) {
    try {
      // Split the time string by ':'
      final parts = time.split(':');
      if (parts.length != 2) throw const FormatException();

      // Parse hours and minutes as integers
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Validate hour and minute ranges
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        throw const FormatException("Invalid hour or minute range.");
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      throw FormatException("Invalid time format: $time");
    }
  }

  void _editSchedule(int index) async {
    selectedRelays.clear();
    indexScheduleEdit = index;

    await fetchRelaysAPI();

    // Set name
    _nameController.text = schedules[index].name;

    // Set selected days
    _selectedDays = {
      for (var day in _days) day: schedules[index].day.contains(day)
    };

    // Set time
    selectedTime = parseTimeString(schedules[index].time);

    for (int i = 0; i < relays.length; i++) {
      Action? relayAction = schedules[index].actions.firstWhere(
            (action) => action.relayId == int.tryParse(relays[i].id),
            orElse: () =>
                Action(relayId: int.parse(relays[i].id), action: "OFF"),
          );

      relays[i].isSetChedule = (relayAction.action == "ON");
      _isSelectedRelays[i] = schedules[index]
          .actions
          .any((action) => action.relayId == int.tryParse(relays[i].id));
    }

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              title: const Center(
                // Center the title text
                child: Text(
                  "Edit Schedule",
                  style: TextStyle(
                    fontSize: 20, // Set the font size
                    fontWeight: FontWeight.w600, // Semi-bold font weight
                    color: Color.fromARGB(255, 80, 73, 73), // Text color
                    letterSpacing: 1.2, // Letter spacing for readability
                    fontFamily: 'avenir', // Use a custom font family (optional)
                  ),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildNewNameField(setState),
                    const SizedBox(height: 12),
                    _buildNewDaysSelection(setState),
                    const SizedBox(height: 12),
                    _buildNewTimeSelector(setState),
                    const SizedBox(height: 12),
                    _buildNewRelaysSelection(setState),
                  ],
                ),
              ),
              actions: _buildNewDialogActions(setState),
            );
          },
        );
      },
    );
  }

  Widget _buildNewNameField(StateSetter setState) {
    return TextField(
      controller: _nameController,
      decoration: InputDecoration(
        hintText: 'Eg: Relay-a',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _nameError ? Colors.red : Colors.grey),
        ),
        errorText: _nameError ? _errorMessage : null,
      ),
      onChanged: (value) {
        setState(() {
          _nameError = false;
          _errorMessage = '';
        });
      },
    );
  }

  Widget _buildNewDaysSelection(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select new days:",
          style: TextStyle(
            fontSize: 15, // Set the font size
            fontWeight: FontWeight.w600, // Semi-bold font weight
            color: Color.fromARGB(255, 80, 73, 73), // Text color
            letterSpacing: 1.2, // Letter spacing for readability
            fontFamily: 'avenir', // Use a custom font family (optional)
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _days.map((day) {
              String abbreviation = day.substring(0, 3); // Get first 3 letters
              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: FilterChip(
                  label: Text(
                    abbreviation,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        // fontSize: 20,
                        color: Colors.white,
                        fontFamily: 'avenir'),
                  ),
                  selected: _selectedDays[day]!,
                  showCheckmark: false,
                  selectedColor: const Color.fromARGB(255, 29, 113, 181),
                  backgroundColor: const Color.fromARGB(255, 200, 200, 200),
                  onSelected: (value) {
                    setState(() => _selectedDays[day] = value);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNewTimeSelector(StateSetter setState) {
    return ListTile(
      title: Text(
          "New time: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, "0")}"),
      trailing: const Icon(Icons.access_time),
      onTap: () {
        // Show a dialog to pick the time using NumberPicker
        showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  title: const Text("Pick Time"),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Hour Picker
                            NumberPicker(
                              value: selectedTime.hour,
                              minValue: 0,
                              maxValue: 23,
                              step: 1,
                              onChanged: (value) {
                                setStateDialog(() {
                                  selectedTime = TimeOfDay(
                                    hour: value,
                                    minute: selectedTime.minute,
                                  );
                                });
                              },
                            ),
                            const Text(":", style: TextStyle(fontSize: 32)),
                            // Minute Picker
                            NumberPicker(
                              value: selectedTime.minute,
                              minValue: 0,
                              maxValue: 59,
                              step: 1,
                              onChanged: (value) {
                                setStateDialog(() {
                                  selectedTime = TimeOfDay(
                                    hour: selectedTime.hour,
                                    minute: value,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 90, 80,
                            80), // Changed 'primary' to 'backgroundColor'
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 10, // Set the font size
                          fontWeight: FontWeight.w600, // Semi-bold font weight
                          color: Colors.white, // Text color
                          letterSpacing: 1.2, // Letter spacing for readability
                          fontFamily:
                              'avenir', // Use a custom font family (optional)
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 116, 143,
                            190), // Changed 'primary' to 'backgroundColor'
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "OK",
                        style: TextStyle(
                          fontSize: 10, // Set the font size
                          fontWeight: FontWeight.w600, // Semi-bold font weight
                          color: Colors.white, // Text color
                          letterSpacing: 1.2, // Letter spacing for readability
                          fontFamily:
                              'avenir', // Use a custom font family (optional)
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNewRelaysSelection(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select desired relay states:",
          style: TextStyle(
            fontSize: 15, // Set the font size
            fontWeight: FontWeight.w600, // Semi-bold font weight
            color: Color.fromARGB(255, 80, 73, 73), // Text color
            letterSpacing: 1.2, // Letter spacing for readability
            fontFamily: 'avenir', // Use a custom font family (optional)
          ),
        ),
        ...relays.asMap().entries.map((entry) {
          int index = entry.key;
          var relay = entry.value;

          // Define the background color based on relay selection
          Color backgroundColor = _isSelectedRelays[index]
              ? const Color.fromARGB(255, 5, 74, 131)
              : const Color.fromARGB(255, 207, 202, 202);

          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 6.0,
              horizontal: 8.0,
            ), // Add vertical and horizontal padding
            child: GestureDetector(
              onTap: () {
                setState(() {
                  // Toggle selection state when the entire item is tapped
                  _isSelectedRelays[index] = !_isSelectedRelays[index];
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor, // Set background color dynamically
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                  ), // Padding inside the ListTile
                  title: Text(
                    relay.name,
                    style: const TextStyle(
                      fontSize: 15, // Set the font size
                      fontWeight: FontWeight.w600, // Semi-bold font weight
                      color: Color.fromARGB(255, 251, 251, 251), // Text color
                      letterSpacing: 1.2, // Letter spacing for readability
                      fontFamily:
                          'avenir', // Use a custom font family (optional)
                    ),
                  ),
                  trailing: Switch(
                    value: relay.isSetChedule,
                    activeTrackColor: Colors
                        .blue, // Custom color for the active track (background)
                    inactiveThumbColor: const Color.fromARGB(255, 222, 213,
                        213), // Custom color for the "off" thumb (circle)
                    inactiveTrackColor: const Color.fromARGB(255, 235, 232,
                        232), // Custom color for the "off" track (background)
                    onChanged: (bool value) {
                      setState(() {
                        relay.isSetChedule = value;
                      });
                    },
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  List<Widget> _buildNewDialogActions(StateSetter setState) {
    bool isNewName =
        (_nameController.text == schedules[indexScheduleEdit].name);
    return [
      ElevatedButton(
        onPressed: () async {
          if (schedules
                  .any((schedule) => schedule.name == _nameController.text) &&
              !isNewName) {
            setState(() {
              _nameError = true;
              _errorMessage = 'Schedule name already exists!';
            });
          } else {
            _nameError = false;
            selectedRelays = relays
                .where((relay) =>
                    _isSelectedRelays[relays.indexOf(relay)] &&
                    !selectedRelays.contains(relay))
                .toList();

            String relayName = _nameController.text;
            List<Map<String, dynamic>> action = selectedRelays.map((relay) {
              return {
                "relayId": relay.id,
                "action": relay.isSetChedule ? "ON" : "OFF"
              };
            }).toList();
            List<String> selectedDaysList = _selectedDays.entries
                .where((entry) => entry.value)
                .map((entry) => entry.key)
                .toList();
            String timeString = formatTimeOfDay(selectedTime);

            await editScheduleAPI(schedules[indexScheduleEdit].id, relayName,
                selectedDaysList, timeString, action);
            // ignore: use_build_context_synchronously
            Navigator.of(context).pop();
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Schedule is edited")),
            );
          }
        },
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 93, 128, 187),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: const Text(
          'Update',
          style: TextStyle(
            fontSize: 10, // Set the font size
            fontWeight: FontWeight.w600, // Semi-bold font weight
            color: Colors.white, // Text color
            letterSpacing: 1.2, // Letter spacing for readability
            fontFamily: 'avenir', // Use a custom font family (optional)
          ),
        ),
      ),
      ElevatedButton(
        onPressed: () {
          _nameController.clear();
          _nameError = false;
          _errorMessage = '';
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 185, 163, 163),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: const Text(
          'Cancel',
          style: TextStyle(
            fontSize: 10, // Set the font size
            fontWeight: FontWeight.w600, // Semi-bold font weight
            color: Colors.white, // Text color
            letterSpacing: 1.2, // Letter spacing for readability
            fontFamily: 'avenir', // Use a custom font family (optional)
          ),
        ),
      ),
    ];
  }

  String formatTimeOfDay(TimeOfDay time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> fetchRelaysAPI() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('accessToken')!;
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse('http://$baseUrl/relay/get');
    try {
      var response = await http.get(url, headers: {
        'Authorization': 'Bearer $token', // Update with your token
      });

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);

        // Check if responseData is a list, otherwise handle empty or unexpected response
        if (responseData is List<dynamic>) {
          List<Relay> fetchedRelays = responseData.map((relay) {
            return Relay(
              id: relay['relay_id'].toString(), // Use 'relay_id'
              name: relay['relay_name'],
              isOn: relay['state'], // Use 'state' for relay status
            );
          }).toList();

          setState(() {
            relays = fetchedRelays; // Update UI with fetched relays
            _isSelectedRelays = List.generate(relays.length, (index) => false);
          });
        } else {
          // If it's not a list, handle it accordingly (e.g., no data)
          setState(() {
            relays = []; // Set relays to an empty list
            _isSelected = [];
          });
          logger.w("Unexpected response format: ${response.body}");
        }
      } else {
        logger.w("Failed to fetch relays: ${response.body}");
      }
    } catch (e) {
      logger.e("Error occurred: $e");
    }
  }

  void _addSchedule() async {
    for (var day in _days) {
      _selectedDays[day] = false;
    }
    _nameController.clear();
    _nameError = false; // Reset error state
    _errorMessage = ''; // Reset error message
    await fetchRelaysAPI();

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text("Add schedule",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildNameField(setState),
                    const SizedBox(height: 12),
                    _buildDaysSelection(setState),
                    const SizedBox(height: 12),
                    _buildTimeSelector(setState),
                    const SizedBox(height: 12),
                    _buildRelaysSelection(setState),
                  ],
                ),
              ),
              actions: _buildDialogActions(setState),
            );
          },
        );
      },
    );
  }

  Widget _buildNameField(StateSetter setState) {
    return TextField(
      controller: _nameController,
      decoration: InputDecoration(
        hintText: 'Name Schedule (required)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: _nameError ? Colors.red : Colors.grey,
          ),
        ),
        errorText: _nameError ? _errorMessage : null,
      ),
      onChanged: (value) {
        setState(() {
          _nameError = false;
          _errorMessage = '';
        });
      },
    );
  }

  Widget _buildDaysSelection(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select days:",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _days.map((day) {
              String abbreviation = day.substring(0, 3); // Get first 3 letters
              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: FilterChip(
                  label: Text(
                    abbreviation,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        // fontSize: 20,
                        color: Colors.white,
                        fontFamily: 'avenir'),
                  ),
                  selected: _selectedDays[day]!,
                  showCheckmark: false,
                  selectedColor: const Color.fromARGB(255, 29, 113, 181),
                  backgroundColor: const Color.fromARGB(255, 200, 200, 200),
                  onSelected: (value) {
                    setState(() => _selectedDays[day] = value);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(StateSetter setState) {
    return ListTile(
      title: Text(
          "Selected time: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, "0")}"),
      trailing: const Icon(Icons.access_time),
      onTap: () {
        // Show a dialog to pick the time using NumberPicker
        showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  title: const Text("Pick Time"),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Hour Picker
                            NumberPicker(
                              value: selectedTime.hour,
                              minValue: 0,
                              maxValue: 23,
                              step: 1,
                              onChanged: (value) {
                                setStateDialog(() {
                                  selectedTime = TimeOfDay(
                                    hour: value,
                                    minute: selectedTime.minute,
                                  );
                                });
                              },
                            ),
                            const Text(":", style: TextStyle(fontSize: 32)),
                            // Minute Picker
                            NumberPicker(
                              value: selectedTime.minute,
                              minValue: 0,
                              maxValue: 59,
                              step: 1,
                              onChanged: (value) {
                                setStateDialog(() {
                                  selectedTime = TimeOfDay(
                                    hour: selectedTime.hour,
                                    minute: value,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 154, 135,
                            135), // Changed 'primary' to 'backgroundColor'
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 10, // Set the font size
                          fontWeight: FontWeight.w600, // Semi-bold font weight
                          color: Colors.white, // Text color
                          letterSpacing: 1.2, // Letter spacing for readability
                          fontFamily:
                              'avenir', // Use a custom font family (optional)
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors
                            .blueAccent, // Changed 'primary' to 'backgroundColor'
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("OK"),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRelaysSelection(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Relays:"),
        ...relays.asMap().entries.map((entry) {
          int index = entry.key;
          var relay = entry.value;
          return ListTile(
            leading: Checkbox(
              value: _isSelectedRelays[index],
              onChanged: (value) {
                setState(() {
                  _isSelectedRelays[index] = value!;
                });
              },
            ),
            title: Text(relay.name),
            subtitle:
                Text("Current state: ${relay.isSetChedule ? "ON" : "OFF"}"),
            trailing: Switch(
              value: relays[index].isSetChedule,
              activeColor: Colors.green,
              onChanged: (bool value) async {
                setState(() {
                  relays[index].isSetChedule = value;
                });
              },
            ),
          );
        }),
      ],
    );
  }

  List<Widget> _buildDialogActions(StateSetter setState) {
    return [
      ElevatedButton(
        onPressed: () async {
          if (_nameController.text.isEmpty) {
            setState(() {
              _nameError = true;
              _errorMessage = 'Please enter schedule name!';
            });
          } else if (schedules
              .any((schedule) => schedule.name == _nameController.text)) {
            setState(() {
              _nameError = true;
              _errorMessage = 'Schedule name already exists!';
            });
          } else {
            setState(() {
              _nameError = false;
            });

            for (int i = 0; i < relays.length; i++) {
              if (_isSelectedRelays[i]) {
                selectedRelays.add(relays[i]);
              }
            }

            String relayName = _nameController.text;
            List<Map<String, dynamic>> action = selectedRelays.map((relay) {
              return {
                "relayId": relay.id,
                "action": relay.isSetChedule ? "ON" : "OFF",
              };
            }).toList();
            List<String> selectedDaysList = _selectedDays.entries
                .where((entry) => entry.value)
                .map((entry) => entry.key)
                .toList();

            await _addScheduleAPI(relayName, selectedDaysList, action);
            // ignore: use_build_context_synchronously
            Navigator.of(context).pop();
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$relayName is relay added")),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 124, 149, 193),
        ),
        child: const Text(
          'Add',
          style: TextStyle(
            fontSize: 10, // Set the font size
            fontWeight: FontWeight.w600, // Semi-bold font weight
            color: Colors.white, // Text color
            letterSpacing: 1.2, // Letter spacing for readability
            fontFamily: 'avenir', // Use a custom font family (optional)
          ),
        ),
      ),
      ElevatedButton(
        onPressed: () {
          // Clear the error state and controllers when cancelling
          _nameController.clear();
          _nameError = false; // Clear error state
          _errorMessage = ''; // Clear error message
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 140, 123, 123),
        ),
        child: const Text(
          'Cancel',
          style: TextStyle(
            fontSize: 10, // Set the font size
            fontWeight: FontWeight.w600, // Semi-bold font weight
            color: Colors.white, // Text color
            letterSpacing: 1.2, // Letter spacing for readability
            fontFamily: 'avenir', // Use a custom font family (optional)
          ),
        ),
      ),
    ];
  }

  void _toggleShowEditIcon() {
    setState(() {
      _showEditIcon = !_showEditIcon;
    });
  }

  void _resetToNormalMode() {
    setState(() {
      _showDeleteIcon = false;
      _showEditIcon = false;
      _selectMode = false;
    });
  }

  Future<void> setScheduleStatusAPI(String scheduleId, bool state) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('accessToken')!;
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse('http://$baseUrl/schedule/set-status');
    try {
      Map<String, dynamic> requestBody = {
        'schedule_id': scheduleId, // Adjusted to match Node.js API
        'state': state, // Adjusted to match Node.js API
      };

      var response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        logger.i("Schedule $scheduleId is ${state ? 'ON' : 'OFF'}");

        // Fetch updated schedule from the server after changing the schedule status
        await fetchSchedulesAPI();
      } else {
        logger.w("Failed to change schedule state: ${response.body}");
      }
    } catch (e) {
      logger.e("Error occurred: $e");
    }
  }

  Future<void> editScheduleAPI(
      String scheduleId,
      String newScheduleName,
      List<String> newDay,
      String newTime,
      List<Map<String, dynamic>> newActions) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('accessToken')!;
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse('http://$baseUrl/schedule/set');
    try {
      Map<String, dynamic> requestBody = {
        'schedule_id': scheduleId,
        'new_schedule_name': newScheduleName,
        'new_day': newDay,
        'new_time': newTime,
        'new_actions': newActions,
      };

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        logger.i("Schedule updated successfully");
        await fetchSchedulesAPI();
      } else {
        // Handle specific errors based on response
        logger.w("Failed to update Schedule: ${response.body}");
      }
    } catch (e) {
      logger.e("Error occurred: $e");
    }
  }

  Future<void> deleteScheduleAPI(String scheduleId) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('accessToken')!;
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse('http://$baseUrl/schedule/delete');
    try {
      Map<String, dynamic> requestBody = {
        'schedule_id': scheduleId,
      };

      var response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        logger.i("SChedule deleted successfully");
        await fetchSchedulesAPI(); // Refresh the list after deletion
      } else {
        logger.w("Failed to delete schedule: ${response.body}");
      }
    } catch (e) {
      logger.e("Error occurred: $e");
    }
  }

  void _deleteSchedule(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete'),
          content: const Text('Are you sure you want to delete this Schedule?'),
          actions: [
            ElevatedButton(
              onPressed: () async {
                String scheduleId = schedules[index].id;
                await deleteScheduleAPI(scheduleId); // Call the API to delete
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Yes'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpeedDial() {
    return SpeedDial(
      icon: _showDeleteIcon || _showEditIcon
          ? Icons.cancel_presentation_rounded
          : Icons.menu_open_rounded,
      backgroundColor: Colors.blueAccent,
      children: [
        SpeedDialChild(
          child: const Tooltip(
            message: 'Add schedule',
            child: Icon(Icons.add, color: Colors.blue),
          ),
          onTap: _addSchedule,
        ),
        SpeedDialChild(
          child: const Tooltip(
            message: 'Delete schedule',
            child: Icon(Icons.delete, color: Colors.blue),
          ),
          onTap: () {
            setState(() {
              _showDeleteIcon = true;
              _showEditIcon = false;
              _selectMode = false;
            });
          },
        ),
        SpeedDialChild(
          child: const Tooltip(
            message: 'Edit schedule',
            child: Icon(Icons.edit, color: Colors.blue),
          ),
          onTap: () {
            setState(() {
              _toggleShowEditIcon();
              _showDeleteIcon = false;
              _selectMode = false;
            });
          },
        ),
      ],
      onOpen: () {
        if (_showDeleteIcon || _showEditIcon) {
          _resetToNormalMode();
        }
      },
    );
  }

  Widget _buildScheduleList() {
    var screenWidth = MediaQuery.of(context).size.width;

    // Determine number of columns based on screen width
    int crossAxisCount = screenWidth > 800 ? 2 : 1;

    // Calculate childAspectRatio for different screen sizes (optional)
    double childAspectRatio = screenWidth > 1350
        ? 7.0
        : screenWidth > 1150
            ? 6.5
            : screenWidth > 950
                ? 5.5
                : screenWidth > 800
                    ? 4.5
                    : 4.0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(), // Bouncing scroll effect
      slivers: [
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return _buildScheduleCard(index); // Build each schedule card
            },
            childCount: schedules.length,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                crossAxisCount, // Number of columns based on screen width
            crossAxisSpacing: 8.0, // Horizontal space between items
            mainAxisSpacing: 8.0, // Vertical space between items
            childAspectRatio: childAspectRatio, // Aspect ratio of each card
          ),
        ),
        // Add extra padding at the bottom (same as before)
        const SliverPadding(
          padding:
              EdgeInsets.only(bottom: 200), // Adjust based on your card height
        ),
      ],
    );
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight), // Set AppBar height
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 255, 255, 255)
            ], 
          ),
        ),
        child: AppBar(
          title: const Text(
            'Schedule'),
          actions: [
            if (_showDeleteIcon || _showEditIcon)
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: _resetToNormalMode,
              ),
          ],
          backgroundColor: Colors
              .transparent, // Set to transparent because gradient is applied to Container
          elevation:
              0, // Remove elevation as the gradient is handling the visual effect
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const Navbar_left(),
      body: Container(
        decoration: backgound_Color(),

        // Set background color of the body here
        child: Stack(
          children: [
            _buildScheduleList(),
            // _buildGridView(crossAxisCount, childAspectRatio),
          ],
        ),
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  Widget _buildScheduleCard(int index) {
    Color backgroundColor = schedules[index].isOn
        ? const Color(0xFF6448FE) // Active state (with gradient)
        : const Color.fromARGB(
            255, 187, 176, 176); // Inactive state (gray color)

    return GestureDetector(
      // onTap: () {
      //   setState(() {
      //     _isTapped = !_isTapped; // Toggle the tapped state
      //   });
      // },
      onTap: () {
        // Call _editSchedule function when the card is tapped
        _editSchedule(index);
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _hoveredIndex = index; // Track the hovered card's index
          });
        },
        onExit: (_) {
          setState(() {
            _hoveredIndex = null; // Reset when the mouse exits the card
          });
        },
        child: TweenAnimationBuilder(
          tween: Tween<double>(
              begin: 1.0,
              end: _hoveredIndex == index || _isTapped ? 1.05 : 1.0),
          duration: const Duration(milliseconds: 150),
          builder: (context, scale, child) {
            return Card(
              elevation: _hoveredIndex == index || _isTapped
                  ? 10
                  : 5, // Elevation change only for the hovered card
              margin: const EdgeInsets.all(8.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              child: Transform.scale(
                scale: scale, // Apply scaling animation
                child: Container(
                  decoration: BoxDecoration(
                    gradient: schedules[index].isOn
                        ? const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 6, 33, 83),
                              Color.fromARGB(255, 11, 9, 160)
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null, // No gradient if inactive
                    color: !schedules[index].isOn
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
                        _selectMode
                            ? Checkbox(
                                value: _isSelected[index],
                                onChanged: (value) {
                                  setState(() => _isSelected[index] = value!);
                                },
                              )
                            : const Icon(
                                Icons.timer_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                        const SizedBox(
                            width:
                                8), // Space between icon/checkbox and next column

                        // Second Column: Name, ID, Status
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                schedules[index].name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontFamily: 'avenir',
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              _buildScheduleSubtitle(
                                  index), // Displays ID and Status
                            ],
                          ),
                        ),
                        const SizedBox(width: 8), // Space between columns

                        // Third Column: Day and Time Info (centered)
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: SizedBox(
                              width: 200,
                              child: _buildDayAndTimeInfo(index),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8), // Space between columns

                        // Fourth Column: Trailing Actions
                        Expanded(
                          flex: 2,
                          child: _buildScheduleTrailingActions(index),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Center _buildScheduleTrailingActions(int index) {
    return Center(
      // Center the Row
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
        children: [
          if (_showDeleteIcon)
            IconButton(
              icon: const Icon(Icons.delete,
                  color: Color.fromARGB(255, 237, 230, 230)),
              onPressed: () => _deleteSchedule(index),
            ),
          if (!_showDeleteIcon &&
              !_showEditIcon) // Don't show Switch in delete, select, and adHome mode
            Switch(
              value: schedules[index].isOn,
              activeTrackColor:
                  Colors.blue, // Custom color for the active track (background)
              inactiveThumbColor: const Color.fromARGB(255, 226, 222,
                  222), // Custom color for the "off" thumb (circle)
              inactiveTrackColor:
                  Colors.grey, // Custom color for the "off" track (background)
              activeColor: Colors.white,
              onChanged: (bool value) async {
                setState(() {
                  schedules[index].isOn = value;
                });
                await setScheduleStatusAPI(schedules[index].id, value);
              },
            ),
          if (_showEditIcon)
            IconButton(
              icon: const Icon(Icons.edit,
                  color: Color.fromARGB(255, 230, 231, 233)),
              onPressed: () {
                _editSchedule(index);
              },
            ),
        ],
      ),
    );
  }

// Helper function to build day and time info
  Widget _buildDayAndTimeInfo(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Day: ${getDayAbbreviation(schedules[index].day)}",
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(color: Colors.white, fontFamily: 'avenir'),
        ),
        const SizedBox(height: 9),
        Text(
          "Time: ${schedules[index].time}",
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(
              color: Colors.white,
              fontFamily: 'avenir',
              fontSize: 15,
              fontWeight: FontWeight.w100),
        ),
      ],
    );
  }

  String getDayAbbreviation(List<String> days) {
    Map<String, String> dayAbbreviations = {
      'Monday': 'Mo',
      'Tuesday': 'Tu',
      'Wednesday': 'We',
      'Thursday': 'Th',
      'Friday': 'Fr',
      'Saturday': 'Sa',
      'Sunday': 'Su'
    };

    List<String> abbreviations = days
        .map((day) => dayAbbreviations[day] ?? '')
        .where((abbr) => abbr.isNotEmpty)
        .toList();

    return abbreviations.isNotEmpty
        ? abbreviations.map((abbr) => '[$abbr]').join('')
        : 'No valid days';
  }

  Column _buildScheduleSubtitle(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ID: ${schedules[index].id}',
          style: const TextStyle(color: Colors.white, fontFamily: 'avenir'),
        ),
      ],
    );
  }
}