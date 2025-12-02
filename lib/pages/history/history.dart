import 'package:flutter/material.dart';
import 'package:frontend_daktmt/apis/api_history.dart';
import 'package:frontend_daktmt/custom_card.dart';
import 'package:frontend_daktmt/nav_bar/nav_bar_left.dart';
import 'package:frontend_daktmt/responsive.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _historyData = [];

  // ================== INIT: auto load hôm nay ==================
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _startDate = today;
    _endDate = today;

    _loadTodayHistory();
  }

  Future<void> _loadTodayHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) return;

    try {
      final data = await fetchhistorydata(token, _startDate!, _endDate!);
      if (!mounted) return;
      setState(() {
        _historyData = data;
      });
    } catch (_) {
      // Có thể bỏ qua im lặng, user tự ấn Search sau
    }
  }

  // ================== PICK DATE ==================
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final baseDate = (isStart ? _startDate : _endDate) ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: baseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        final onlyDate = DateTime(picked.year, picked.month, picked.day);
        if (isStart) {
          _startDate = onlyDate;
        } else {
          _endDate = onlyDate;
        }
      });
    }
  }

  // ================== SEARCH HISTORY ==================
  void _search() async {
    if (_startDate != null && _endDate != null) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login again.')),
        );
        return;
      }

      try {
        final data = await fetchhistorydata(token, _startDate!, _endDate!);
        if (!mounted) return;

        if (data.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No data found for the selected dates')),
          );
        }

        setState(() {
          _historyData = data;
        });
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $error')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time period!')),
      );
    }
  }

  // ================== TITLE BAR ==================
  Widget _buildHistoryTitleBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, color: Colors.white, size: 30),
          SizedBox(width: 12),
          Text(
            'HISTORY PAGE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ================== DATE PICKER BUTTON ĐẸP ==================
  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final dateText = date != null
        ? DateFormat('dd/MM/yyyy').format(date)
        : 'Select date';

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today, size: 18),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFF1E88E5)),
      ),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dateText,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================== MAIN CARD ==================
  Widget _buildHistoryCard() {
    final startText = _startDate != null
        ? DateFormat('dd/MM/yyyy').format(_startDate!)
        : '...';
    final endText = _endDate != null
        ? DateFormat('dd/MM/yyyy').format(_endDate!)
        : '...';

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Bộ chọn thời gian
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    label: 'Start date',
                    date: _startDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDateButton(
                    label: 'End date',
                    date: _endDate,
                    onTap: () => _selectDate(context, false),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.search, size: 20),
                    label: const Text(
                      'Search',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Hiển thị khoảng ngày
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF1E88E5).withOpacity(0.05),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, color: Color(0xFF1E88E5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected range',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$startText  →  $endText',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Nhanh: Today
                  TextButton.icon(
                    onPressed: () {
                      final now = DateTime.now();
                      final today =
                          DateTime(now.year, now.month, now.day);
                      setState(() {
                        _startDate = today;
                        _endDate = today;
                      });
                      _search();
                    },
                    icon: const Icon(Icons.today, size: 18),
                    label: const Text('Today'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),

            // Danh sách lịch sử
            Expanded(
              child: _historyData.isEmpty
                  ? const Center(child: Text('No history data'))
                  : ListView.builder(
                      itemCount: _historyData.length,
                      itemBuilder: (context, index) {
                        final h = _historyData[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.event_note,
                                color: Colors.blue),
                            title: Text(h['activity'] ?? 'No activity'),
                            subtitle: Text(
                              h['Date'] != null
                                  ? DateFormat('dd/MM/yyyy HH:mm:ss').format(
                                      DateTime.parse(h['Date']).toLocal())
                                  : 'No date',
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }

  // ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      drawer: const Navbar_left(),
      body: Stack(
        children: [
          // Nền
          Container(decoration: backgound_Color()),

          // Icon menu mobile
          const navbarleft_set(),

          SafeArea(
            child: isDesktop
                ? Row(
                    children: [
                      SizedBox(width: 260, child: const Navbar_left()),
                      const VerticalDivider(width: 1, thickness: 1),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildHistoryTitleBar(),
                              const SizedBox(height: 16),
                              Expanded(child: _buildHistoryCard()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(
                            height:
                                70),
                        _buildHistoryTitleBar(),
                        const SizedBox(height: 16),
                        Expanded(child: _buildHistoryCard()),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
