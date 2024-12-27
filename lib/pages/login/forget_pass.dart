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
  bool isLoading = false;
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
        _errorMessage = 'Wrong password';
      });
      return;
    }

    if (_passwordController_1.text.isEmpty ||
        _passwordController_1.text.length < 8) {
      setState(() {
        _errorMessage = 'Password has to be at least 8 characters';
      });
      return;
    }

    String? confirmCodeResult = await fetchConfirmcode(
      _emailController.text,
      _code.text,
    );

    if (confirmCodeResult != "Success verification code") {
      setState(() {
        _errorMessage = confirmCodeResult;
      });
      return;
    }

    String? forgetPasswordResult = await fetchForgetPassword(
      _emailController,
      _passwordController_1,
      // ignore: use_build_context_synchronously
      context,
    );

    if (forgetPasswordResult != "Success") {
      setState(() {
        _errorMessage = forgetPasswordResult;
      });
    } else {
      setState(() {
        _errorMessage = null;
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
    setState(() {
      _errorMessage = null; // Reset lỗi
    });

    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = "Please enter your email";
      });
      return;
    }

    String? sendCodeResult = await fetchSendcode(_emailController.text);

    if (sendCodeResult == "Successful code submission") {
      setState(() {
        _isVerificationCodeVisible = true;
        _errorMessage = null; // Reset lỗi sau khi thành công
      });
    } else {
      setState(() {
        _errorMessage = sendCodeResult;
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final bool isRowLayout = isMobile;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: backgound_Color(),
            padding: EdgeInsets.only(top: isRowLayout ? 50.0 : 50.0),
            alignment: Alignment.topCenter,
            child: const Text(
              'Forget password!',
              style: TextStyle(
                fontSize: 30,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: isRowLayout
                  ? const EdgeInsets.fromLTRB(10, 300, 10, 10)
                  : EdgeInsets.fromLTRB(
                      screenWidth * 0.36, 200, screenWidth * 0.36, 100),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.white,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 100),
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
                          setState(() {
                            _errorMessage = null;
                          });
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
                              keyboardType: TextInputType.text,
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
                                      Color.fromARGB(255, 252, 201, 201),
                                      Color.fromARGB(255, 148, 59, 216)
                                    ],
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
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
                      const SizedBox(height: 10),
                      _buildPasswordField(
                        controller: _passwordController_1,
                        label: 'Password',
                      ),
                      const SizedBox(height: 10),
                      _buildPasswordField(
                        controller: _passwordController_2,
                        label: 'Confirm Password',
                      ),
                      const SizedBox(height: 40),
                      _buildSignUpButton_2(context),
                    ],
                    SizedBox(height: screenHeight * 0.05),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _handleSignInClick(context),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color.fromARGB(255, 0, 47, 255),
                            ),
                          ),
                        ),
                        const SizedBox(width: 200),
                        GestureDetector(
                          onTap: () => _handleSignUpClick(context),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color.fromARGB(255, 0, 47, 255),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
          MainAxisAlignment.center, // Aligns the button to the right
      children: [
        SizedBox(
          width: 250,
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
              setState(() {
                _errorMessage = null;
                isLoading = true;
              });
              _sendcode();
              startTimer();
            },
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 252, 201, 201),
                    Color.fromARGB(255, 148, 59, 216)
                  ],
                ),
              ),
              child: Container(
                alignment: Alignment.center,
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ))
                    : const Text(
                        'Next',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color.fromARGB(255, 255, 255, 255),
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
      width: 250,
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
              colors: [
                Color.fromARGB(255, 252, 201, 201),
                Color.fromARGB(255, 148, 59, 216)
              ],
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
      height: 50,
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
              color: _passwordVisible ? Colors.green : Colors.grey,
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
