import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend_daktmt/custom_card.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

final Logger _logger = Logger();

class CabinetLocation {
  final String id;
  final String name;
  final String? description;
  final String? board;
  final String? deviceId;
  final double? lat;
  final double? lng;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CabinetLocation({
    required this.id,
    required this.name,
    this.description,
    this.board,
    this.deviceId,
    this.lat,
    this.lng,
    this.createdAt,
    this.updatedAt,
  });

  factory CabinetLocation.fromJson(Map<String, dynamic> json) {
    return CabinetLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      board: json['board'] as String?,
      deviceId: json['deviceId'] as String?,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}

class CabinetScreen extends StatefulWidget {
  const CabinetScreen({super.key});

  @override
  State<CabinetScreen> createState() => _CabinetScreenState();
}

class _CabinetScreenState extends State<CabinetScreen> {
  late Future<List<CabinetLocation>> _futureCabinets;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _futureCabinets = _fetchCabinetLocations();
  }

  Future<List<CabinetLocation>> _fetchCabinetLocations() async {
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse('http://$baseUrl/cabinet/locations/all');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      _logger.e('Failed to load cabinet locations: ${response.body}');
      throw Exception('Failed to load cabinet locations');
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final list = (body['data'] as List)
        .map((e) => CabinetLocation.fromJson(e as Map<String, dynamic>))
        .toList();

    return list;
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  Future<void> _showEditCabinetDialog(CabinetLocation cabinet) async {
    final nameController = TextEditingController(text: cabinet.name);
    final descController =
        TextEditingController(text: cabinet.description ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Edit cabinet',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _updateCabinet(
        cabinet.id,
        nameController.text.trim(),
        descController.text.trim(),
      );
    }
  }

  Future<void> _updateCabinet(
    String id,
    String name,
    String description,
  ) async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL']!;
      final url = Uri.parse('http://$baseUrl/cabinet/$id');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null) throw Exception('Not logged in');

      final body = <String, dynamic>{
        'name': name,
        'description': description,
      };

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        _logger.e('Failed to update cabinet: ${response.body}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update cabinet')),
        );
        return;
      }

      setState(() {
        _futureCabinets = _fetchCabinetLocations();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cabinet updated successfully')),
      );
    } catch (e) {
      _logger.e('Error updating cabinet: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating cabinet: $e')),
      );
    }
  }

  Future<void> _onCabinetSelected(CabinetLocation cabinet) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedCabinetId', cabinet.id);
      await prefs.setString('selectedCabinetName', cabinet.name);

      final baseUrl = dotenv.env['API_BASE_URL']!;
      final url = Uri.parse('http://$baseUrl/cabinet/${cabinet.id}/overview');

      final token = prefs.getString('accessToken');
      if (token == null) throw Exception('Not logged in');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        _logger.e('Failed to load cabinet overview: ${response.body}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot load the cabinet data ')),
        );
        return;
      }
      debugPrint('✅ Drawer CabinetName = ${cabinet.name}');

      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      await _saveOverviewToPrefs(jsonData);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _logger.e('Error selecting cabinet: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting cabinet: $e')),
      );
    }
  }

  Future<void> _saveOverviewToPrefs(Map<String, dynamic> jsonData) async {
    final prefs = await SharedPreferences.getInstance();

    dynamic temp = jsonData['temperature'];
    if (temp is String) temp = double.tryParse(temp) ?? 0.0;
    if (temp is num) {
      await prefs.setDouble('temperature', temp.toDouble());
    }

    dynamic hum = jsonData['humidity'];
    if (hum is String) hum = double.tryParse(hum) ?? 0.0;
    if (hum is num) {
      await prefs.setDouble('humidity', hum.toDouble());
    }

    if (jsonData['location'] is String) {
      await prefs.setString('location', jsonData['location'] as String);
    }

    await prefs.setString('relays', json.encode(jsonData['relays'] ?? []));
    await prefs.setString(
        'relays_home', json.encode(jsonData['relays_home'] ?? []));
    await prefs.setString(
        'schedules', json.encode(jsonData['schedules'] ?? []));
    await prefs.setString(
        'schedules_home', json.encode(jsonData['schedules_home'] ?? []));

    await prefs.setString(
        'selectedCabinet', json.encode(jsonData['cabinet'] ?? {}));
  }

