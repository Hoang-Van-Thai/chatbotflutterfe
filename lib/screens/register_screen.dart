
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';

// New OTP Screen
class OTPScreen extends StatefulWidget {
  final String email;

  const OTPScreen({super.key, required this.email});

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://chatbotflutter-production.up.railway.app/register/verify-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'otp': _otpController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP verified! Registration successful. Please log in.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        final error = jsonDecode(response.body)['detail'] ?? 'OTP verification failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
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
    _otpController.dispose();
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
                      'Enter OTP',
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
                    const SizedBox(height: 16),
                    Text(
                      'An OTP has been sent to ${widget.email}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // OTP Field
                    TextFormField(
                      controller: _otpController,
                      decoration: InputDecoration(
                        labelText: 'OTP',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.lock, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the OTP';
                        }
                        if (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) {
                          return 'OTP must be a 6-digit number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Verify Button
                    _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : ElevatedButton(
                      onPressed: _verifyOTP,
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
                          Icon(Icons.check),
                          SizedBox(width: 8),
                          Text(
                            'Verify OTP',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Back to Register
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Back to Register',
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

// Updated Register Screen
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://chatbotflutter-production.up.railway.app/register/send-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'role': 'user',
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to your email!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(email: _emailController.text.trim()),
          ),
        );
      } else {
        final error = jsonDecode(response.body)['detail'] ?? 'Failed to send OTP';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
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
                      'Register to Chatbot App',
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
                    // Register Button
                    _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        // background backgroundColor: Colors.white,
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
                          Icon(Icons.person_add),
                          SizedBox(width: 8),
                          Text(
                            'Register',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Navigate to Login
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      },
                      child: Text(
                        'Already have an account? Login here',
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