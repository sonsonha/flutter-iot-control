import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend_daktmt/custom_card.dart';
import 'package:frontend_daktmt/extensions/string_extensions.dart';
import 'package:frontend_daktmt/responsive.dart';

import '../../apis/apis_login.dart';

class Forget extends StatefulWidget {
  const Forget({super.key});

  @override
  State<Forget> createState() => _ForgetState();
}

class _ForgetState extends State<Forget> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController_1 = TextEditingController();
  final TextEditingController _passwordController_2 = TextEditingController();
  final TextEditingController _code = TextEditingController();

  bool _isVerificationCodeVisible = false;
  bool _passwordVisible = false;

  String? _errorMessage;

  Timer? _timer;
  int _start = 60;
  bool _isTimerActive = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    _isTimerActive = true;
    _start = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _timer?.cancel();
          _isTimerActive = false;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  Future<void> _handleOnClick(BuildContext context) async {
    if (_passwordController_1.text != _passwordController_2.text) {
      setState(() {
        _errorMessage = 'Mật khẩu không khớp';
      });
      return;
    }

    if (_passwordController_1.text.length < 8) {
      setState(() {
        _errorMessage = 'Mật khẩu phải có ít nhất 8 ký tự';
      });
      return;
    }
    bool isSuccess = await fetchConfirmcode(
      _emailController.text,
      _code.text,
    );

    if (isSuccess) {
      isSuccess = await fetchForgetPassword(
          // ignore: use_build_context_synchronously
          _emailController,
          _passwordController_1,
          // ignore: use_build_context_synchronously
          context);

      if (!isSuccess) {
        setState(() {
          _errorMessage = "Đã xảy ra lỗi . Vui lòng thử lại.";
        });
      }
    } else {
      setState(() {
        _errorMessage = "Mã xác thực không đúng";
      });
    }
  }

  void _handleSignInClick(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/signin');
  }

  void _handleSignUpClick(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/register');
  }

  Future<void> _sendcode() async {
    _errorMessage = null;

    if (_emailController.toString().isEmpty) {
      _errorMessage = "Vui lòng điền email";
    }

    bool isSuccess = await fetchSendcode(_emailController.text);
    if (isSuccess) {
      setState(() {
        _isVerificationCodeVisible = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi khi gửi mã xác thực';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final bool isRowLayout = isMobile;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: backgound_Color(),
            padding: EdgeInsets.only(top: 20.0, left: isRowLayout ? 55 : 222),
            alignment: Alignment.topLeft,
            child: const Text(
              'Forget password!',
              style: TextStyle(
                fontSize: 30,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                screenWidth * 0.3, 200, screenWidth * 0.3, 100),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  if (!_isVerificationCodeVisible) ...[
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        suffixIcon: Icon(
                          Icons.check,
                          color: _emailController.text.isValidEmail()
                              ? Colors.green
                              : Colors.grey,
                        ),
                        label: const Text(
                          'Email',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 3, 3, 3),
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildSignUpButton_1(context),
                  ],
                  if (_isVerificationCodeVisible) ...[
                    const Text(
                      'Enter the verification code sent to your email',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 17, 255)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            controller: _code,
                            decoration: const InputDecoration(
                              label: Text(
                                'Verification Code',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (_isTimerActive)
                          Text(
                            '$_start',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 16),
                          )
                        else
                          ElevatedButton(
                            onPressed: () {
                              startTimer();
                              _sendcode();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 0, 102, 255),
                                    Color.fromARGB(144, 0, 38, 255)
                                  ],
                                ),
                              ),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.center,
                                height: 40,
                                child: const Text(
                                  'Send',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    _buildPasswordField(
                      controller: _passwordController_1,
                      label: 'Password',
                    ),
                    _buildPasswordField(
                      controller: _passwordController_2,
                      label: 'Confirm Password',
                    ),
                    const SizedBox(height: 20),
                    _buildSignUpButton_2(context),
                  ],
                  SizedBox(height: screenHeight * 0.2),
                  Align(
                    alignment:
                        Alignment.bottomCenter, // Aligns to the bottom center
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Centers the Row
                      children: [
                        GestureDetector(
                          onTap: () => _handleSignInClick(context),
                          child: const Text(
                            'Sign in',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color.fromARGB(255, 0, 47, 255),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10), // Space between the texts
                        const Text(
                          '-', // Dash between the texts
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Color(0xff281537),
                          ),
                        ),
                        const SizedBox(
                            width:
                                10), // Space between the dash and the next text
                        GestureDetector(
                          onTap: () => _handleSignUpClick(context),
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color.fromARGB(255, 0, 47, 255),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton_1(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.end, // Aligns the button to the right
      children: [
        SizedBox(
          width: 202,
          height: 57,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () async {
              if (_emailController.text.isEmpty) {
                setState(() {
                  _errorMessage = 'Please enter your email';
                });
                return;
              }

              if (!_emailController.text.isValidEmail()) {
                setState(() {
                  _errorMessage = 'Emails are not formatted correctly';
                });
                return;
              }

              _sendcode();
            },
            child: Ink(
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color.fromARGB(255, 0, 102, 255), Color(0xff281537)],
                ),
              ),
              child: Container(
                alignment: Alignment.center,
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton_2(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
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
              colors: [Color.fromARGB(255, 255, 255, 255), Color(0xff281537)],
            ),
          ),
          child: Container(
            alignment: Alignment.center,
            child: const Text(
              'Change password',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
  }) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        obscureText: !_passwordVisible,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _passwordVisible ? Icons.visibility : Icons.visibility_off,
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
            onPressed: () {
              setState(() {
                _passwordVisible = !_passwordVisible;
              });
            },
          ),
        ),
      ),
    );
  }
}
