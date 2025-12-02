// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend_daktmt/apis/apis_login.dart';
import 'package:frontend_daktmt/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ================= NÚT MENU MOBILE =================
class navbarleft_set extends StatelessWidget {
  const navbarleft_set({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return isMobile
        ? Positioned(
            top: 30,
            left: 10,
            child: Builder(
              builder: (context) => Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ),
          )
        : const SizedBox();
  }
}

// ================= DRAWER CHÍNH =================
class Navbar_left extends StatelessWidget {
  const Navbar_left({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Drawer(
      backgroundColor: Colors.blue.shade50,
      child: Column(
        children: [
          // ===== HEADER (LOGO + TÊN APP) =====
          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo BKU
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/mylogoBKU.png',
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                // Tên app
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'SMART CABINET',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Industrial Control Panel',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ===== KHỐI "CHỌN TỦ / TỦ HIỆN TẠI" (RIÊNG, NGAY DƯỚI HEADER) =====
          const _CabinetDrawerSection(),

          // ===== MENU ITEMS =====
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _drawerItem(
                  context,
                  icon: Icons.home,
                  title: 'Home',
                  route: '/home',
                ),
                _drawerItem(
                  context,
                  icon: Icons.history,
                  title: 'History',
                  route: '/history',
                ),
                _drawerItem(
                  context,
                  icon: Icons.power,
                  title: 'Relay',
                  route: '/relay',
                ),
                _drawerItem(
                  context,
                  icon: Icons.schedule,
                  title: 'Schedule',
                  route: '/schedule',
                ),
                _drawerItem(
                  context,
                  icon: Icons.person,
                  title: 'Profile',
                  route: '/profile',
                ),
                _drawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Setting',
                  route: '/setting',
                ),

                const Divider(height: 30),

                // ===== LOGOUT =====
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    final authService = apilogout();
                    bool success = await authService.logoutUser();

                    if (success) {
                      // ignore: use_build_context_synchronously
                      Navigator.pushReplacementNamed(context, '/signin');
                    } else {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sign out successfully!'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // ===== FOOTER =====
          if (!isMobile)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '© 2025 Smart Cabinet',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= DRAWER ITEM BUILDER =================
  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool highlight = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? Colors.blue.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade800),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () {
          Navigator.pushReplacementNamed(context, route);
        },
      ),
    );
  }
}

class _CabinetDrawerSection extends StatefulWidget {
  const _CabinetDrawerSection();

  @override
  State<_CabinetDrawerSection> createState() => _CabinetDrawerSectionState();
}

class _CabinetDrawerSectionState extends State<_CabinetDrawerSection> {
  String? currentCabinetName;

  @override
  void initState() {
    super.initState();
    _loadSelectedCabinet();
  }

  Future<void> _loadSelectedCabinet() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('selectedCabinetName');
    if (mounted) {
      setState(() {
        currentCabinetName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề + icon
          Row(
            children: const [
              Icon(Icons.inventory_2_rounded, color: Colors.white, size: 26),
              SizedBox(width: 8),
              Text(
                'Tủ hiện tại',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            currentCabinetName != null
                ? 'Cabinet: $currentCabinetName'
                : 'Chưa chọn tủ',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),

          // Tên tủ
          // Text(
          //   currentCabinetName ?? 'Cabinet: ${currentCabinetName}',
          //   // currentCabinetName ?? 'Chưa chọn tủ',
          //   maxLines: 1,
          //   overflow: TextOverflow.ellipsis,
          //   style: const TextStyle(
          //     color: Colors.white,
          //     fontSize: 14,
          //   ),
          // ),

          const SizedBox(height: 10),

          // Nút "Quản lý tủ"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade800,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: isDesktop ? 10 : 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.tune),
              label: const Text(
                'Select cabinet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/cabinet');
              },
            ),
          ),
        ],
      ),
    );
  }
}
