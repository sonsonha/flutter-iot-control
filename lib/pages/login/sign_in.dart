import 'package:flutter/material.dart';
import 'package:frontend_daktmt/apis/apis_login.dart';
import 'package:frontend_daktmt/custom_card.dart';
import 'package:frontend_daktmt/responsive.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';

final Logger logger = Logger();

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final FocusNode _keyboardFocusNode = FocusNode();

  bool _passwordVisible = false;
  String? _errorMessage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Đảm bảo KeyboardListener có focus sau khi widget được mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _keyboardFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

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
      setState(() {
        isLoading = true;
      });
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
      setState(() {
        isLoading = false;
      });
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

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: false, // bạn đã requestFocus trong initState
      includeSemantics: true,
      onKeyEvent: (KeyEvent event) {
        // chỉ phản ứng khi key được nhấn xuống (KeyDown)
        if (event is KeyDownEvent) {
          // kiểm tra Enter (cả numpad và normal enter)
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            // Gọi action giống như bấm nút Sign In
            _handleOnClick(context);
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true, // Avoid keyboard overlap
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Wrap Stack inside a ConstrainedBox with appropriate constraints
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      Container(
                        decoration: backgound_Color(),
                        padding: EdgeInsets.only(
                            top: 100.0, left: isRowLayout ? 85 : 222),
                        alignment: Alignment.topLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome to CaCoIot!',
                              style: TextStyle(
                                fontSize: 30,
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!isRowLayout) const SizedBox(height: 100),
                            if (!isRowLayout)
                              Image.asset(
                                'assets/mylogoBKU.png',
                                width: 400,
                                height: 400,
                              ),
                            if (!isRowLayout) const SizedBox(height: 20),
                            if (!isRowLayout)
                              const Padding(
                                padding: EdgeInsets.only(left: 250),
                                child: Text(
                                  '"Khai phá ,Tiên phong, Sáng tạo"',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 10.0,
                            right: isRowLayout ? 10.0 : 100.0,
                            top: isRowLayout ? 220.0 : 50.0,
                            bottom: isRowLayout ? 0 : 50.0,
                          ),
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: isRowLayout ? double.infinity : 500.0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              color: const Color.fromARGB(235, 255, 255, 255),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: isRowLayout ? 18.0 : 50.0,
                                vertical: isRowLayout ? 50.0 : 80.0),
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize.min, // Adjust size to fit content
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Sign in',
                                  style: TextStyle(
                                    fontSize: 35,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
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
                                        color: _passwordVisible
                                            ? Colors.green
                                            : Colors.grey,
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
                                  onChanged: (value) {
                                    setState(() {
                                      _errorMessage = null;
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
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
                                    GestureDetector(
                                      onTap: () =>
                                          _handleForgotPasswordClick(context),
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
              ),
            ],
          ),
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
