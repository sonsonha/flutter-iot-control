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

  final String token;          // hiện tại chưa dùng, nhưng giữ để tránh lỗi chỗ khác
  String label = "Humidity";

  @override
  // ignore: library_private_types_in_public_api
  _ChartState createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  // Nhãn trục Y
  final Map<int, String> leftTitle = const {
    0: '0',
    20: '20',
    40: '40',
    60: '60',
    80: '80',
    100: '100',
  };

  int time = 7;

  Future<List<Map<String, dynamic>>> fetchData() {
    // token hiện tại không dùng ở đây, nhưng vẫn giữ để tương thích
    if (widget.label == 'Humidity') {
      return fetchloghumidata(time);
    } else {
      return fetchlogtempdata(time);
    }
  }

  // nút chọn 7 / 30 / 90 ngày, có highlight ngày đang chọn
  Widget _buildTimeButtons() {
    Widget buildBtn(int value, String text) {
      final bool isSelected = time == value;
      return ElevatedButton(
        onPressed: () {
          if (time != value) {
            setState(() {
              time = value;
            });
          }
        },
        style: ElevatedButton.styleFrom(
          elevation: isSelected ? 2 : 0,
          backgroundColor: isSelected
              ? const Color.fromARGB(255, 17, 163, 212)
              : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: const Color.fromARGB(255, 17, 163, 212)
                  .withOpacity(isSelected ? 0.0 : 0.4),
            ),
          ),
        ),
        child: Text(text),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        buildBtn(7, '7 Days'),
        const SizedBox(width: 10),
        buildBtn(30, '30 Days'),
        const SizedBox(width: 10),
        buildBtn(90, '90 Days'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchData(),
      builder: (context, snapshot) {
        final statusButtons = _buildTimeButtons();

        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
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

        // Lỗi
        if (snapshot.hasError) {
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
                  'Error loading data',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red.shade400,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.width * 0.12),
              ],
            ),
          );
        }

        // Không có dữ liệu
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

        // Tạo list FlSpot từ data
        final List<Map<String, dynamic>> rawData = snapshot.data!;
        final List<FlSpot> spots = rawData.asMap().entries.map((entry) {
          final int index = entry.key;
          final Map<String, dynamic> dataPoint = entry.value;
          final FlSpot originalSpot = dataPoint['spot'];

          // dùng index làm x để spacing đều, y giữ nguyên
          final double xValue = index.toDouble();
          final double yValue = originalSpot.y;

          return FlSpot(xValue, yValue);
        }).toList();

        // Dữ liệu lỗi
        if (spots.any((spot) => spot.y.isNaN || spot.y.isInfinite)) {
          return const Center(child: Text('Invalid data points'));
        }

        // Tính range
        final double maxX =
            spots.map((spot) => spot.x).reduce((a, b) => max(a, b));
        final double minX =
            spots.map((spot) => spot.x).reduce((a, b) => min(a, b));
        double maxY =
            spots.map((spot) => spot.y).reduce((a, b) => max(a, b)) + 10;

        // clamp maxY tối thiểu 20
        if (maxY < 20) maxY = 20;

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
                            final int index = value.toInt();
                            if (index < rawData.length) {
                              final DateTime date = rawData[index]['date'];
                              final String formattedDate =
                                  '${date.day}-${date.month}';

                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 2,
                                child: Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize:
                                        Responsive.isMobile(context) ? 9 : 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          reservedSize: 40,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value == maxY) {
                              return const SizedBox();
                            }
                            final label = leftTitle[value.toInt()];
                            if (label == null) return const SizedBox();
                            return Text(
                              label,
                              style: TextStyle(
                                fontSize:
                                    Responsive.isMobile(context) ? 9 : 12,
                                color: Colors.black87,
                              ),
                            );
                          },
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
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.35),
                              widget.label == 'Humidity'
                                  ? const Color.fromARGB(87, 1, 35, 255)
                                  : const Color.fromARGB(86, 255, 1, 1),
                            ],
                          ),
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
                    maxX: maxX,
                    minY: 0,
                    maxY: maxY,
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