Widget _buildCabinetMap(
  List<CabinetLocation> cabinets,
  double centerLat,
  double centerLng,
) {
  final markers = cabinets
      .where((c) => c.lat != null && c.lng != null)
      .map(
        (c) => Marker(
          point: LatLng(c.lat!, c.lng!),
          width: 140,
          height: 70,
          child: GestureDetector(
            onTap: () =>
                _isEditMode ? _showEditCabinetDialog(c) : _onCabinetSelected(c),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isEditMode ? Icons.edit_location_alt : Icons.location_on,
                  size: 34,
                  color: _isEditMode ? Colors.amberAccent : Colors.red,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    c.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      )
      .toList();

  return CustomCard(
    child: LayoutBuilder(
      builder: (context, constraints) {
        // constraints.maxHeight ở đây chính là chiều cao mà Row/Column cấp cho card
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.map, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Text(
                    _isEditMode ? 'Cabinet Map (Edit mode)' : 'Cabinet Map',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${cabinets.length} cabinets',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 👇 phần map dùng Expanded để chiếm hết chiều cao còn lại
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(centerLat, centerLng),
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://api.maptiler.com/maps/basic/{z}/{x}/{y}.png?key=pqZwfqHFA5XexcvOOXeb',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F88F9),
            Color(0xFF5BB6FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: Column(
            children: [
              const Text(
                'Industrial Cabinets',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              if (_isEditMode)
                const Text(
                  'Edit mode',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.amberAccent,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isEditMode ? Icons.done_all : Icons.edit,
                color: _isEditMode ? Colors.amberAccent : Colors.white,
              ),
              tooltip: _isEditMode ? 'Exit edit mode' : 'Edit cabinets',
              onPressed: () {
                setState(() {
                  _isEditMode = !_isEditMode;
                });
              },
            ),
          ],
        ),
        body: FutureBuilder<List<CabinetLocation>>(
          future: _futureCabinets,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error fetching list cabinet:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            final cabinets = snapshot.data ?? [];

            if (cabinets.isEmpty) {
              return const Center(
                child: Text(
                  'Chưa có tủ nào.\nHãy tạo tủ mới trong phần cài đặt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final cWithLocation = cabinets.firstWhere(
              (c) => c.lat != null && c.lng != null,
              orElse: () => cabinets.first,
            );

            final centerLat = cWithLocation.lat ?? 10.7736288;
            final centerLng = cWithLocation.lng ?? 106.6602627;

            return LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth >= 900;

                final mapWidget = Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: _buildCabinetMap(cabinets, centerLat, centerLng),
                );

                Widget listWidget = Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B4F72), Color(0xFF2980B9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 6),
                      itemCount: cabinets.length,
                      itemBuilder: (context, index) {
                        final c = cabinets[index];

                        final createdStr = _formatDate(c.createdAt);
                        final updatedStr = _formatDate(c.updatedAt);

                        return InkWell(
                          onTap: () => _isEditMode
                              ? _showEditCabinetDialog(c)
                              : _onCabinetSelected(c),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isEditMode
                                    ? Colors.amberAccent
                                    : Colors.white.withValues(alpha: 0.25),
                                width: _isEditMode ? 1.4 : 0.9,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              c.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          if (c.board != null &&
                                              c.board!.isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                c.board!,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      if (c.description != null &&
                                          c.description!.isNotEmpty)
                                        Text(
                                          c.description!,
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.85),
                                            fontSize: 12,
                                          ),
                                        ),
                                      if (c.lat != null && c.lng != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2.0),
                                          child: Text(
                                            '(${c.lat!.toStringAsFixed(5)}, ${c.lng!.toStringAsFixed(5)})',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.7),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      if (c.deviceId != null &&
                                          c.deviceId!.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2.0),
                                          child: Text(
                                            'Device: ${c.deviceId}',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.7),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      if (createdStr.isNotEmpty ||
                                          updatedStr.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4.0),
                                          child: Row(
                                            children: [
                                              if (createdStr.isNotEmpty)
                                                Text(
                                                  'Created: $createdStr',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(
                                                            alpha: 0.6),
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              if (createdStr.isNotEmpty &&
                                                  updatedStr.isNotEmpty)
                                                const SizedBox(width: 8),
                                              if (updatedStr.isNotEmpty)
                                                Text(
                                                  'Updated: $updatedStr',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(
                                                            alpha: 0.6),
                                                    fontSize: 10,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _isEditMode
                                      ? Icons.edit_outlined
                                      : Icons.chevron_right,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(flex: 3, child: mapWidget),
                      Expanded(flex: 2, child: listWidget),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      SizedBox(height: 340, child: mapWidget),
                      Expanded(child: listWidget),
                    ],
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
