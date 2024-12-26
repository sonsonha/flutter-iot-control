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
  // ignore: library_private_types_in_public_api
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _historyData = [];
  // Hàm để chọn ngày
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != (isStart ? _startDate : _endDate)) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Hàm tìm kiếm (giả định)
  void _search() async {
    if (_startDate != null && _endDate != null) {
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString(
          'accessToken')!; // Replace with your actual token fetching logic

      try {
        // Fetch data based on the selected dates
        List<Map<String, dynamic>> data =
            await fetchhistorydata(token, _startDate!, _endDate!);
        if (data.isEmpty) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No data found for the selected dates')),
          );
        }
        // Update the state to store the fetched history data
        setState(() {
          _historyData = data;
        });
      } catch (error) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching data: $error'),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time period!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: const Navbar_left(),
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: Container(
        decoration: backgound_Color(),
        padding: isDesktop
            ? EdgeInsets.fromLTRB(screenWidth * 0.2, 10, screenWidth * 0.2, 10)
            : const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0), // Bo góc 8 đơn vị
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6.0,
                offset: Offset(0, 3), // Độ lệch của bóng
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _selectDate(context, true),
                            child: const Text('Start'),
                          ),
                        ),
                        const SizedBox(width: 8), // Spacing between the buttons
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _selectDate(context, false),
                            child: const Text('End'),
                          ),
                        ),
                        const SizedBox(
                            width: 8), // Spacing before the Search button
                        ElevatedButton(
                          onPressed: _search,
                          child: const Text('Search'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16), // Space between rows
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.grey), // Border color and style
                        borderRadius:
                            BorderRadius.circular(8.0), // Rounded corners
                      ),
                      child: isDesktop
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _startDate != null
                                      ? 'Start date: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                      : 'No start date selected',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  _endDate != null
                                      ? 'End date: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                      : 'No end date selected',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _startDate != null
                                        ? 'Start date: ${_startDate!.year}/${_startDate!.month}/${_startDate!.day}'
                                        : 'No start date selected',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(
                                      height: 8), // Space between date texts
                                  Text(
                                    _endDate != null
                                        ? 'End date: ${_endDate!.year}/${_endDate!.month}/${_endDate!.day}'
                                        : 'No end date selected',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _historyData.length, // Use the fetched data
                  itemBuilder: (context, index) {
                    final historyItem =
                        _historyData[index]; // Access each history record
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: isDesktop
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  historyItem['Date'] != null
                                      ? DateFormat('dd/MM/yyyy HH:mm:ss ')
                                          .format(DateTime.parse(
                                                  historyItem['Date'])
                                              .toLocal()) // Parse and format the date
                                      : 'No date',
                                ),
                                Text(historyItem['activity'] ?? 'No activity'),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(historyItem['activity'] ?? 'No activity'),
                                Text(
                                  historyItem['Date'] != null
                                      ? DateFormat('dd/MM/yyyy HH:mm:ss ')
                                          .format(DateTime.parse(
                                                  historyItem['Date'])
                                              .toLocal())
                                      : 'No date',
                                ),
                              ],
                            ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
