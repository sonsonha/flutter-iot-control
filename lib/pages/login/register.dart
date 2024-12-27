import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend_daktmt/custom_card.dart';
import 'package:frontend_daktmt/extensions/string_extensions.dart';
import 'package:frontend_daktmt/responsive.dart';

import '../../apis/apis_login.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController _fullname = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController_1 = TextEditingController();
  final TextEditingController _passwordController_2 = TextEditingController();
  final TextEditingController _aiouser = TextEditingController();
  final TextEditingController _aiokey = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _code = TextEditingController();

  bool _isVerificationCodeVisible = false;
  bool _passwordVisible = false;
  bool isLoading = false;
  String? _errorMessage;

  // Timer-related variables
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
   
    if (_emailController.text.isNotEmpty && _code.text.isNotEmpty) {
      String? confirmCodeResult = await fetchConfirmcode(
        _emailController.text,
        _code.text,
      );

      if (confirmCodeResult != "Success verification code") {
        setState(() {
          _errorMessage = "Wrong code verification";
        });
        return;
      }

      String? registerResult = await fetchRegister(
        _fullname,
        _username,
        _emailController,
        _passwordController_1,
        _aiouser,
        _aiokey,
        _phone,
        // ignore: use_build_context_synchronously
        context,
      );

      if (registerResult != "Successfully registered") {
        setState(() {
          _errorMessage = registerResult;
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

  void _handleSignInClick(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/signin');
  }

  void _handleForgotPasswordClick(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/forget-password');
  }

  Future<void> _sendcode() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = "Not enough information!";
      });
      return;
    }

    String? sendCodeResult = await fetchSendcode(_emailController.text);
     
    if (sendCodeResult == "Successful code submission") {
      setState(() {
        _isVerificationCodeVisible = true;
        _errorMessage = null;
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: backgound_Color(),
            padding: EdgeInsets.only(top: isRowLayout ? 50.0 : 60.0),
            alignment: Alignment.topCenter,
            child: const Text(
              'Register!',
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
                  ? const EdgeInsets.fromLTRB(10, 200, 10, 10)
                  : EdgeInsets.fromLTRB(
                      screenWidth * 0.36, 150, screenWidth * 0.36, 100),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.white,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 35, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 0.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 255, 0, 0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (!_isVerificationCodeVisible) ...[
                      // Username Field
                      _buildTextField(
                          controller: _fullname, label: 'Full name'),
                      _buildTextField(controller: _username, label: 'Username'),

                      // Email Field with validation icon
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
                      // Password Field
                      _buildPasswordField(
                        controller: _passwordController_1,
                        label: 'Password',
                      ),
                      // Confirm Password Field
                      _buildPasswordField(
                        controller: _passwordController_2,
                        label: 'Confirm Password',
                      ),
                      _buildTextField(
                          controller: _aiouser, label: 'AIO Username'),
                      _buildTextField(controller: _aiokey, label: 'AIO Key'),
                      _buildTextField(
                        controller: _phone,
                        label: 'Phone number',
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 20),
                      _buildSignUpButton_1(context),
                    ],
                    if (_isVerificationCodeVisible) ...[
                      const Text(
                        'Enter the verification code sent to your email',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 132, 255)),
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
                                    color: Color(0xffB81736),
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
                      const SizedBox(height: 20),
                      _buildSignUpButton_2(context),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        GestureDetector(
                          onTap: () => _handleForgotPasswordClick(context),
                          child: const Text(
                            'Forgot Password?',
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
        onPressed: () async {
          if (_fullname.text.isEmpty ||
              _username.text.isEmpty ||
              _emailController.text.isEmpty ||
              _passwordController_1.text.isEmpty ||
              _aiouser.text.isEmpty ||
              _aiokey.text.isEmpty ||
              _phone.text.isEmpty) {
            setState(() {
              _errorMessage = 'Not enough information!';
            });
            return;
          }

          if (!_emailController.text.isValidEmail()) {
            setState(() {
              _errorMessage = 'Wrong email format';
            });
            return;
          }

          if (_passwordController_1.text != _passwordController_2.text) {
            setState(() {
              _errorMessage = 'Password mismatch';
            });
            return;
          }
          if (_passwordController_1.text.length < 8) {
            setState(() {
              _errorMessage =
                  'Password must not be less than 8 characters long';
            });
            return;
          }
          if (!RegExp(r'^[0-9]+$').hasMatch(_phone.text)) {
            setState(() {
              _errorMessage = 'Phone number must contain only digits';
            });
            return;
          }

          if (_phone.text.length < 10 || _phone.text.length > 11) {
            setState(() {
              _errorMessage = 'Phone number must be 10 or 11 characters long';
            });
            return;
          }
          setState(() {
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
                    'Sign Up',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
          ),
        ),
      ),
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
              'Confirm',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
    return TextField(
      controller: controller,
      obscureText: !_passwordVisible,
      decoration: InputDecoration(
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
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
    );
  }
}
