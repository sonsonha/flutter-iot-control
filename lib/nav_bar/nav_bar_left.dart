import 'package:flutter/material.dart';
import 'package:frontend_daktmt/apis/apis_login.dart';
import 'package:frontend_daktmt/responsive.dart';

// ignore: camel_case_types
class navbarleft_set extends StatelessWidget {
  const navbarleft_set({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Sử dụng MediaQuery để lấy chiều rộng màn hình
    final isMobile = Responsive.isMobile(context);
    // final theme = Theme.of(context);

    return isMobile
        ? Positioned(
            top: 35,
            left: 5,
            child: Builder(
              builder: (context) => IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: Color.fromARGB(255, 5, 16, 49),
                  size: 35.0,
                ),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          )
        : const SizedBox();
  }
}



// ignore: camel_case_types
class Navbar_left extends StatelessWidget {
  const Navbar_left({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Padding(
        // Thêm Padding vào đây
        padding: const EdgeInsets.only(top: 40.0),
        child: ListView(
          padding: EdgeInsets.zero,
          
          children: [
            ListTile(
                leading: const Icon(Icons.home),
                title: const Text(
                'Home',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17.0,
                  color: Color.fromARGB(255, 18, 18, 25),
                )
                // overflow:
                //     TextOverflow.ellipsis, // Adds "..." if the text is too long
                // maxLines: 1, // Limits to a single line
                // softWrap: false, // Prevents wrapping to a new line
                ),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/home');
                }),
            ListTile(
                leading: const Icon(Icons.history),
                title: const Text(
                'History',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17.0,
                  color: Color.fromARGB(255, 19, 19, 24),
                )),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/history');
                }),
            ListTile(
                leading: const Icon(Icons.replay),
                title: const Text(
                'Relay',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17.0,
                  color: Color.fromARGB(255, 18, 18, 25),
                )
                ),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/relay');
                }),
            ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text(
                'Schedule',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17.0,
                  color: Color.fromARGB(255, 18, 18, 25),
                )),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/schedule');
                }),
            ListTile(
                leading: const Icon(Icons.people),
                title: const Text(
                'Profile',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17.0,
                  color: Color.fromARGB(255, 18, 18, 25),
                )),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/profile');
                }),
            ListTile(
                leading: const Icon(Icons.settings),
                title: const Text(
                'Setting',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17.0,
                  color: Color.fromARGB(255, 18, 18, 25),
                )
                ),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/setting');
                }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              onTap: () async {
                final authService = apilogout(); // Khởi tạo AuthService
                bool success =
                    await authService.logoutUser(); // Gọi phương thức đăng xuất

                if (success) {
                  // Nếu đăng xuất thành công, chuyển hướng đến trang đăng nhập
                  // ignore: use_build_context_synchronously
                  Navigator.pushReplacementNamed(context, '/signin');
                } else {
                  // Thông báo lỗi nếu không thành công
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đăng xuất không thành công')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
