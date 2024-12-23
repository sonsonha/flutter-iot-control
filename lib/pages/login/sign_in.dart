import 'package:flutter/material.dart';
import 'package:frontend_daktmt/apis/apis_login.dart';
import 'package:frontend_daktmt/custom_card.dart';
// import 'package:frontend_daktmt/extensions/string_extensions.dart';
import 'package:frontend_daktmt/responsive.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;
  String? _errorMessage;

  Future<void> _handleOnClick(BuildContext context) async {
    if (_emailController.text.isNotEmpty &&
            _passwordController
                .text.isNotEmpty //&& _emailController.text.isValidEmail()
        ) {
      if (_passwordController.text.length < 8) {
        setState(() {
          _errorMessage = "Password must be at least 8 characters long.";
        });
        return;
      }
      String? errorMessage = await fetchSignIn(
        _emailController,
        _passwordController,
        context,
      );

      if (errorMessage != null) {
        setState(() {
          _errorMessage = errorMessage;
        });
      } else {
        setState(() {
          _errorMessage = null;
        });
      }
    } else {
      setState(() {
        _errorMessage = "Not enough information!";
      });
    }
  }

  void _handleSignUpClick(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/register');
  }

  void _handleForgotPasswordClick(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/forget-password');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final bool isRowLayout = isMobile;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Stack(
          children: [
            Container(
              decoration: backgound_Color(),
              padding:
                  EdgeInsets.only(top: 120.0, left: isRowLayout ? 55 : 222),
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to CaCoIot!',
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isRowLayout) const SizedBox(height: 100),
                  if (!isRowLayout) // Khoảng cách giữa các thành phần
                    Image.asset(
                      'assets/mylogoBKU.png', // Đường dẫn đến hình ảnh của bạn
                      width: 400, // Kích thước của hình ảnh
                      height: 400,
                    ),
                  if (!isRowLayout) const SizedBox(height: 20),
                  if (!isRowLayout)
                    const Padding(
                      padding: EdgeInsets.only(
                          left: 250), // Dịch dòng chữ sang trái 20 pixel
                      child: Text(
                        '"Khai phá ,Tiên phong, Sáng tạo"', // Dòng chữ mới
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontStyle: FontStyle.italic, // In nghiêng
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Align(
              alignment:
                  Alignment.centerRight, // Đặt phần tử này ở giữa màn hình
              child: Padding(
                padding: EdgeInsets.only(
                    left: 10.0,
                    right: isRowLayout ? 10.0 : 100.0,
                    top: isRowLayout ? 250.0 : 50.0,
                    bottom: isRowLayout ? 10.0 : 50.0),
                child: Container(
                  width: isRowLayout ? double.infinity : 500.0,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: isRowLayout ? 18.0 : 50.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Điều chỉnh màu nếu cần
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          label: Text(
                            'Username or Email',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                      ),
                      const SizedBox(height: 25.0),
                      TextField(
                        keyboardType: TextInputType.text,
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color:
                                  _passwordVisible ? Colors.green : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                          label: const Text(
                            'Password',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _handleSignUpClick(context),
                            child: const Text(
                              'Sign up',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Color.fromARGB(255, 0, 132, 255),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _handleForgotPasswordClick(context),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Color.fromARGB(255, 0, 132, 255),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 100),
                      _buildSignInButton(context),
                      const SizedBox(height: 50),
                      const DividerWithText(),
                      const SizedBox(height: 30),
                      const _SignWithGG(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () => _handleOnClick(context),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 0, 110, 255),
                Color.fromARGB(255, 247, 0, 255)
              ],
            ),
          ),
          child: Container(
            alignment: Alignment.center,
            child: const Text(
              'Sign In',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignWithGG extends StatelessWidget {
  const _SignWithGG();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Xử lý sự kiện khi nhấn vào nút
        logger.i("Sign in with Google");
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // Màu nền nút
        padding: const EdgeInsets.symmetric(
            horizontal: 12.0, vertical: 12.0), // Padding cho nút
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0), // Tạo viền bo tròn cho nút
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize
            .min, // Đảm bảo hàng chỉ chiếm kích thước tối thiểu cần thiết
        children: [
          Image.asset(
            'assets/google.png', // Đường dẫn logo Google
            width: 32.0, // Chiều rộng logo
            height: 32.0, // Chiều cao logo
          ),
          const SizedBox(width: 10.0), // Khoảng cách giữa logo và text
          const Text(
            "Sign in with Google",
            style: TextStyle(
              color: Colors.black, // Màu chữ
              fontSize: 16.0, // Kích thước chữ
            ),
          ),
        ],
      ),
    );
  }
}
