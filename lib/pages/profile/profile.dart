import 'package:flutter/material.dart';
import 'package:frontend_daktmt/custom_card.dart';
import 'package:frontend_daktmt/nav_bar/nav_bar_left.dart';
import 'package:frontend_daktmt/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_daktmt/apis/api_page.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool isEditing = false;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController aioController = TextEditingController();
  final TextEditingController aiokeyController = TextEditingController();
  final TextEditingController wsvController = TextEditingController();
  final TextEditingController newpasswordController = TextEditingController();
  final TextEditingController currentpasswordController =
      TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();
  bool isPasswordEdited = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('accessToken') ?? '';

    try {
      Map<String, dynamic> data = await fetchProfileData(token);
      setState(() {
        _profileData = data;
        usernameController.text = data['username'] ?? '';
        emailController.text = data['email'] ?? '';
        phoneController.text = data['phone_number'] ?? '';
        aioController.text = data['AIO_USERNAME'] ?? '';
        aiokeyController.text = data['AIO_KEY'] ?? '';
        wsvController.text = data['webServerIp'] ?? '';
        newpasswordController.text = '**** ****';
        currentpasswordController.text = '';
      });
    } catch (error) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile: $error')),
      );
    }
  }
  
  

  Future<void> _updateProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('accessToken') ?? '';
      await fetchEditProfile(
          token,
          usernameController.text,
          emailController.text,
          phoneController.text,
          aioController.text,
          aiokeyController.text,
          wsvController.text,
          newpasswordController.text,
          currentpasswordController.text);

      setState(() {
        _profileData?['username'] = usernameController.text;
        _profileData?['email'] = emailController.text;
        _profileData?['phone_number'] = phoneController.text;
        _profileData?['AIO_USERNAME'] = aioController.text;
        _profileData?['AIO_KEY'] = aiokeyController.text;
        _profileData?['webServerIp'] = wsvController.text;
        isEditing = false;
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = Responsive.isDesktop(context);
    final bool isRowLayout = isDesktop;
    return Scaffold(
      drawer: const Navbar_left(),
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(
              isEditing ? Icons.check : Icons.edit,
              color: Colors.green,
            ),
            onPressed: () {
              if (isEditing) {
                _showPasswordDialog(context);
              } else {
                setState(() {
                  isEditing = true; // Enable editing when Edit is pressed
                });
              }
            },
          ),
          if (isEditing) // Hiển thị nút "X" chỉ khi đang ở chế độ chỉnh sửa
            IconButton(
              icon: const Icon(
                Icons.clear,
                color: Colors.red,
              ), // Biểu tượng "X"
              onPressed: () {
                setState(() {
                  isEditing = false;
                });
              },
            ),
        ],
      ),
      body: Container(
        decoration: backgound_Color(),
        padding: isRowLayout
            ? EdgeInsets.only(
                top: 20, left: screenWidth * 0.25, right: screenWidth * 0.25)
            : const EdgeInsets.only(top: 20, left: 5, right: 5),
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
                    image: _profileData?['coverPhoto']?['data'] != null
                        ? DecorationImage(
                            image: MemoryImage(
                              base64Decode(_profileData!['coverPhoto']['data']),
                            ),
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
                  backgroundImage: _profileData?['avatar']?['data'] != null
                      ? MemoryImage(
                          base64Decode(_profileData!['avatar']['data']),
                        )
                      : null,
                  backgroundColor: Colors.blueAccent,
                  child: (_profileData?['avatar'] == null ||
                          _profileData?['avatar']['data'] == null)
                      ? Text(
                          (_profileData?['username']?[0] ?? 'N/A')
                              .toUpperCase(),
                          style: const TextStyle(
                              fontSize: 40, color: Colors.white),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            _buildEditableProfileItem(usernameController, 'Username'),
            _buildEditableProfileItem(emailController, 'Email'),
            _buildEditableProfileItem(newpasswordController, 'Password'),
            _buildEditableProfileItem(phoneController, 'Phone'),
            _buildEditableProfileItem(aioController, 'AIO Username'),
            _buildEditableProfileItem(aiokeyController, 'AIO Key'),
            _buildEditableProfileItem(wsvController, 'Web Server IP'),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableProfileItem(
    TextEditingController controller,
    String label,
  ) {
    bool isPasswordField = controller == newpasswordController;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: isEditing || !isPasswordField
          ? TextField(
              controller: controller,
              obscureText: isPasswordField &&
                  !isEditing, // Mask text for newpassword field
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 179, 179, 179), // Border color
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 12.0,
                ),
              ),
            )
          : TextField(
              controller: controller,
              readOnly: true,
              obscureText: isPasswordField, // Mask text for newpassword field
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 121, 121, 121),
              ),
            ),
    );
  }

  Future<void> _showPasswordDialog(BuildContext context) async {
    final TextEditingController passwordController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Prevents dismissal by tapping outside the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter current Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true, // Hides the password input
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                String currentPassword = passwordController.text.trim();
                // Call _updateProfile with current password
                if (currentPassword.isNotEmpty) {
                  _updateProfile();
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  // Optionally handle empty password input
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter your password.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
