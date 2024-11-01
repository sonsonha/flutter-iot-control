import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend_daktmt/apis/api_page.dart';
import 'package:frontend_daktmt/apis/apis_login.dart';
import 'package:frontend_daktmt/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: camel_case_types
class nabarright_set extends StatefulWidget {
  const nabarright_set({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _nabarright_setState createState() => _nabarright_setState();
}

// ignore: camel_case_types
class _nabarright_setState extends State<nabarright_set> {
  Map<String, dynamic>? profileData; // Lưu dữ liệu profile

  @override
  void initState() {
    super.initState();
    _getToken();
    _loadProfile(); // Gọi hàm để lấy dữ liệu profile từ API
  }

  String? token;

// Lấy token từ SharedPreferences hoặc từ một nguồn khác
  void _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('accessToken'); // Đảm bảo 'your_token_key' đúng
  }

  Future<void> _loadProfile() async {
    try {
      final data = await fetchProfileData(token!);

      setState(() {
        profileData = data;
      });
    } catch (error) {
      logger.e("Error fetching profile: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final bool isRowLayout = isDesktop;

    return Positioned(
      top: isRowLayout ? 14 : 38,
      right: isRowLayout ? 50 : 16,
      child: Builder(
        builder: (context) => GestureDetector(
          onTap: () {
            Scaffold.of(context).openEndDrawer();
          },
          child: Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(143, 255, 255, 255),
              borderRadius: BorderRadius.circular(50),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5.0,
                ),
              ],
            ),
            child: Row(
              children: [
                ClipOval(
                  child: profileData != null &&
                          profileData!['avatar'] != null &&
                          profileData!['avatar']['data'] != null
                      ? Image.memory(
                          base64Decode(profileData!['avatar']['data']),
                          width: 35,
                          height: 35,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/hcmut.png',
                          width: 35,
                          height: 35,
                          fit: BoxFit.cover,
                        ), // Dự phòng hình ảnh
                ),
                SizedBox(width: isRowLayout ? 8 : 0),
                isRowLayout
                    ? const Text(
                        "NguyenTrung",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Container(),
                SizedBox(width: isRowLayout ? 8 : 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: camel_case_types
class Navbar_right extends StatelessWidget {
  final Map<String, dynamic> profileData; // Thêm trường này

  const Navbar_right(
      {super.key,
      required this.profileData}); // Nhận profileData từ constructor

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('NguyenTrung'),
            accountEmail: const Text('trungvodich@gmail.com'),
            currentAccountPicture: CircleAvatar(
              child: ClipOval(
                child: profileData['avatar'] != null &&
                        profileData['avatar']['data'] != null
                    ? Image.memory(
                        base64Decode(profileData['avatar']
                            ['data']), // Hiển thị ảnh từ base64
                        fit: BoxFit.cover,
                      )
                    : Image.asset('assets/hcmut.png'), // Dự phòng hình ảnh
              ),
            ),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 165, 165, 165),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Tests scheduled'),
          ),
          _buildScheduleCard("Mathematics", "On", "Mon"),
          _buildScheduleCard("Physics", "Off", "Wed"),
          _buildScheduleCard("Chemistry", "On", "Fri"),
          _buildScheduleCard("English", "Off", "Sun"),
        ],
      ),
    );
  }
}

Widget _buildScheduleCard(String subject, String status, String day) {
  // ignore: non_constant_identifier_names
  String Subject =
      subject.length > 10 ? "${subject.substring(0, 10)}..." : subject;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            Subject,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            day,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            status,
            style: TextStyle(
              color: status == "On" ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
