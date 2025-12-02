// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend_daktmt/apis/api_profile.dart';
import 'package:frontend_daktmt/custom_card.dart';
import 'package:frontend_daktmt/nav_bar/nav_bar_left.dart';
import 'package:frontend_daktmt/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'dart:typed_data';

final Logger logger = Logger();

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
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

  // File? avatarImageFile;
  // File? coverPhotoFile;
  Uint8List? avatarBytes;
  Uint8List? coverPhotoBytes;


  final ImagePicker _picker = ImagePicker();

Future<void> _pickImage(bool isAvatar) async {
  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    final bytes = await pickedFile.readAsBytes();
    setState(() {
      if (isAvatar) {
        avatarBytes = bytes;
      } else {
        coverPhotoBytes = bytes;
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

    String? profileJson = prefs.getString('profile');
    if (profileJson != null) {
      Map<String, dynamic> profileData = json.decode(profileJson);

      setState(() {
        _profileData = profileData;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No profile data found.')),
      );
    }
  }

  Future<void> _updateProfile({
    required String currentPassword,
    }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('accessToken');

      if (currentPassword.isEmpty) {
        throw Exception('Current password is required.');
      }

      Map<String, dynamic> updatedData = {};

      if (fullnameController.text.trim() != _profileData?['fullname']) {
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

      updatedData['currentpassword'] = currentPassword.trim();

      // ✅ KIỂM TRA COI CÓ ĐỔI ẢNH HAY KHÔNG
      final bool hasImageChange =
          avatarBytes != null || coverPhotoBytes != null;

      // ✅ NẾU KHÔNG ĐỔI TEXT VÀ CŨNG KHÔNG ĐỔI ẢNH → THẬT SỰ LÀ KHÔNG CÓ GÌ ĐỔI
      if (updatedData.length == 1 &&
          updatedData.containsKey('currentpassword') &&
          !hasImageChange) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes were made.')),
        );
        return;
      }

      // if (updatedData.length == 1 &&
      //     updatedData.containsKey('currentpassword')) {
      //   if (!mounted) return;
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('No changes were made.')),
      //   );
      //   return;
      // }

      // await fetchEditProfile(
      //     token!, updatedData, avatarImageFile, coverPhotoFile);

      // setState(() {
      //   updatedData.forEach((key, value) {
      //     if (key != 'currentpassword') {
      //       _profileData?[key] = value;
      //       logger.i(value);
      //     }
      //   });
      //   prefs.setString('profile', json.encode(_profileData));
      // });

      // if (!mounted) return;
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Profile updated successfully!')),
      // );
final updatedProfile = await fetchEditProfile(
  token!,
  updatedData,
  avatarBytes,
  coverPhotoBytes,
);

if (updatedProfile == null) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Update failed on server')),
  );
  return;
} 

setState(() {
  // dùng luôn profile mới từ server
  _profileData = updatedProfile;

  fullnameController.text = updatedProfile['fullname'] ?? '';
  usernameController.text = updatedProfile['username'] ?? '';
  emailController.text = updatedProfile['email'] ?? '';
  phoneController.text = updatedProfile['phone_number'] ?? '';
  aioController.text = updatedProfile['AIO_USERNAME'] ?? '';
  aiokeyController.text = updatedProfile['AIO_KEY'] ?? '';
  wsvController.text = updatedProfile['webServerIp'] ?? '';

  // reset ảnh local sau khi lưu
  avatarBytes = null;
  coverPhotoBytes = null;
});

// lưu lại vào SharedPreferences để lần sau vào màn hình vẫn là dữ liệu mới
prefs.setString('profile', json.encode(updatedProfile));

if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Profile updated successfully!')),
);


    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
      logger.e('Error: $e');
    }
  }

  Future<void> _deleteProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('accessToken');
      var currentPassword = currentpasswordController.text.trim();

      if (currentPassword.isEmpty) {
        throw Exception('Current password is required.');
      }

      await fetchDeleteProfile(token!, currentPassword);
      await prefs.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile deleted successfully!')),
      );
      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete profile: $e')),
      );
      logger.e('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    Widget content;
    if (_profileData == null) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      content = ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildProfileCard(),
        ],
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: const Navbar_left(),
      body: Stack(
        children: [
          // Nền
          Container(decoration: backgound_Color()),

          // Nút 3 gạch cho mobile
          const navbarleft_set(),

          SafeArea(
            child: isDesktop
                ? Row(
                    children: [
                      // Navbar trái luôn hiện trên desktop
                      SizedBox(
                        width: 260,
                        child: const Navbar_left(),
                      ),
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Colors.black26,
                      ),

                      // Nội dung chính
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            children: [
                              _buildProfileTitleBar(),
                              const SizedBox(height: 16),
                              Expanded(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 800,
                                    ),
                                    child: content,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      children: [
                        const SizedBox(
                            height:
                                70),
                        _buildProfileTitleBar(),
                        const SizedBox(height: 16),
                        Expanded(child: content),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Thanh tiêu đề "PROFILE PAGE"
  Widget _buildProfileTitleBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E88E5),
            Color(0xFF42A5F5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: const [
          Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 30,
          ),
          SizedBox(width: 12),
          Text(
            'PROFILE PAGE',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 6.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header: title + nút edit/save
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isEditing ? Icons.check : Icons.edit,
                        color: Colors.green,
                      ),
                      tooltip: isEditing ? 'Save changes' : 'Edit profile',
                      onPressed: () {
                        if (isEditing) {
                          _showPasswordDialog(context);
                        } else {
                          setState(() {
                            isEditing = true;
                          });
                        }
                      },
                    ),
                    if (isEditing)
                      IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.red,
                        ),
                        tooltip: 'Cancel editing',
                        onPressed: () {
                          setState(() {
                            isEditing = false;
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

// Cover + Avatar
Stack(
  clipBehavior: Clip.none,
  children: [
    // COVER
    MouseRegion(
      cursor: isEditing
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: isEditing ? () => _pickImage(false) : null,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            image: coverPhotoBytes != null
                ? DecorationImage(
                    image: MemoryImage(coverPhotoBytes!),
                    fit: BoxFit.cover,
                  )
                : _profileData?['coverPhoto']?['data'] != null
                    ? DecorationImage(
                        image: MemoryImage(
                          base64Decode(_profileData!['coverPhoto']['data']),
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
            borderRadius: BorderRadius.circular(14),
          ),
          width: double.infinity,
          height: 160,
        ),
      ),
    ),

    // AVATAR – luôn phải là child của Stack
    Positioned(
      left: 0,
      right: 0,
      bottom: -40,
      child: Center(
        child: MouseRegion(
          cursor: isEditing
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isEditing ? () => _pickImage(true) : null,
            child: CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFFEDE7F6),
              backgroundImage: avatarBytes != null
                  ? MemoryImage(avatarBytes!)
                  : (_profileData?['avatar']?['data'] != null
                      ? MemoryImage(
                          base64Decode(_profileData!['avatar']['data']),
                        )
                      : null),
              child: avatarBytes == null &&
                      !(_profileData?['avatar']?['data'] != null)
                  ? Text(
                      (_profileData?['username']?[0] ?? 'N/A').toUpperCase(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.primaries[
                          DateTime.now().second % Colors.primaries.length
                        ],
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    ),
  ],
),

const SizedBox(height: 56), // để chừa chỗ cho avatar chìa xuống

            const SizedBox(height: 50),

            Text(
              _profileData?['fullname'] ?? 'N/A',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _profileData?['email'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),

            const Divider(
              color: Color.fromARGB(255, 200, 200, 200),
              thickness: 0.6,
              indent: 8,
              endIndent: 8,
            ),

            _buildEditableProfileItem(fullnameController, 'Full Name'),
            _buildEditableProfileItem(usernameController, 'Username'),
            _buildEditableProfileItem(emailController, 'Email'),
            _buildEditableProfileItem(newpasswordController, 'Password'),
            _buildEditableProfileItem(phoneController, 'Phone'),
            _buildEditableProfileItem(aioController, 'AIO Username'),
            _buildEditableProfileItem(aiokeyController, 'AIO Key'),
            _buildEditableProfileItem(wsvController, 'Web Server IP'),

            const Divider(
              color: Color.fromARGB(255, 200, 200, 200),
              thickness: 0.6,
              indent: 8,
              endIndent: 8,
            ),

            _buildDeleteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableProfileItem(
      TextEditingController controller, String label) {
    bool isPasswordField = controller == newpasswordController;

    if (!isEditing && isPasswordField) {
      controller.text = '**** ****';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        obscureText: isPasswordField && !isEditing,
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
          filled: true,
          fillColor: const Color.fromARGB(10, 0, 0, 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
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
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 90, 90, 90),
              ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Visibility(
      visible: isEditing,
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 18.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 3,
          ),
          icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
          onPressed: () {
            if (isEditing) {
              _showYesno(context);
            } else {
              setState(() {
                isEditing = true;
              });
            }
          },
          label: const Text(
            'Delete account',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> _showYesno(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete account',
            style: TextStyle(color: Colors.red),
          ),
          content: TextField(
            controller: currentpasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color.fromARGB(255, 0, 140, 255)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () {
                if (currentpasswordController.text.trim().isNotEmpty) {
                  _deleteProfile();
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

  Future<void> _showPasswordDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Save changes',
            style: TextStyle(color: Colors.blue),
          ),
          content: TextField(
            controller: currentpasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Current password',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () {
                if (currentpasswordController.text.trim().isNotEmpty) {
                  _updateProfile(
                    currentPassword: currentpasswordController.text.trim(),
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
