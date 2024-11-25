import 'package:flutter/material.dart';
import 'package:frontend_daktmt/custom_card.dart';
import 'package:frontend_daktmt/nav_bar/nav_bar_left.dart';
import 'package:frontend_daktmt/pages/setting/ble.dart';
import 'package:frontend_daktmt/pages/upgrade/upgrade.dart';
import 'package:frontend_daktmt/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  String selectedTheme = 'Light';
  String selectedLanguage = 'English';
  String selectedConnection = 'MQTT';
  String selectedUpdate = 'Off';
  String selectedNoitification = 'Off';
  String? token;
  @override
  void initState() {
    super.initState();
    _loadToken(); // Load token when the screen initializes
  }

  // Method to load token from SharedPreferences
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('accessToken');
    });
  }

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
            ? const EdgeInsets.fromLTRB(10, 10, 10, 170)
            : EdgeInsets.fromLTRB(screenWidth * 0.3, 20, screenWidth * 0.3, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container chứa các cài đặt
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 30.0, vertical: 25.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0), // Bo tròn góc
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        // Thay đổi đây để thêm icon vào trước text
                        children: [
                          Icon(
                            Icons.brightness_6,
                            color: Color.fromARGB(255, 145, 145,
                                145), // Chỉnh màu biểu tượng tại đây
                          ), // Biểu tượng trước văn bản
                          SizedBox(
                              width:
                                  8.0), // Khoảng cách giữa biểu tượng và văn bản
                          Text('Theme'),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTheme =
                                (selectedTheme == 'Light') ? 'Dark' : 'Light';
                          });
                        },
                        child: Container(
                          width: 120,
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedTheme,
                                textAlign: TextAlign.center,
                              ),
                              const Icon(Icons.arrow_forward_ios),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  divider_set(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        // Thay đổi đây để thêm icon vào trước text
                        children: [
                          Icon(
                            Icons.language,
                            color: Color.fromARGB(255, 230, 112,
                                112), // Chỉnh màu biểu tượng tại đây
                          ), // Biểu tượng trước văn bản
                          SizedBox(
                              width:
                                  8.0), // Khoảng cách giữa biểu tượng và văn bản
                          Text('Language'),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedLanguage = (selectedLanguage == 'English')
                                ? 'VietNamese'
                                : 'English';
                          });
                        },
                        child: Container(
                          width: 120,
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedLanguage,
                                textAlign: TextAlign.center,
                              ),
                              const Icon(Icons.arrow_forward_ios),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  divider_set(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        // Thay đổi đây để thêm icon vào trước text
                        children: [
                          Icon(
                            Icons.network_check,
                            color: Colors.blue, // Chỉnh màu biểu tượng tại đây
                          ), // Biểu tượng trước văn bản
                          SizedBox(
                              width:
                                  8.0), // Khoảng cách giữa biểu tượng và văn bản
                          Text('Connection'),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedConnection = (selectedConnection == 'MQTT')
                                ? 'WebSocket'
                                : 'MQTT';
                          });
                        },
                        child: Container(
                          width: 120,
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedConnection,
                                textAlign: TextAlign.center,
                              ),
                              const Icon(Icons.arrow_forward_ios),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  divider_set(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        // Thay đổi đây để thêm icon vào trước text
                        children: [
                          Icon(
                            Icons.notification_add,
                            color: Color.fromARGB(255, 48, 48,
                                48), // Chỉnh màu biểu tượng tại đây
                          ), // Biểu tượng trước văn bản
                          SizedBox(
                              width:
                                  8.0), // Khoảng cách giữa biểu tượng và văn bản
                          Text('Noitification'),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedNoitification =
                                (selectedNoitification == 'Off') ? 'On' : 'Off';
                          });
                        },
                        child: Container(
                          width: 120,
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedNoitification,
                                textAlign: TextAlign.center,
                              ),
                              const Icon(Icons.arrow_forward_ios),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  divider_set(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        // Thay đổi đây để thêm icon vào trước text
                        children: [
                          Icon(
                            Icons.system_update,
                            color: Color.fromARGB(255, 0, 255,
                                64), // Chỉnh màu biểu tượng tại đây
                          ), // Biểu tượng trước văn bản
                          SizedBox(
                              width:
                                  8.0), // Khoảng cách giữa biểu tượng và văn bản
                          Text('Software Update'),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const BleDevicePage()),
                          );
                        },
                      ),
                    ],
                  ),
                  divider_set(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        // Thay đổi đây để thêm icon vào trước text
                        children: [
                          Icon(
                            Icons.update,
                            color: Color.fromARGB(255, 255, 0,
                                212), // Chỉnh màu biểu tượng tại đây
                          ), // Biểu tượng trước văn bản
                          SizedBox(
                              width:
                                  8.0), // Khoảng cách giữa biểu tượng và văn bản
                          Text('Upgrade Account'),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const UpgradePage()),
                          );
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
          ],
        ),
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Padding divider_set() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(
        color: Colors.grey,
        height: 0.2,
        thickness: 0.3,
      ),
    );
  }
}
