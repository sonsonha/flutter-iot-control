import 'package:flutter/material.dart';
import 'package:frontend_daktmt/responsive.dart';

// ignore: camel_case_types
class noitification_setting extends StatelessWidget {
  const noitification_setting({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final bool isRowLayout = isDesktop;

    return Positioned(
      top: isRowLayout ? 15 : 40,
      right: isRowLayout ? 220 : 70,
      child: Builder(
        builder: (context) => GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              barrierColor: Colors.transparent,
              builder: (BuildContext context) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.8,
                    width: isRowLayout
                        ? 300
                        : MediaQuery.of(context).size.width * 0.9,
                    margin: const EdgeInsets.only(top: 16, right: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text('No new notifications'),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(0, 255, 255, 255)
                  // ignore: deprecated_member_use
                  .withOpacity(0.8), // Màu nền cho box
              borderRadius: BorderRadius.circular(50), // Bo góc box
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5.0,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications,
              color: Color.fromARGB(255, 0, 0, 0), // Màu icon
            ),
          ),
        ),
      ),
    );
  }
}
