
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_screen.dart';
import 'register_screen.dart'; // Import new RegisterScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://chatbotflutter-production.up.railway.app/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade700, Colors.blue.shade200],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/logo.png',
                      height: 100,
                      width: 100,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.chat_bubble_outline,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chatbot App',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.email, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.lock, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      obscureText: true,
                      style: TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Login Button
                    _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade700,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.login),
                          SizedBox(width: 8),
                          Text(
                            'Login',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Navigate to Register
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterScreen()),
                        );
                      },
                      child: Text(
                        'Don\'t have an account? Register here',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
