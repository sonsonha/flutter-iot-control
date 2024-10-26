import 'package:flutter/material.dart';
import 'package:frontend_daktmt/custom_card.dart';
import 'package:frontend_daktmt/nav_bar/nav_bar_left.dart';
import 'package:frontend_daktmt/pages/upgrade/upgrade.dart';
import 'package:frontend_daktmt/responsive.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  String selectedLanguage = 'English';
  String selectedConnection = 'MQTT';

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      drawer: const Navbar_left(),
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Container(
        decoration: backgound_Color(),
        padding: isMobile
            ? const EdgeInsets.fromLTRB(10, 10, 10, 10)
            : EdgeInsets.fromLTRB(
                screenWidth * 0.3, 200, screenWidth * 0.3, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container chứa các cài đặt
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0), // Bo tròn góc
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6.0,
                    offset: Offset(0, 3), // Độ lệch bóng
                  ),
                ],
                border: Border.all(color: Colors.grey.shade300), // Đường viền
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: isDarkMode,
                    onChanged: (bool value) {
                      setState(() {
                        isDarkMode = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Language'),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: DropdownButton<String>(
                          value: selectedLanguage,
                          items: <String>['English', 'Vietnamese']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedLanguage = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Connection'),
                      DropdownButton<String>(
                        value: selectedConnection,
                        items:
                            <String>['MQTT', 'WebSocket'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedConnection = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings saved')),
                        );
                      },
                      child: const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Stack(
                children: [
                  // Hình nền được chứa trong một container
                  Container(
                    width: double.infinity,
                    height: isMobile
                        ? 250.0
                        : 300.0, // Điều chỉnh chiều cao theo màn hình
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(20), // Bo tròn góc cho hình nền
                      image: const DecorationImage(
                        image: AssetImage('assets/cardOCB.png'),
                        fit: BoxFit.cover, // Giúp hình ảnh phủ kín container
                      ),
                    ),
                  ),
                  // Nút "Upgrade Account"
                  Positioned(
                    bottom: isMobile ? 320.0 : 50.0,
                    left: 0, // Căn trái
                    right: 0, // Căn phải
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const UpgradePage()),
                          );
                        },
                        child: const Text('Upgrade Account'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
