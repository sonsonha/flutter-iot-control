import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const CustomCard({super.key, this.color, this.padding, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(16.0),
          ),
          color: color ?? const Color.fromARGB(237, 255, 255, 255),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(12.0),
          child: child,
        ));
  }
}

// ignore: non_constant_identifier_names
BoxDecoration backgound_Color() {
  return const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color.fromARGB(255, 0, 94, 255),
        Color.fromARGB(255, 38, 255, 0),
        Color.fromARGB(255, 255, 187, 0),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}


class DividerWithText extends StatelessWidget {
  const DividerWithText({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Expanded(
          child: Divider(
            thickness: 1, // Độ dày của dòng
            color: Colors.grey, // Màu của dòng
            indent: 10.0, // Khoảng cách từ dòng đến cạnh bên trái
            endIndent: 5.0, // Khoảng cách từ dòng đến chữ "or"
          ),
        ),
        Text("or", style: TextStyle(color: Colors.grey)),
        Expanded(
          child: Divider(
            thickness: 1,
            color: Colors.grey,
            indent: 10.0,
            endIndent: 10.0,
          ),
        ),
      ],
    );
  }
}