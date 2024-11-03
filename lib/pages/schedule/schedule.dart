import 'package:flutter/material.dart';
import 'package:frontend_daktmt/nav_bar/nav_bar_left.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart';

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
  String day;
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
      day: (json['day'] as List<dynamic>).join(', '),
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
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
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
    fetchSchedulesAPI(); // Fetch relays when the screen initializes
    _isSelected = List.generate(
      schedules.length,
      (index) => false,
    );
  }

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

          setState(() {
            schedules = fetchedSchedules;
            _isSelected = List.generate(schedules.length, (_) => false);
          });
          print("Success to fetch schedules");
        } else {
          setState(() {
            relays = [];
            _isSelected = [];
          });
          print("Unexpected response format: ${response.body}");
        }
      } else {
        print("Failed to fetch relays: ${response.body}");
      }
    } catch (e) {
      print("Error occurred: $e");
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
        print("Schedule added successfully");
        await fetchSchedulesAPI(); // Fetch updated schedules after adding
      } else {
        print("Failed to add schedule: ${response.body}");
      }
    } catch (e) {
      print("Error adding schedule: $e");
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
    indexScheduleEdit = index;

    // Set name
    _nameController.text = schedules[index].name;

    // Set selected days
    _selectedDays = {
      for (var day in _days) day: schedules[index].day.contains(day)
    };

    // Set time
    selectedTime = parseTimeString(schedules[index].time);

    await fetchRelaysAPI();

    for (int i = 0; i < relays.length; i++) {
      // Find the action for the current relay, allowing a null result if no match
      Action? relayAction = schedules[index].actions.firstWhere(
            (action) => action.relayId == int.tryParse(relays[i].id),
            orElse: () => Action(
                relayId: int.parse(relays[i].id),
                action: "OFF"), // Provide a default Action if not found
          );

      // Set isSetChedule based on the action's state
      relays[i].isSetChedule = (relayAction.action == "ON");
      _isSelectedRelays[i] = schedules[index]
          .actions
          .any((action) => action.relayId == int.tryParse(relays[i].id));
    }
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Schedule"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildNewNameField(setState),
                    const SizedBox(height: 10),
                    _buildNewDaysSelection(setState),
                    const SizedBox(height: 10),
                    _buildNewTimeSelector(setState),
                    const SizedBox(height: 10),
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
        labelText: "New Schedule name",
        border: OutlineInputBorder(
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

  Widget _buildNewDaysSelection(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select new days:"),
        Wrap(
          children: _days.map((day) {
            return CheckboxListTile(
              title: Text(day),
              value: _selectedDays[day],
              onChanged: (value) {
                setState(() => _selectedDays[day] = value!);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNewTimeSelector(StateSetter setState) {
    return ListTile(
      title: Text("New time: ${selectedTime.format(context)}"),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: selectedTime,
        );
        if (pickedTime != null) {
          setState(() => selectedTime = pickedTime);
        }
      },
    );
  }

  Widget _buildNewRelaysSelection(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select desired relay states:"),
        ...relays.asMap().entries.map((entry) {
          int index = entry.key;
          var relay = entry.value;

          return ListTile(
            leading: Checkbox(
              value: _isSelectedRelays[index],
              onChanged: (bool? value) {
                setState(() {
                  _isSelectedRelays[index] = value ?? false;
                });
              },
            ),
            title: Text(relay.name),
            subtitle:
                Text("Desired state: ${relay.isSetChedule ? "ON" : "OFF"}"),
            trailing: Switch(
              value: relay.isSetChedule,
              activeColor: Colors.green,
              onChanged: (bool value) {
                setState(() {
                  relay.isSetChedule = value;
                });
              },
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
            setState(() {
              _nameError = false;
            });

            for (int i = 0; i < relays.length; i++) {
              if (_isSelectedRelays[i] &&
                  !selectedRelays.any((relay) => relay.id == relays[i].id)) {
                // Check whether the selected relays is added to selectedRelays list or not to add
                selectedRelays.add(relays[i]);
              }
            }

            String relayName = _nameController.text;
            List<Map<String, dynamic>> action = selectedRelays.map((relay) {
              return {
                "relayId": relay.id,
                "action": relay.isSetChedule ? "OFF" : "ON",
              };
            }).toList();
            List<String> selectedDaysList = _selectedDays.entries
                .where((entry) => entry.value)
                .map((entry) => entry.key)
                .toList();

            String timeString = formatTimeOfDay(selectedTime);

            await editScheduleAPI(schedules[indexScheduleEdit].id, relayName,
                selectedDaysList, timeString, action);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Schedule is edited")),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
        ),
        child: const Text('Update'),
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
          backgroundColor: Colors.redAccent,
        ),
        child: const Text('Cancel'),
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
          print("Unexpected response format: ${response.body}");
        }
      } else {
        print("Failed to fetch relays: ${response.body}");
      }
    } catch (e) {
      print("Error occurred: $e");
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
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Add schedule"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildNameField(setState),
                    const SizedBox(height: 10),
                    _buildDaysSelection(setState),
                    const SizedBox(height: 10),
                    _buildTimeSelector(setState),
                    const SizedBox(height: 10),
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
        labelText: "Schedule Name",
        border: OutlineInputBorder(
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
        const Text("Select Days:"),
        Wrap(
          children: _days.map((day) {
            return CheckboxListTile(
              title: Text(day),
              value: _selectedDays[day],
              onChanged: (value) {
                setState(() => _selectedDays[day] = value!);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(StateSetter setState) {
    return ListTile(
      title: Text("Time: ${selectedTime.format(context)}"),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: selectedTime,
        );
        if (pickedTime != null) {
          setState(() => selectedTime = pickedTime);
        }
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
                "action": relay.isSetChedule ? "OFF" : "ON",
              };
            }).toList();
            List<String> selectedDaysList = _selectedDays.entries
                .where((entry) => entry.value)
                .map((entry) => entry.key)
                .toList();

            await _addScheduleAPI(relayName, selectedDaysList, action);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$relayName is relay added")),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
        ),
        child: const Text('Add'),
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
          backgroundColor: Colors.redAccent,
        ),
        child: const Text('Cancel'),
      ),
    ];
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      _isSelected = List.generate(schedules.length, (_) => false);
    });
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
        print("Schedule $scheduleId is ${state ? 'ON' : 'OFF'}");

        // Fetch updated schedule from the server after changing the schedule status
        await fetchSchedulesAPI();
      } else {
        print("Failed to change schedule state: ${response.body}");
      }
    } catch (e) {
      print("Error occurred: $e");
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
        print("Schedule updated successfully");
        await fetchSchedulesAPI();
      } else {
        // Handle specific errors based on response
        print("Failed to update Schedule: ${response.body}");
      }
    } catch (e) {
      print("Error occurred: $e");
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
        print("SChedule deleted successfully");
        await fetchSchedulesAPI(); // Refresh the list after deletion
      } else {
        print("Failed to delete schedule: ${response.body}");
      }
    } catch (e) {
      print("Error occurred: $e");
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
          : Icons.menu_open_rounded, // Change the icon based on the condition
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

  GridView _buildGridView(int crossAxisCount, double childAspectRatio) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        return _buildScheduleCard(index);
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Schedule', style: TextStyle(fontSize: 24)),
      actions: [
        if (_showDeleteIcon || _showEditIcon)
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: _resetToNormalMode,
          ),
      ],
      backgroundColor: Colors.blueAccent,
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 600 ? 2 : 1;
    double childAspectRatio = screenWidth > 600 ? 6.0 : 4.0;

    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const Navbar_left(),
      body: Stack(
        children: [
          _buildGridView(crossAxisCount, childAspectRatio),
        ],
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  Card _buildScheduleCard(int index) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 5, // Height
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: _selectMode
            ? Checkbox(
                value: _isSelected[index],
                onChanged: (value) {
                  setState(() => _isSelected[index] = value!);
                },
              )
            : const Icon(
                Icons.electrical_services_rounded,
                color: Colors.blueAccent,
                size: 30,
              ),
        title:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            schedules[index].name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 10),
          Row(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScheduleSubtitle(index),
              Text("Day: ${schedules[index].day}"),
              Text("Time: ${schedules[index].time}"),
            ],
          ),
        ]),
        // subtitle: _buildRelaySubtitle(index),
        trailing: _buildScheduleTrailingActions(index),
      ),
    );
  }

  Row _buildScheduleTrailingActions(int index) {
    // bool isSelected = _isSelected[index];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showDeleteIcon)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteSchedule(index),
          ),
        if (!_showDeleteIcon &&
            !_showEditIcon) // Don't show Switch in delete, select and adHome mode
          Switch(
            value: schedules[index].isOn,
            activeColor: Colors.green,
            onChanged: (bool value) async {
              setState(() {
                schedules[index].isOn = value;
              });
              await setScheduleStatusAPI(schedules[index].id, value);
            },
          ),
        if (_showEditIcon)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueAccent),
            onPressed: () {
              // fetchInitialAction(index);
              _editSchedule(index);
            },
          ),
      ],
    );
  }

  Column _buildScheduleSubtitle(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ID: ${schedules[index].id}',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          schedules[index].isOn ? 'Status: ON' : 'Status: OFF',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: schedules[index].isOn ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}
