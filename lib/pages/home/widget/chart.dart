import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend_daktmt/apis/api_page.dart';
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

  Future<List<FlSpot>> fetchData(String token, String label, int time) async {
    if (label == 'Humidity') {
      return await fetchloghumidata(token, time);
    } else {
      return await fetchlogtempdata(token, time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FlSpot>>(
      future: fetchData(widget.token, widget.label, time),
      builder: (context, snapshot) {
        //! loadings
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No data available');
        }

        List<FlSpot> spots = snapshot.data!;

        if (spots.any((spot) => spot.y.isNaN || spot.y.isInfinite)) {
          return const Text('Invalid data points');
        }

        double maxX = spots.map((spot) => spot.x).reduce(max);
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
              Row(
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
              ),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: Responsive.isMobile(context) ? 9 / 4 : 16 / 6,
                child: LineChart(
                  LineChartData(
                    lineTouchData: const LineTouchData(
                      handleBuiltInTouches: true,
                    ),
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      // ! đang lỗi ở đây

                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 1,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            int index = value.toInt();
                            // Đảm bảo index không vượt quá số lượng dữ liệu
                            if (index < spots.length) {
                              // Lấy giá trị x từ spots và chuyển đổi sang DateTime
                              DateTime date = DateTime.now().subtract(
                                  Duration(days: (spots.length - index)));
                              String formattedDate =
                                  '${date.month}-${date.day}';

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
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return leftTitle[value.toInt()] != null
                                ? Text(
                                    leftTitle[value.toInt()].toString(),
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
                        isCurved: true,
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
                    minX: 0,
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
