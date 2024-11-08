// ignore: file_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UpdateOptionsDialog extends StatefulWidget {
  final String token;

  const UpdateOptionsDialog({super.key, required this.token});

  @override
  _UpdateOptionsDialogState createState() => _UpdateOptionsDialogState();
}

class _UpdateOptionsDialogState extends State<UpdateOptionsDialog> {
  String? selectedBoard;
  String version = "";
  String size = ""; // To store version and size
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // _loadversion() is removed because it wasn't doing anything meaningful
  }

  // Fetches version data from the API for the selected board
  Future<void> fetchVersionData() async {
    setState(() {
      isLoading = true;
    });

    final baseUrl = dotenv.env['API_BASE_URL']!;
    try {
      final response = await http.post(
        Uri.parse('http://$baseUrl/firmware/get'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({
          'board': selectedBoard,
        }),
      );
      print(response.statusCode);

      if (response.statusCode == 200) {
        // Parse response as a Map
        final data = json.decode(response.body);
        print(data);
        setState(() {
          version = data['version']?.toString() ?? '';
          size = data['size']?.toString() ?? '';
          isLoading = false;
        });
      } else {
        print(response.statusCode);
        // setState(() {
        //   isLoading = false;
        // });
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Unexpected data format')),
        // );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  Future<void> fetchVersionDownload() async {
    setState(() {
      isLoading = true;
    });

    final baseUrl = dotenv.env['API_BASE_URL']!;
    try {
      final response = await http.post(
        Uri.parse('http://$baseUrl/firmware/download'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({
          'board': selectedBoard,
          'version': version.toString(),
        }),
      );

      setState(() {
        isLoading = false;
      });
      if (response.headers['content-type']?.contains('application/json') ==
          true) {
        final data = json.decode(response.body);
        print(data);
      } else {
        print('Unexpected content type: ${response.headers['content-type']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Unexpected content type: ${response.headers['content-type']}')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> boardOptions = ['Yolo Uno', 'Relay 6ch'];

    return AlertDialog(
      title: const Text("Software Update"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Devices'),
                DropdownButton<String>(
                  hint: const Text(
                    "Select Device",
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                  value: selectedBoard,
                  items: boardOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? boardselected) {
                    setState(() {
                      selectedBoard = boardselected;
                    });
                    if (boardselected != null) {
                      fetchVersionData();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (version.isEmpty)
              const Center(child: Text("No version available"))
            else
              Column(
                children: [
                  Text("Version: $version"),
                  const SizedBox(height: 10),
                  Text("Size: $size"),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      fetchVersionDownload();
                    },
                    child: const Text("Download"),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
