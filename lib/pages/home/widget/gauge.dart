import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:frontend_daktmt/custom_card.dart';

class GaugeWidget extends StatelessWidget {
  final String label;
  final double value;
  
  const GaugeWidget({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    String unit = label == 'Humidity' ? '%' : '°C';
  
    // Xác định màu sắc ghi chú dựa trên giá trị
    Color annotationColor;
    if (value < 60) {
      annotationColor = Colors.green; // Giá trị thấp
    } else if (value < 75) {
      annotationColor = Colors.yellow; // Giá trị trung bình thấp
    } else if (value < 90) {
      annotationColor = Colors.orange; // Giá trị trung bình
    } else {
      annotationColor = Colors.red; // Giá trị cao
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  axisLineStyle: const AxisLineStyle(
                    thickness: 15,
                    cornerStyle: CornerStyle.bothCurve,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: value,
                      cornerStyle: CornerStyle.bothCurve,
                      enableAnimation: true,
                      animationDuration: 1200,
                      sizeUnit: GaugeSizeUnit.factor,
                      gradient: SweepGradient(
                        colors: label == 'Humidity'
                            ? <Color>[
                                const Color.fromARGB(255, 0, 132, 255), // Màu nếu giá trị là true
                                const Color.fromARGB(255, 0, 26, 255),
                              ]
                            : <Color>[
                                const Color.fromARGB(255, 184, 113, 113), // Màu nếu giá trị là false
                                const Color.fromARGB(255, 255, 0, 0),
                              ],
                        stops: const <double>[0.25, 0.75],
                      ),
                      width: 0.15,
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          '${value.toStringAsFixed(1)} $unit',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: annotationColor, // Màu chữ
                          ),
                        ),
                      ),
                      angle: 90,
                      positionFactor: 0.8,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 5, top: 5),
          decoration: BoxDecoration(
            color: const Color.fromARGB(162, 243, 243, 243),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 30,
                width: 90,
              ),
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text('Low'),
                ],
              ),
              const SizedBox(height: 5),
              // Dấu chấm và ghi chú cho 'Medium Low'
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.yellow,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text('Med Low'),
                ],
              ),
              const SizedBox(height: 5),
              // Dấu chấm và ghi chú cho 'Medium'
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text('Medium'),
                ],
              ),
              const SizedBox(height: 5),
              // Dấu chấm và ghi chú cho 'High'
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text('High'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ignore: camel_case_types
class humigauge extends StatelessWidget {
  const humigauge({
    super.key,
    required this.gaugeHeight,
    required this.gaugeWidth,
    required this.value, // Thêm thuộc tính value
  });

  final double gaugeHeight;
  final double gaugeWidth;
  final double value; // Giá trị độ ẩm động

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Căn trái cho tất cả
        children: [
          const Text(
            '- Humidity💧-',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: gaugeHeight,
            width: gaugeWidth,
            child: GaugeWidget(label: 'Humidity', value: value),
          ),
        ],
      ),
    );
  }
}

// ignore: camel_case_types
class tempgauge extends StatelessWidget {
  const tempgauge({
    super.key,
    required this.gaugeHeight,
    required this.gaugeWidth,
    required this.value, // Thêm thuộc tính value
  });

  final double gaugeHeight;
  final double gaugeWidth;
  final double value; // Giá trị nhiệt độ động

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Căn trái cho tất cả
        children: [
          const Text(
            '- Temperature🌡️-',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: gaugeHeight,
            width: gaugeWidth,
            child: GaugeWidget(label: 'Temperature', value: value),
          ),
        ],
      ),
    );
  }
}
