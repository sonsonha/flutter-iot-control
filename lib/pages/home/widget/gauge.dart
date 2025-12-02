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

    Color mainColor = label == 'Humidity'
        ? const Color(0xFF2196F3)
        : const Color(0xFFE53935);

    Color annotationColor;
    if (value < 60) {
      annotationColor = Colors.green;
    } else if (value < 75) {
      annotationColor = Colors.yellow;
    } else if (value < 90) {
      annotationColor = Colors.orange;
    } else {
      annotationColor = Colors.red;
    }

    return Column(
      children: [
        // ===== ICON + TITLE =====
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              label == 'Humidity' ? Icons.water_drop : Icons.thermostat,
              color: mainColor,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ===== GAUGE =====
        SizedBox(
          height: 160,
          child: SfRadialGauge(
            axes: <RadialAxis>[
              RadialAxis(
                minimum: 0,
                maximum: 100,
                showTicks: false,
                showLabels: false,
                axisLineStyle: const AxisLineStyle(
                  thickness: 18,
                  cornerStyle: CornerStyle.bothCurve,
                ),
                pointers: <GaugePointer>[
                  RangePointer(
                    value: value,
                    width: 0.18,
                    sizeUnit: GaugeSizeUnit.factor,
                    cornerStyle: CornerStyle.bothCurve,
                    enableAnimation: true,
                    animationDuration: 1200,
                    gradient: SweepGradient(
                      colors: [
                        mainColor.withOpacity(0.3),
                        mainColor,
                      ],
                      stops: const [0.3, 0.9],
                    ),
                  ),
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    angle: 90,
                    positionFactor: 0.1,
                    widget: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: annotationColor,
                          ),
                        ),
                        Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ===== LEGEND =====
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            _LegendDot(color: Colors.green, label: 'Low'),
            _LegendDot(color: Colors.yellow, label: 'Medium'),
            _LegendDot(color: Colors.orange, label: 'High'),
            _LegendDot(color: Colors.red, label: 'Danger'),
          ],
        ),
      ],
    );
  }
}

// ===== LEGEND WIDGET NHỎ GỌN =====
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
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
    required this.value,
  });

  final double gaugeHeight;
  final double gaugeWidth;
  final double value;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GaugeWidget(label: 'Humidity', value: value),
      ),
    );
  }
}

class tempgauge extends StatelessWidget {
  const tempgauge({
    super.key,
    required this.gaugeHeight,
    required this.gaugeWidth,
    required this.value,
  });

  final double gaugeHeight;
  final double gaugeWidth;
  final double value;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GaugeWidget(label: 'Temperature', value: value),
      ),
    );
  }
}
