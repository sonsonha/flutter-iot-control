import 'package:flutter/material.dart';
import 'package:frontend_daktmt/custom_card.dart';
import 'package:frontend_daktmt/nav_bar/nav_bar_left.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_daktmt/apis/api_widget.dart'; // Để sử dụng API_BASE_URL
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString(
        'accessToken')!; // Replace with your actual token fetching logic

    try {
      Map<String, dynamic> data = await fetchProfileData(token);
      setState(() {
        _profileData = data;
      });
    } catch (error) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error fetching profile: $error'),
      ));
    }
  }

  void _showEditDialog() {
    final TextEditingController usernameController =
        TextEditingController(text: _profileData!['username']);
    final TextEditingController emailController =
        TextEditingController(text: _profileData!['email']);
    final TextEditingController phoneController =
        TextEditingController(text: _profileData!['phone_number']);
    final TextEditingController aioController =
        TextEditingController(text: _profileData!['AIO_USERNAME']);
    final TextEditingController aiokeyController =
        TextEditingController(text: _profileData!['AIO_KEY']);
    final TextEditingController wsvController =
        TextEditingController(text: _profileData!['webServerIp']);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: aioController,
                decoration: const InputDecoration(labelText: 'AIO Username'),
              ),
              TextField(
                controller: aiokeyController,
                decoration: const InputDecoration(labelText: 'AIO Key'),
              ),
              TextField(
                controller: wsvController,
                decoration: const InputDecoration(labelText: 'Web Server IP'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Gọi API cập nhật thông tin nếu cần thiết
                _updateProfile(
                  username: usernameController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  aio: aioController.text,
                  aiokey: aiokeyController.text,
                  wsv: wsvController.text,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfile(
      {required String username,
      required String email,
      required String phone,
      required String aio,
      required String aiokey,
      required String wsv}) async {
    // Cập nhật _profileData
    setState(() {
      _profileData!['username'] = username;
      _profileData!['email'] = email;
      _profileData!['phone_number'] = phone;
      _profileData!['AIO_USERNAME'] = aio;
      _profileData!['AIO_KEY'] = aiokey;
      _profileData!['webServerIp'] = wsv;
    });

    // Gọi API để cập nhật thông tin người dùng nếu cần
    // await updateProfileData(token, username, email, phone);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      drawer: const Navbar_left(),
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditDialog,
          ),
        ],
      ),
      body: Container(
        decoration: backgound_Color(),
        padding: EdgeInsets.only(
            top: 20, left: screenWidth * 0.25, right: screenWidth * 0.25),
        child: _profileData == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  _buildProfileCard(),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 5.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    image: _profileData!['coverPhoto'] != null &&
                            _profileData!['coverPhoto']['data'] != null
                        ? DecorationImage(
                            image: MemoryImage(base64Decode(
                                _profileData!['coverPhoto']['data'])),
                            fit: BoxFit.cover,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.2,
                ),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileData!['avatar'] != null &&
                          _profileData!['avatar']['data'] != null
                      ? MemoryImage(
                          base64Decode(_profileData!['avatar']['data']))
                      : null,
                  backgroundColor: Colors.blueAccent,
                  child: _profileData!['avatar'] == null ||
                          _profileData!['avatar']['data'] == null
                      ? Text(
                          _profileData!['username'][0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 40, color: Colors.white),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text(
              _profileData!['fullname'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              _profileData!['webServerIp'],
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const Divider(height: 30),
            _buildProfileItem(
                Icons.person, 'Username', _profileData!['username']),
            _buildProfileItem(Icons.email, 'Email', _profileData!['email']),
            _buildProfileItem(Icons.password, 'Password', '**** ****'),
            _buildProfileItem(
                Icons.phone, 'Phone', _profileData!['phone_number']),
            _buildProfileItem(
                Icons.lock, 'AIO Username', _profileData!['AIO_USERNAME']),
            _buildProfileItem(
                Icons.vpn_key, 'AIO Key', _profileData!['AIO_KEY']),
            _buildProfileItem(
                Icons.computer, 'Web Server IP', _profileData!['webServerIp']),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
    );
  }
}
