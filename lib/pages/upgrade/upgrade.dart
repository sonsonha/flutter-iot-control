import 'package:flutter/material.dart';
import 'package:frontend_daktmt/responsive.dart';

class UpgradePage extends StatelessWidget {
  const UpgradePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Account'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Container(
            width: isMobile
                ? MediaQuery.of(context).size.width
                : MediaQuery.of(context).size.width * 0.4,
            height: isMobile ? 250.0 : MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: AssetImage('assets/cardOCB.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
