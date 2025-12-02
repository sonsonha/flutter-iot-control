import 'package:flutter/material.dart';
import 'package:frontend_daktmt/custom_card.dart';
import 'package:frontend_daktmt/nav_bar/nav_bar_left.dart';
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
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('accessToken');
  }

  // ================= TITLE BAR =================
  Widget _buildSettingsTitleBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, color: Colors.white, size: 30),
          SizedBox(width: 12),
          Text(
            'SETTINGS PAGE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ================= SETTINGS CARD =================
  Widget _buildSettingsCard() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow(
              icon: Icons.brightness_6,
              color: Colors.orangeAccent,
              title: 'Theme',
              value: selectedTheme,
              onTap: () {
                setState(() {
                  selectedTheme =
                      (selectedTheme == 'Light') ? 'Dark' : 'Light';
                });
              },
            ),
            divider_set(),

            _buildRow(
              icon: Icons.language,
              color: Colors.redAccent,
              title: 'Language',
              value: selectedLanguage,
              onTap: () {
                setState(() {
                  selectedLanguage =
                      (selectedLanguage == 'English') ? 'VietNamese' : 'English';
                });
              },
            ),
            divider_set(),

            _buildRow(
              icon: Icons.network_check,
              color: Colors.blue,
              title: 'Connection',
              value: selectedConnection,
              onTap: () {
                setState(() {
                  selectedConnection =
                      (selectedConnection == 'MQTT') ? 'WebSocket' : 'MQTT';
                });
              },
            ),
            divider_set(),

            _buildRow(
              icon: Icons.notifications_active,
              color: Colors.deepPurple,
              title: 'Notification',
              value: selectedNoitification,
              onTap: () {
                setState(() {
                  selectedNoitification =
                      (selectedNoitification == 'Off') ? 'On' : 'Off';
                });
              },
            ),
            divider_set(),

            _buildArrowRow(
              icon: Icons.system_update,
              color: Colors.green,
              title: 'Software Update',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You are on the latest version'),
                  ),
                );
              },
            ),
            divider_set(),

            _buildArrowRow(
              icon: Icons.update,
              color: Colors.pink,
              title: 'Upgrade Account',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UpgradePage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings saved')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ROW WITH VALUE (FULL TAP) =================
  Widget _buildRow({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ================= ROW WITH ARROW (FULL TAP) =================
  Widget _buildArrowRow({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      drawer: const Navbar_left(),
      body: Stack(
        children: [
          Container(decoration: backgound_Color()),
          const navbarleft_set(),

          SafeArea(
            child: isDesktop
                ? Row(
                    children: [
                      SizedBox(width: 260, child: const Navbar_left()),
                      const VerticalDivider(width: 1, thickness: 1),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildSettingsTitleBar(),
                              const SizedBox(height: 16),
                              Expanded(child: _buildSettingsCard()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(
                          height:
                              70, // 👈 chừa khoảng trống để không che nút 3 gạch
                        ),
                        _buildSettingsTitleBar(),
                        const SizedBox(height: 16),
                        Expanded(child: _buildSettingsCard()),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Padding divider_set() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(thickness: 0.4),
    );
  }
}
