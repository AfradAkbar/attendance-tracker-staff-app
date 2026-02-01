import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staff_app/constants.dart';
import 'package:staff_app/screens/app_shell.dart';
import 'package:staff_app/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formkey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sign in",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Container(color: Colors.orange, width: 60, height: 2),
                  const SizedBox(height: 30),

                  // Email Label
                  const Text(
                    "Email",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  // EMAIL FIELD
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(height: 2.5),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email, size: 18),
                      hintText: 'Enter your Email',
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Password Label
                  const Text(
                    "Password",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  // PASSWORD FIELD
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    style: const TextStyle(height: 2.5),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.key_rounded, size: 19),
                      hintText: 'Enter your Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Forgot Password
                  // Align(
                  //   alignment: Alignment.centerRight,
                  //   child: TextButton(
                  //     onPressed: () {
                  //       Navigator.of(context).push(
                  //         MaterialPageRoute(
                  //           builder: (context) => const ForgotPasswordScreen(),
                  //         ),
                  //       );
                  //     },
                  //     child: const Text("Forgot Password?"),
                  //   ),
                  // ),
                  const SizedBox(height: 30),

                  // LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formkey.currentState!.validate()) {
                                _onClick(
                                  _emailController.text.trim(),
                                  _passwordController.text.trim(),
                                );
                              }
                            },
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            )
                          : const Text('LOGIN'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SIGNUP NAVIGATION
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     const Text('Don’t have an account?'),
                  //     TextButton(
                  //       onPressed: () {
                  //         Navigator.of(context).pushReplacement(
                  //           MaterialPageRoute(
                  //             builder: (context) => const SignupScreen(),
                  //           ),
                  //         );
                  //       },
                  //       child: const Text('Sign Up'),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // LOGIN FUNCTION
  Future<void> _onClick(String email, String password) async {
    setState(() => _isLoading = true);

    final url = Uri.parse(kStaffLoginRoute);

    final body = jsonEncode({"email": email, "password": password});

    try {
      final res = await post(
        url,
        body: body,
        headers: {"content-type": "application/json"},
      );

      print(res.body);

      if (res.statusCode == 200) {
        final parsedBody = jsonDecode(res.body);

        final prefs = await SharedPreferences.getInstance();
        // Store JWT token for authentication
        prefs.setString('jwt_token', parsedBody['data']['token']);
        // Store staff ID for fetching attendance records
        prefs.setString('staff_id', parsedBody['data']['user']['_id']);
        // Store user data for profile display
        prefs.setString('user_data', jsonEncode(parsedBody['data']['user']));

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppShell()),
          (route) => false,
        );
      } else if (res.statusCode == 401) {
        final parsedBody = jsonDecode(res.body);
        final errorMessage =
            parsedBody['message'] ?? "Invalid email or password";
        _showError(errorMessage);
      } else {
        final parsedBody = jsonDecode(res.body);
        final errorMessage = parsedBody['message'] ?? "An error occurred";
        _showError(errorMessage);
      }
    } catch (e) {
      _showError("Something went wrong. Please try again.");
    }

    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(message)),
    );
  }
}
