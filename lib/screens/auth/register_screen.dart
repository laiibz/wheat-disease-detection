import 'package:flutter/material.dart';
import 'package:email_otp/email_otp.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timer_count_down/timer_count_down.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/botanical_background.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _canResend = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  EmailOTP myAuth = EmailOTP();

  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    if (_nameController.text.isEmpty || email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill all fields");
      return;
    }

    if (!_isValidEmail(email)) {
      Fluttertoast.showToast(msg: "Invalid email format");
      return;
    }

    if (password.length < 8) {
      Fluttertoast.showToast(msg: "Password must be at least 8 characters long");
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      Fluttertoast.showToast(msg: "Add at least one uppercase letter (A-Z)");
      return;
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      Fluttertoast.showToast(msg: "Add at least one lowercase letter (a-z)");
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      Fluttertoast.showToast(msg: "Add at least one number (0-9)");
      return;
    }
    if (!RegExp(r'[!@#\$&*~]').hasMatch(password)) {
      Fluttertoast.showToast(msg: "Add a special character (e.g. ! @ # \$)");
      return;
    }

    if (password != _confirmPasswordController.text) {
      Fluttertoast.showToast(msg: "Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      myAuth.setConfig(
        appEmail: "wheatguard.app@gmail.com",
        appName: "WheatGuard Security",
        userEmail: email,
        otpLength: 6,
      );

      myAuth.setSMTP(
        host: "smtp.gmail.com",
        auth: true,
        username: "wheatguard.app@gmail.com",
        password: "szja yepr zljh njxr", 
        secure: "TLS",
        port: 587,
      );

      bool result = await myAuth.sendOTP();
      if (result) {
        Fluttertoast.showToast(msg: "OTP sent! Check your Inbox or Spam folder.");
        setState(() {
          _isOtpSent = true;
          _canResend = false;
        });
      } else {
        Fluttertoast.showToast(msg: "Failed to send code.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Service error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length < 6) {
      Fluttertoast.showToast(msg: "Enter the 6-digit code");
      return;
    }

    setState(() => _isLoading = true);
    try {
      bool isVerified = await myAuth.verifyOTP(otp: _otpController.text);
      if (isVerified) {
        if (!mounted) return;
        final authService = context.read<AuthService>();
        await authService.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );
        Fluttertoast.showToast(msg: "Account created successfully!");
        if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        Fluttertoast.showToast(msg: "Invalid code.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleRegister() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final result = await authService.signInWithGoogle();
      if (result != null) {
        final exists = await authService.checkUserExists(result.user!.uid);
        if (exists) {
          await authService.signOut();
          Fluttertoast.showToast(msg: "Account already exists. Please sign in.");
        } else {
          await authService.createUserInFirestore(
            result.user!.uid,
            result.user!.displayName ?? "User",
            result.user!.email ?? "",
            'google',
            photoUrl: result.user!.photoURL,
          );
          if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Join WheatGuard"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BotanicalBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        if (!_isOtpSent) ...[
                          const SizedBox(height: 16),
                          const Icon(Icons.grass, size: 80, color: AppTheme.goldAccent),
                          const SizedBox(height: 16),
                          const Text("Create your professional account", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 32),
                          _buildField(_nameController, "Full Name", Icons.person),
                          const SizedBox(height: 16),
                          _buildField(_emailController, "Email Address", Icons.email),
                          const SizedBox(height: 16),
                          _buildField(
                            _passwordController, 
                            "Password", 
                            Icons.lock_outline, 
                            isPassword: true, 
                            obscure: _obscurePassword,
                            onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword)
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            _confirmPasswordController, 
                            "Confirm Password", 
                            Icons.lock_reset, 
                            isPassword: true,
                            obscure: _obscureConfirmPassword,
                            onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Password must be 8+ chars with uppercase, number & symbol.",
                            style: TextStyle(color: Colors.white38, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          _isLoading 
                            ? const CircularProgressIndicator(color: AppTheme.goldAccent)
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton(onPressed: _sendOtp, child: const Text("SEND VERIFICATION CODE")),
                                  const SizedBox(height: 24),
                                  const Center(child: Text("OR", style: TextStyle(color: Colors.grey))),
                                  const SizedBox(height: 24),
                                  OutlinedButton.icon(
                                    onPressed: _googleRegister,
                                    icon: const Icon(FontAwesomeIcons.google, size: 18),
                                    label: const Text("Continue with Google"),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: AppTheme.sageGreen),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                        ] else ...[
                          const SizedBox(height: 40),
                          const Icon(Icons.mark_email_read, size: 80, color: AppTheme.goldAccent),
                          const SizedBox(height: 24),
                          const Text("Verify Your Identity", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("Code sent to: ${_emailController.text}", style: const TextStyle(color: AppTheme.sageGreen), textAlign: TextAlign.center),
                          const SizedBox(height: 32),
                          _buildField(_otpController, "Enter 6-Digit Code", Icons.security, isNumber: true),
                          const SizedBox(height: 32),
                          _isLoading
                            ? const CircularProgressIndicator(color: AppTheme.goldAccent)
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton(onPressed: _verifyOtp, child: const Text("VERIFY & REGISTER")),
                                  if (_canResend)
                                    TextButton(onPressed: _sendOtp, child: const Text("Resend Code")),
                                  const SizedBox(height: 16),
                                  Countdown(
                                    seconds: 60,
                                    build: (_, double time) => Text("Resend available in ${time.toInt()}s", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                                    onFinished: () => setState(() => _canResend = true),
                                  ),
                                ],
                              ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool isPassword = false, bool isNumber = false, bool obscure = false, VoidCallback? onToggleObscure}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.glassWhite, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: isPassword ? obscure : false,
        keyboardType: isNumber ? TextInputType.number : (label.contains("Email") ? TextInputType.emailAddress : TextInputType.text),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.sageGreen),
          prefixIcon: Icon(icon, color: AppTheme.sageGreen),
          suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                onPressed: onToggleObscure,
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
