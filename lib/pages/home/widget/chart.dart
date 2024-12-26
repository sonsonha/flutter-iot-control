import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend_daktmt/apis/api_home.dart';
import 'package:frontend_daktmt/responsive.dart';
import 'package:frontend_daktmt/custom_card.dart';

// ignore: must_be_immutable
class Chart extends StatefulWidget {
  Chart({
    super.key,
    required this.token,
    required this.label,
  });

  final String token;
  String label = "Humidity";

  @override
  // ignore: library_private_types_in_public_api
  _ChartState createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  final leftTitle = {
    0: '0',
    20: '20',
    40: '40',
    60: '60',
    80: '80',
    100: '100',
  };

  int time = 7;

  Future<List<Map<String, dynamic>>> fetchData(
      String token, String label, int time) async {
    if (label == 'Humidity') {
      return await fetchloghumidata(token, time);
    } else {
      return await fetchlogtempdata(token, time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchData(widget.token, widget.label, time),
      builder: (context, snapshot) {
        Widget statusButtons = Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  time = 7;
                });
              },
              child: const Text('7 Days'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  time = 30;
                });
              },
              child: const Text('30 Days'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  time = 90;
                });
              },
              child: const Text('90 Days'),
            ),
          ],
        );
        if (snapshot.connectionState == ConnectionState.waiting) {
          // return const Center(child: CircularProgressIndicator());
          return CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label == 'Humidity'
                      ? 'Humidity (%)'
                      : 'Temperature (°C)',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                statusButtons,
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator()),
                SizedBox(height: MediaQuery.of(context).size.width * 0.12),
              ],
            ),
          );
        }
        // Hiển thị loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              Text(
                widget.label == 'Humidity'
                    ? 'Humidity (%)'
                    : 'Temperature (°C)',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              statusButtons,
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label == 'Humidity'
                      ? 'Humidity (%)'
                      : 'Temperature (°C)',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                statusButtons,
                const SizedBox(height: 20),
                Text(
                  time == 30 || time == 90
                      ? 'Need to upgrade account'
                      : 'No data available',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: MediaQuery.of(context).size.width * 0.12),
              ],
            ),
          );
        }
        // Tạo danh sách FlSpot từ dữ liệu
        List<FlSpot> spots = snapshot.data!.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> dataPoint = entry.value;

          // Lấy FlSpot từ dữ liệu
          FlSpot spot = dataPoint['spot'];

          // Truy xuất giá trị x và y từ FlSpot
          double xValue = index.toDouble();

          double yValue = spot.y;

          return FlSpot(xValue, yValue);
        }).toList();
        // Kiểm tra dữ liệu invalid (NaN hoặc Infinity)
        if (spots.any((spot) => spot.y.isNaN || spot.y.isInfinite)) {
          return const Center(child: Text('Invalid data points'));
        }

        // Tính maxX và maxY từ dữ liệu thực tế
        double maxX = spots.map((spot) => spot.x).reduce(max);
        double minX = spots.map((spot) => spot.x).reduce(min);
        double maxY = spots.map((spot) => spot.y).reduce(max) + 10;

        return CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label == 'Humidity'
                    ? 'Humidity (%)'
                    : 'Temperature (°C)',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              statusButtons,
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: Responsive.isMobile(context) ? 9 / 4 : 16 / 6,
                child: LineChart(
                  LineChartData(
                    lineTouchData:
                        const LineTouchData(handleBuiltInTouches: true),
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 20,
                          interval: 1,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            int index = value.toInt();
                            if (index < snapshot.data!.length) {
                              DateTime date = snapshot.data![index]['date'];
                              String formattedDate =
                                  '${date.day}-${date.month}';

                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 2,
                                child: Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize:
                                        Responsive.isMobile(context) ? 9 : 12,
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                              );
                            } else {
                              return const SizedBox();
                            }
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value == maxY) {
                              return const SizedBox(); // Trả về widget rỗng nếu là maxY
                            }
                            return leftTitle[value.toInt()] != null
                                ? Text(
                                    leftTitle[value.toInt()]!,
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.isMobile(context) ? 9 : 12,
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                    ),
                                  )
                                : const SizedBox();
                          },
                          showTitles: true,
                          interval: 20,
                          reservedSize: 40,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: false,
                        curveSmoothness: 0.2,
                        color: widget.label == 'Humidity'
                            ? const Color.fromARGB(87, 1, 35, 255)
                            : const Color.fromARGB(86, 255, 1, 1),
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              // ignore: deprecated_member_use
                              Theme.of(context).primaryColor.withOpacity(0.5),
                              widget.label == 'Humidity'
                                  ? const Color.fromARGB(87, 1, 35, 255)
                                  : const Color.fromARGB(86, 255, 1, 1),
                            ],
                          ),
                          show: true,
                        ),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                            radius: 3,
                            color: widget.label == 'Humidity'
                                ? const Color.fromARGB(255, 1, 86, 255)
                                : const Color.fromARGB(255, 255, 1, 1),
                            strokeWidth: 2,
                            strokeColor: widget.label == 'Humidity'
                                ? const Color.fromARGB(255, 1, 86, 255)
                                : const Color.fromARGB(255, 255, 1, 1),
                          ),
                        ),
                        spots: spots,
                      ),
                    ],
                    minX: minX,
                    maxX: maxX, // Đảm bảo maxX chính xác
                    minY: 0,
                    maxY: maxY, // Đảm bảo maxY chính xác
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
