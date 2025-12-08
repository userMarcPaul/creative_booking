// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'verify_email_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

// Role can be 'client' or 'creative'
  String _selectedRole = 'client';
  bool _isLoading = false;

  Future<void> _signup() async {
    //1. Validation
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please fill in all required fields"),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final userData = await ApiService.register(
      _usernameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
      _selectedRole,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final int? userId = userData?['id'];
    if (userId == null) return;

    final bool loginSuccess = await ApiService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (loginSuccess && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            role: _selectedRole,
            userId: userId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Create Account",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Start your journey",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 28, fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827))),
            const SizedBox(height: 8),
            Text("Create an account to browse or offer services",
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 32),

            _buildTextField(_usernameController, "Username", Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField(_emailController, "Email", Icons.email_outlined, email: true),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(child: _buildTextField(_firstNameController, "First Name", null)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(_lastNameController, "Last Name", null)),
            ]),

            const SizedBox(height: 16),
            _buildTextField(_passwordController, "Password", Icons.lock_outline, obscure: true),

            const SizedBox(height: 32),
            Text("I want to...",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _buildRoleCard('client', 'Hire Talent', Icons.search)),
                const SizedBox(width: 16),
                Expanded(child: _buildRoleCard('creative', 'Find Work', Icons.brush)),
              ],
            ),

            const SizedBox(height: 40),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text("Create Account"),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Already have an account?",
                    style: TextStyle(color: Colors.grey.shade600)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(" Login",
                      style: TextStyle(
                          color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData? icon, {
    bool obscure = false,
    bool email = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
    );
  }

  Widget _buildRoleCard(String role, String label, IconData icon) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF4F46E5) : Colors.grey.shade200,
            width: 2,
          ),
          color: selected ? const Color(0xFF4F46E5).withOpacity(0.1) : Colors.white,
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? const Color(0xFF4F46E5) : Colors.grey.shade400,
                size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                  color: selected ? const Color(0xFF4F46E5) : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
    );
  }
}
