import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Cabinet {
  final String id;
  final String name;

  Cabinet({required this.id, required this.name});

  factory Cabinet.fromJson(Map<String, dynamic> json) {
    return Cabinet(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? 'Cabinet',
    );
  }
}

class CabinetSelectorBar extends StatefulWidget {
  final void Function(String cabinetId, String cabinetName)? onCabinetChanged;

  const CabinetSelectorBar({super.key, this.onCabinetChanged});

  @override
  State<CabinetSelectorBar> createState() => _CabinetSelectorBarState();
}

class _CabinetSelectorBarState extends State<CabinetSelectorBar> {
  List<Cabinet> cabinets = [];
  String? selectedCabinetId;
  String? selectedCabinetName;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    selectedCabinetId = prefs.getString('selectedCabinetId');
    selectedCabinetName = prefs.getString('selectedCabinetName');

    await _fetchCabinets();

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _fetchCabinets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null) return;

      final baseUrl = dotenv.env['API_BASE_URL']!;
      final url = Uri.parse('http://$baseUrl/cabinet');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) return;

      final body = json.decode(response.body);
      final list = (body['data'] as List<dynamic>? ?? []);
      cabinets = list.map((e) => Cabinet.fromJson(e)).toList();

      // Nếu chưa có tủ được chọn thì mặc định chọn tủ đầu tiên
      if (cabinets.isNotEmpty && selectedCabinetId == null) {
        final first = cabinets.first;
        selectedCabinetId = first.id;
        selectedCabinetName = first.name;

        await prefs.setString('selectedCabinetId', first.id);
        await prefs.setString('selectedCabinetName', first.name);

        widget.onCabinetChanged?.call(first.id, first.name);
      }
    } catch (e) {
      // Có thể log nếu cần
      // print('Error fetch cabinets: $e');
    }
  }

  Future<void> _onChanged(String? newId) async {
    if (newId == null) return;
    if (cabinets.isEmpty) return;

    final selected = cabinets.firstWhere(
      (c) => c.id == newId,
      orElse: () => cabinets.first,
    );

    final prefs = await SharedPreferences.getInstance();
    selectedCabinetId = selected.id;
    selectedCabinetName = selected.name;
    await prefs.setString('selectedCabinetId', selected.id);
    await prefs.setString('selectedCabinetName', selected.name);

    if (mounted) {
      setState(() {});
    }

    widget.onCabinetChanged?.call(selected.id, selected.name);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: const [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Đang tải danh sách tủ...'),
          ],
        ),
      );
    }

    if (cabinets.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: const [
            Icon(Icons.inventory_2_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(child: Text('Chưa có tủ nào, hãy tạo tủ mới.')),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hàng trên: label + dropdown
          Row(
            children: [
              const Icon(
                Icons.inventory_2_rounded,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 8),
              const Text(
                'Select cabinet to monitor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCabinetId,
                    items: cabinets
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _onChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Selected cabinet: ${selectedCabinetName ?? 'Not selected'}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
