import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_daktmt/custom_card.dart';
import 'package:frontend_daktmt/nav_bar/nav_bar_left.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();

class Relay {
  String id;
  String name;
  bool isOn;

  Relay({required this.id, required this.name, this.isOn = false});
}

class RelayScreen extends StatefulWidget {
  const RelayScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RelayScreenState createState() => _RelayScreenState();
}

class _RelayScreenState extends State<RelayScreen> {
  // final bool _isHovered = false; // To detect hover
  final bool _isTapped = false; // To detect tap (for mobile)
  int? _hoveredIndex;
  List<Relay> relays = [];
  List<Relay> homeRelays = [];
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  // bool isTurnOn = false;

  bool _idError = false;
  String _errorMessage = '';

  bool flatToggleSelect = false;

  // bool _selectMode = false;
  List<bool> _isSelected = [];

  bool _showDeleteIcon = false;
  bool _showEditIcon = false;

  bool _isAddToHomeMode = false;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  void fetchInitialData() async {
    // Fetch all relays
    await fetchRelaysAPI();

    List<String> homeRelayIds = await fetchHomeRelays();

    setState(() {
      // Update _isSelected based on whether the relay is already on the home screen
      _isSelected = List.generate(
        relays.length,
        (index) => homeRelayIds.contains(relays[index].id),
      );

      // Also update the homeRelays list for use elsewhere
      homeRelays =
          relays.where((relay) => homeRelayIds.contains(relay.id)).toList();
    });
  }

