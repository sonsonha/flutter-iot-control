import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend_daktmt/custom_card.dart';
import 'package:frontend_daktmt/nav_bar/nav_bar_left.dart';
import 'package:frontend_daktmt/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_daktmt/apis/api_page.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();

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
  final TextEditingController fullnameController = TextEditingController();
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
  File? avatarImageFile; // Để lưu hình ảnh avatar dưới dạng File
  File? coverPhotoFile; // Để lưu hình ảnh cover photo dưới dạng File

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isAvatar) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isAvatar) {
          avatarImageFile =
              File(pickedFile.path); // Lưu File đã chọn cho avatar
        } else {
          coverPhotoFile =
              File(pickedFile.path); // Lưu File đã chọn cho cover photo
        }
      });
    } else {
      logger.i('No image selected.');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    // Retrieve the profile JSON string
    String? profileJson = prefs.getString('profile');
    if (profileJson != null) {
      // Decode the JSON string into a Map
      Map<String, dynamic> profileData = json.decode(profileJson);

      setState(() {
        _profileData = profileData; // Save the decoded profile data
        usernameController.text = profileData['username'] ?? '';
        fullnameController.text = profileData['fullname'] ?? '';
        emailController.text = profileData['email'] ?? '';
        phoneController.text = profileData['phone_number'] ?? '';
        aioController.text = profileData['AIO_USERNAME'] ?? '';
        aiokeyController.text = profileData['AIO_KEY'] ?? '';
        wsvController.text = profileData['webServerIp'] ?? '';
        newpasswordController.text = profileData['newPassword'] ?? '';
        currentpasswordController.text = profileData['currentPassword'] ?? '';
      });
    } else {
      logger.i("No profile data found in SharedPreferences.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No profile data found.')),
      );
    }
  }

  Future<void> _updateProfile({
    required String currentPassword, // Mật khẩu hiện tại
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('accessToken');

      if (currentPassword.isEmpty) {
        throw Exception('Current password is required.');
      }

      // Tạo payload chỉ chứa các trường thay đổi
      Map<String, dynamic> updatedData = {};

      // So sánh các giá trị từ TextEditingController với _profileData
      if(fullnameController.text.trim() != _profileData?['fullname']) {
        updatedData['fullname'] = fullnameController.text.trim();
        prefs.remove('fullname');
      }
      if (usernameController.text.trim() != _profileData?['username']) {
        updatedData['username'] = usernameController.text.trim();
        prefs.remove('username');
      }
      if (emailController.text.trim() != _profileData?['email']) {
        updatedData['email'] = emailController.text.trim();
        prefs.remove('email');
      }
      if (phoneController.text.trim() != _profileData?['phone_number']) {
        updatedData['phone_number'] = phoneController.text.trim();
        prefs.remove('phone_number');
      }
      if (aioController.text.trim() != _profileData?['AIO_USERNAME']) {
        updatedData['AIO_USERNAME'] = aioController.text.trim();
        prefs.remove('AIO_USERNAME');
      }
      if (aiokeyController.text.trim() != _profileData?['AIO_KEY']) {
        updatedData['AIO_KEY'] = aiokeyController.text.trim();
        prefs.remove('AIO_KEY');
      }
      if (wsvController.text.trim() != _profileData?['webServerIp']) {
        updatedData['webServerIp'] = wsvController.text.trim();
        prefs.remove('webServerIp');
      }
      if (isEditing &&
          newpasswordController.text.trim().isNotEmpty &&
          newpasswordController.text.trim() != '**** ****') {
        updatedData['newpassword'] = newpasswordController.text.trim();
        prefs.remove('newpassword');
      }

      // Luôn thêm currentpassword vào payload
      updatedData['currentpassword'] = currentPassword.trim();

      // Nếu không có thay đổi nào (ngoài currentpassword)
      if (updatedData.length == 1 &&
          updatedData.containsKey('currentpassword')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes were made.')),
        );
        return;
      }

      // Gửi request cập nhật đến backend
      await fetchEditProfile(
          token!, updatedData, avatarImageFile, coverPhotoFile);

      setState(() {
        updatedData.forEach((key, value) {
          if (key != 'currentpassword') {
            _profileData?[key] = value;
            logger.i(value);
          }
        });
        prefs.setString('profile', json.encode(_profileData));
      });
      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      // Xử lý lỗi và hiển thị thông báo lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
      print('Error: $e');
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
                GestureDetector(
                  onTap: isEditing
                      ? () => _pickImage(false)
                      : null, // Chọn ảnh cho cover photo
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      image: coverPhotoFile != null
                          ? DecorationImage(
                              image: FileImage(
                                  coverPhotoFile!), // Sử dụng FileImage thay vì MemoryImage
                              fit: BoxFit.cover,
                            )
                          : _profileData?['coverPhoto']?['data'] != null
                              ? DecorationImage(
                                  image: MemoryImage(
                                    base64Decode(
                                        _profileData!['coverPhoto']['data']),
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.2,
                  ),
                ),
                GestureDetector(
                  onTap: isEditing
                      ? () => _pickImage(true)
                      : null, // Chọn ảnh cho avatar
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: avatarImageFile != null
                        ? FileImage(
                            avatarImageFile!) // Sử dụng FileImage thay vì MemoryImage
                        : null,
                    child: avatarImageFile == null
                        ? Text(
                            (_profileData?['username']?[0] ?? 'N/A')
                                .toUpperCase(),
                            style: const TextStyle(
                                fontSize: 40, color: Colors.white),
                          )
                        : null,
                  ),
                ),
              ],
            ),
            // Text(
            //   _profileData?['fullname'] ?? 'N/A',
            //   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            // ),
            const Divider(
              color: Color.fromARGB(255, 141, 140, 140),
              thickness: 0.3,
              indent: 20,
              endIndent: 20,
            ),
            _buildEditableProfileItem(fullnameController, 'Full Name'),
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

  _buildEditableProfileItem(TextEditingController controller, String label) {
    bool isPasswordField = controller == newpasswordController;

    if (!isEditing && isPasswordField) {
      controller.text = '**** ****'; // Che đi mật khẩu khi không chỉnh sửa
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: isPasswordField && !isEditing, // Che đi khi là mật khẩu
        readOnly: !isEditing || (isPasswordField && !isEditing),
        onTap: () {
          if (isEditing && isPasswordField) {
            controller.clear();
          }
        },
        onSubmitted: (value) {
          if (isPasswordField) {
            setState(() {
              controller.text = '**** ****';
            });
          }
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Color.fromARGB(255, 179, 179, 179),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 12.0,
          ),
        ),
        style: isEditing && isPasswordField && controller.text.isEmpty
            ? const TextStyle(color: Colors.black)
            : const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 121, 121, 121),
              ),
      ),
    );
  }

  Future<void> _showPasswordDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Current password'),
          content: TextField(
            controller: currentpasswordController,
            obscureText: true, // Ẩn mật khẩu
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                if (currentpasswordController.text.trim().isNotEmpty) {
                  _updateProfile(
                    currentPassword: currentpasswordController.text
                        .trim(), // Truyền mật khẩu hiện tại
                  );
                  setState(() {
                    isEditing = false;
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your current password.'),
                    ),
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