  Future<List<String>> fetchHomeRelays() async {
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
        List<dynamic> data = jsonDecode(response.body);
        await prefs.setString('relays_home', json.encode(data));
        return data
            .map<String>((relay) => relay['relay_id'].toString())
            .toList();
      } else {
        logger.w("Failed to fetch home relays: ${response.body}");
        return [];
      }
    } catch (e) {
      logger.e("Error occurred: $e");
      return [];
    }
  }

  Future<bool> setRelayToHomeAPI(String relayId, bool relayHome) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('accessToken')!;
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse('http://$baseUrl/relay/set-home');
    try {
      Map<String, dynamic> requestBody = {
        'relay_id': relayId,
        'relay_home': relayHome,
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
        var jsonData = jsonDecode(response.body);
        logger.i(jsonData);
        // Trigger fetchHomeRelays to refresh UI
        await fetchHomeRelays();

        return true;
      } else {
        logger.w("Failed to add relay: ${response.body}");
        return false; // Failed to add relay
      }
    } catch (e) {
      _showAlertDialog("Error: $e");
      return false; // Error occurred, relay not added
    }
  }

  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Alert"),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
          if (mounted) {
            setState(() {
              relays = fetchedRelays; // Update UI with fetched relays
              _isSelected = List.generate(relays.length, (index) => false);
            });
          }
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

  Future<void> addRelayAPI(String relayId, String relayName) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('accessToken')!;
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse('http://$baseUrl/relay/add');
    try {
      Map<String, dynamic> requestBody = {
        'relay_id': relayId,
        'relay_name': relayName,
      };

      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        logger.i("Relay added successfully");

        // Fetch updated relays from the server after adding the new relay
        await fetchRelaysAPI();
      } else {
        logger.w("Failed to add relay: ${response.body}");
      }
    } catch (e) {
      logger.e("Error occurred: $e");
    }
  }

  Future<void> setRelayStatusAPI(String relayId, bool state) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('accessToken')!;
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse('http://$baseUrl/relay/set-status');
    try {
      Map<String, dynamic> requestBody = {
        'relayId': relayId, // Adjusted to match Node.js API
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
        logger.i("Relay $relayId is ${state ? 'ON' : 'OFF'}");
        // isTurnOn = state;
        // Fetch updated relays from the server after changing the relay status
        await fetchRelaysAPI();
      } else {
        logger.w("Failed to change relay state: ${response.body}");
      }
    } catch (e) {
      logger.e("Error occurred: $e");
    }
  }

  Future<void> editRelayAPI(
      String oldRelayId, String relayName, String newRelayId) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('accessToken')!;
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse('http://$baseUrl/relay/set');
    try {
      Map<String, dynamic> requestBody = {
        'relay_id': oldRelayId,
        'relay_name': relayName,
        'new_relay_id': newRelayId,
      };

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // Make sure you have this set up correctly
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        logger.i("Relay updated successfully");
        await fetchRelaysAPI();
      } else {
        // Handle specific errors based on response
        logger.w("Failed to update relay: ${response.body}");
      }
    } catch (e) {
      logger.e("Error occurred: $e");
    }
  }

  Future<void> deleteRelayAPI(String relayId) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('accessToken')!;
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse('http://$baseUrl/relay/delete');
    try {
      Map<String, dynamic> requestBody = {
        'relayId': relayId,
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
        // logger.i("Relay deleted successfully");
        if (mounted) {
          await fetchRelaysAPI(); // Refresh the list after deletion
          await fetchHomeRelays();
        }
      } else {
        logger.w("Failed to delete relay: ${response.body}");
      }
    } catch (e) {
      logger.e("Error occurred: $e");
    }
  }

  // Thêm relay mới
  void _addRelay() {
    _idController.clear();
    _nameController.clear();
    _idError = false; // Reset error state
    _errorMessage = ''; // Reset error message

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Relay'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      hintText: 'Relay ID (required)',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _idError ? Colors.red : Colors.grey,
                        ),
                      ),
                      errorText: _idError ? _errorMessage : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Relay Name (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (_idController.text.isEmpty) {
                      setState(() {
                        _idError = true;
                        _errorMessage = 'Relay ID is required!';
                      });
                    } else if (relays
                        .any((relay) => relay.id == _idController.text)) {
                      setState(() {
                        _idError = true;
                        _errorMessage = 'Relay ID already exists!';
                      });
                    } else {
                      setState(() {
                        _idError = false;
                      });

                      String relayId = _idController.text;
                      String relayName = _nameController.text.isNotEmpty
                          ? _nameController.text
                          : 'Relay-$relayId';

                      await addRelayAPI(relayId, relayName);
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop();
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
                    _idController.clear();
                    _nameController.clear();
                    _idError = false; // Clear error state
                    _errorMessage = ''; // Clear error message
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Delete relays
  // void _deleteRelay(int index) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: const Text('Delete'),
  //         content: const Text('Are you sure you want to delete this relay?'),
  //         actions: [
  //           ElevatedButton(
  //             onPressed: () async {
  //               String relayId = relays[index].id;
  //               await deleteRelayAPI(relayId); // Call the API to delete
  //               // ignore: use_build_context_synchronously
  //               Navigator.of(context).pop();
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.redAccent,
  //             ),
  //             child: const Text('Yes'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.grey,
  //             ),
  //             child: const Text('No'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _toggleSelectMode() {
    setState(() {
      // _isAddToHomeMode = false;
      // _selectMode = !_selectMode;
      flatToggleSelect = !flatToggleSelect;
      _isSelected = List.generate(relays.length, (_) => flatToggleSelect);
    });
  }

  void _toggleDeleteMode() {
    setState(() {
      _showDeleteIcon = !_showDeleteIcon;
      _isAddToHomeMode = false;
      _isSelected = List.generate(relays.length, (_) => false);
    });
  }

  void _toggleAddToHomeMode() {
    setState(() {
      _isAddToHomeMode = !_isAddToHomeMode;
      // _selectMode = false;

      // Initialize _isSelected based on homeRelays, allowing toggle of each selection
      _isSelected = List.generate(
        relays.length,
        (index) => homeRelays.contains(relays[index]),
      );
    });
  }

  void _confirmDeleteRelays() async {
    List<Relay> selectedRelaysDelete = [];
    for (int i = 0; i < relays.length; i++) {
      if (_isSelected[i]) {
        selectedRelaysDelete.add(relays[i]);
      }
    }
    int numDeletedRelay = 0;
    for (var relay in selectedRelaysDelete) {
      String relayId = relay.id;
      await deleteRelayAPI(relayId);
      // selectedRelaysDelete.remove(relay);
      numDeletedRelay++;
    }
    if (numDeletedRelay <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$numDeletedRelay relay deleted")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$numDeletedRelay relays deleted")),
      );
    }
  }

  void _confirmAddToHome() async {
    // Fetch relays already on the home screen
    bool flagRemoveFromHome = false;
    int maxRelaysAllowAddToScreen =
        6; // Maximum relays allowed add to Home screen
    int amountRemoveFromHome = 0;
    List<String> existingHomeRelayIds = await fetchHomeRelays();
    List<Relay> selectedRelays = [];
    List<String> alreadyAddedRelays = [];

    // Collect selected relays and check if they're already added
    for (int i = 0; i < relays.length; i++) {
      if (existingHomeRelayIds.contains(relays[i].id)) {
        alreadyAddedRelays.add(relays[i].name);
      }
      if (_isSelected[i]) {
        selectedRelays.add(relays[i]);
      }
    }

    for (int i = 0; i < relays.length; i++) {
      if (!_isSelected[i] && alreadyAddedRelays.contains(relays[i].name)) {
        flagRemoveFromHome = true;
        bool removeHome = await setRelayToHomeAPI(relays[i].id, false);
        if (removeHome) {
          amountRemoveFromHome++;
          homeRelays.remove(
              relays[i]); // Remove from homeRelays if API call is successful
        }
      }
    }

    if (flagRemoveFromHome) {
      flagRemoveFromHome = false;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('$amountRemoveFromHome relays removed to home screen!')),
      );
      amountRemoveFromHome = 0;
    }

    // Check if adding selected relays exceeds the limit of 4
    if (selectedRelays.length > maxRelaysAllowAddToScreen ||
        existingHomeRelayIds.length == maxRelaysAllowAddToScreen) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max relay add to home is 6')),
      );
    } else {
      // Add each selected relay by calling the API
      int numOfRelaysAdded = 0;
      for (var relay in selectedRelays) {
        if (!alreadyAddedRelays.contains(relay.name)) {
          bool isAdded = await setRelayToHomeAPI(relay.id, true);
          if (isAdded) {
            homeRelays
                .add(relay); // Add to homeRelays if API call is successful
            numOfRelaysAdded++;
          }
        }
      }
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("$numOfRelaysAdded relay added to home screen!")),
      );
    }

    // setState(() {
    //   _selectMode = false; // Disable selection mode
    // });
  }

  void _editRelay(int index) {
    // Reset controllers before showing the dialog
    _idController.clear();
    _nameController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Relay'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      hintText: 'New Relay ID',
                      border: const OutlineInputBorder(),
                      errorText: _idError ? _errorMessage : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'New Relay Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    String newRelayId = _idController.text.trim();
                    String newRelayName = _nameController.text.trim();

                    // If both fields are empty, show error
                    if (newRelayId.isEmpty && newRelayName.isEmpty) {
                      setState(() {
                        _idError = true;
                        _errorMessage = 'Please enter changes!';
                      });
                      return; // Exit early if no changes are made
                    }

                    // Check if the entered ID already exists
                    if (newRelayId.isNotEmpty &&
                        relays.any((relay) => relay.id == newRelayId)) {
                      setState(() {
                        _idError = true;
                        _errorMessage = 'Relay ID already exists!';
                      });
                      return; // Exit if duplicate ID
                    }

                    // If Name field is empty, keep the old name
                    if (newRelayName.isEmpty) {
                      newRelayName = relays[index].name;
                    }
                    logger.i(
                        "Editing relay: ID: $newRelayId, Name: $newRelayName");

                    // Perform async API call to edit the relay
                    await editRelayAPI(
                      relays[index].id, // Old relay ID (current one)
                      newRelayName, // New relay name or old if unchanged
                      newRelayId, // New relay ID or old if unchanged
                    );

                    // Always refresh the list from the server to avoid inconsistencies
                    await fetchRelaysAPI();

                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent),
                  child: const Text('Update'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _idController.clear();
                    _nameController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Navbar_left(),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Container(decoration: backgound_Color()),
          _buildRelayList(),
          if (_isAddToHomeMode)
            Positioned(
              bottom: 20,
              left: 20,
              child: FloatingActionButton.extended(
                onPressed: _confirmAddToHome,
                label: const Text('Add to home'),
                icon: const Icon(Icons.home_work_sharp),
                backgroundColor: Colors.blueAccent,
              ),
            )
          else if (_showDeleteIcon)
            Positioned(
              bottom: 20,
              left: 20,
              child: FloatingActionButton.extended(
                onPressed: _confirmDeleteRelays,
                label: const Text('Delete'),
                icon: const Icon(Icons.delete_sharp),
                backgroundColor: Colors.blueAccent,
              ),
            ),
        ],
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  // Reset everything to normal mode
  void _resetToNormalMode() {
    setState(() {
      _showDeleteIcon = false;
      _showEditIcon = false;
      // _selectMode = false;
      _isAddToHomeMode = false;
    });
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
            ], // Gradient colors
            begin: Alignment.topLeft, // Start point of the gradient
            end: Alignment.bottomRight, // End point of the gradient
          ),
        ),
        child: AppBar(
          title: const Text(
            'Relay',
          ),
          actions: [
            if (_showEditIcon || _isAddToHomeMode)
              IconButton(
                icon: const Icon(Icons.cancel,
                    color: Color.fromARGB(255, 255, 255, 255)),
                onPressed: _resetToNormalMode,
              )
            else if (_showDeleteIcon)
              IconButton(
                icon: const Icon(Icons.check_box_outlined),
                onPressed: _toggleSelectMode,
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

  // AppBar _buildAppBar() {
  //   return AppBar(
  //     title: const Text('Relay', style: TextStyle(fontSize: 24)),
  //     actions: [
  //       if (_showEditIcon || _isAddToHomeMode)
  //         IconButton(
  //           icon: const Icon(Icons.cancel),
  //           onPressed: _resetToNormalMode,
  //         )
  //       else if (_showDeleteIcon)
  //         IconButton(
  //           icon: const Icon(Icons.check_box_outlined),
  //           onPressed: _toggleSelectMode,
  //         ),
  //     ],
  //     backgroundColor: Colors.blueAccent,
  //   );
  // }

  Widget _buildRelayList() {
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

    return relays.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No relays added yet.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addRelay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: const Text('Add Relay'),
                ),
              ],
            ),
          )
        : CustomScrollView(
            physics: const BouncingScrollPhysics(), // Bouncing scroll effect
            slivers: [
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildRelayCard(index); // Build each relay card
                  },
                  childCount: relays.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      crossAxisCount, // Number of columns based on screen width
                  crossAxisSpacing: 8.0, // Horizontal space between items
                  mainAxisSpacing: 8.0, // Vertical space between items
                  childAspectRatio:
                      childAspectRatio, // Aspect ratio of each card
                ),
              ),
              // Add extra padding at the bottom (same as before)
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 200),
              ),
            ],
          );
  }

  Widget _buildRelayCard(int index) {
    bool isAlreadyAddedToHome = homeRelays.contains(relays[index]);
    Color backgroundColor = relays[index].isOn
        ? const Color(0xFF6448FE) // Active state (with gradient)
        : const Color.fromARGB(
            255, 187, 176, 176); // Inactive state (gray color)

    return GestureDetector(
      onTap: () {
        if (_showDeleteIcon || _isAddToHomeMode) {
          setState(() {
            _isSelected[index] = !_isSelected[index];
          });
        } else {
          _editRelay(index);
        }
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
                    gradient: relays[index].isOn
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF6448FE),
                              Color.fromARGB(255, 12, 84, 123)
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null, // No gradient if inactive
                    color: !relays[index].isOn
                        ? backgroundColor
                        : null, // Apply gray if inactive
                    boxShadow: [
                      BoxShadow(
                        color: [
                          const Color.fromARGB(255, 19, 76, 130),
                          const Color(0xFF5FC6FF)
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
                        Icon(
                          isAlreadyAddedToHome
                              ? Icons.home_work_sharp // Icon if already added
                              : Icons.electrical_services_rounded,
                          color: const Color.fromARGB(255, 255, 255, 255),
                          size: 30,
                        ),
                        const SizedBox(
                            width:
                                8), // Space between icon/checkbox and next column

                        // Second Column: Name, ID, Status
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                relays[index].name,
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
                              _buildRelaySubtitle(
                                  index), // Displays ID and Status
                            ],
                          ),
                        ),
                        const SizedBox(width: 8), // Space between columns

                        // Fourth Column: Trailing Actions
                        Expanded(
                          flex: 2,
                          child: _buildRelayTrailingActions(index),
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

  Column _buildRelaySubtitle(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ID: ${relays[index].id}',
          style: const TextStyle(color: Colors.white, fontFamily: 'avenir'),
        ),
      ],
    );
  }

  Center _buildRelayTrailingActions(int index) {
    bool isSelected = _isSelected[index];
    return Center(
      // Center the Row
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
        children: [
          if (_isAddToHomeMode)
            Checkbox(
              value: isSelected, // Reflect current selection state
              onChanged: (bool? value) {
                setState(() {
                  _isSelected[index] =
                      value ?? false; // Allow toggling for all relays
                });
              },
            ),
          if (_showDeleteIcon)
            Checkbox(
              value: isSelected, // Reflect current selection state
              onChanged: (bool? value) {
                setState(() {
                  _isSelected[index] =
                      value ?? false; // Allow toggling for all relays
                });
              },
            ),
          // IconButton(
          //   icon: const Icon(Icons.delete,
          //       color: Color.fromARGB(255, 237, 230, 230)),
          //   onPressed: () => _deleteRelay(index),
          // ),
          if (!_showDeleteIcon &&
              !_isAddToHomeMode &&
              !_showEditIcon) // Don't show Switch in delete, select, and adHome mode
            Switch(
              value: relays[index].isOn,
              activeColor: const Color.fromARGB(255, 252, 252, 252),
              onChanged: (bool value) async {
                setState(() {
                  relays[index].isOn = value;
                });
                await setRelayStatusAPI(relays[index].id, value);
              },
            ),
          if (_showEditIcon)
            IconButton(
              icon: const Icon(Icons.edit,
                  color: Color.fromARGB(255, 230, 231, 233)),
              onPressed: () {
                _editRelay(index);
              },
            ),
        ],
      ),
    );
  }

  SpeedDial _buildSpeedDial() {
    return SpeedDial(
      icon: _showDeleteIcon || _showEditIcon || _isAddToHomeMode
          ? Icons.cancel_presentation_rounded
          : Icons.menu_open_rounded, // Change the icon based on the condition
      backgroundColor: Colors.blueAccent,
      children: [
        SpeedDialChild(
          child: const Tooltip(
            message: 'Add Relay',
            child: Icon(Icons.add, color: Colors.blue),
          ),
          onTap: _addRelay,
        ),
        SpeedDialChild(
          child: const Tooltip(
            message: 'Delete Relay',
            child: Icon(Icons.delete_outline, color: Colors.blue),
          ),
          onTap: () {
            setState(() {
              // _showDeleteIcon = true;
              _showEditIcon = false;
              _isAddToHomeMode = false;
              // _selectMode = false;
              _toggleDeleteMode();
            });
          },
        ),
        SpeedDialChild(
          child: const Tooltip(
            message: 'Add to Home',
            child: Icon(Icons.home_work_sharp, color: Colors.blue),
          ),
          onTap: () {
            setState(() {
              _showDeleteIcon = false;
              _showEditIcon = false;
              _toggleAddToHomeMode();
            });
          },
        ),
        SpeedDialChild(
          child: const Tooltip(
            message: 'Rename',
            child: Icon(Icons.edit_note_sharp, color: Colors.blue),
          ),
          onTap: () {
            setState(() {
              _isAddToHomeMode = false;
              _showEditIcon = true;
              _showDeleteIcon = false;
              // _selectMode = false;
            });
          },
        ),
      ],
      onOpen: () {
        if (_isAddToHomeMode || _showDeleteIcon || _showEditIcon) {
          _resetToNormalMode();
        }
      },
    );
  }
}
