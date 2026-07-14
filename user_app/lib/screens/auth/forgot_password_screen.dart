import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 0; // 0: Enter Email, 1: Enter OTP, 2: Enter New Password
  
  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyOtp = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_formKeyEmail.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();

    final success = await authProvider.sendPasswordResetOtp(email);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent to your email successfully.'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
      setState(() {
        _currentStep = 1;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to send OTP.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKeyOtp.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    final success = await authProvider.verifyPasswordResetOtp(email, otp);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP verified successfully. Please enter your new password.'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
      setState(() {
        _currentStep = 2;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Invalid OTP.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKeyPassword.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final password = _passwordController.text;

    final success = await authProvider.resetPassword(email, otp, password);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully. Please log in with your new password.'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to reset password.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool isActive = index <= _currentStep;
        bool isCurrent = index == _currentStep;
        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent
                    ? AppTheme.primaryPurple
                    : isActive
                        ? AppTheme.primaryPurple.withOpacity(0.6)
                        : AppTheme.cardBg,
                border: Border.all(
                  color: isCurrent ? AppTheme.primaryPink : AppTheme.borderGrey,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : AppTheme.softGrey,
                  ),
                ),
              ),
            ),
            if (index < 2)
              Container(
                width: 40,
                height: 3,
                color: isActive && index < _currentStep
                    ? AppTheme.primaryPurple
                    : AppTheme.borderGrey,
              ),
          ],
        );
      }),
    );
  }

  Widget _buildEmailStep(bool isLoading) {
    return Form(
      key: _formKeyEmail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Forgot Password?',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your registered email address to receive a 4-digit verification OTP.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.softGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
              hintText: 'name@example.com',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          isLoading
              ? const Center(
                  child: SpinKitThreeBounce(
                    color: AppTheme.primaryPurple,
                    size: 30.0,
                  ),
                )
              : ElevatedButton(
                  onPressed: _requestOtp,
                  child: const Text('Send OTP'),
                ),
        ],
      ),
    );
  }

  Widget _buildOtpStep(bool isLoading) {
    return Form(
      key: _formKeyOtp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Verify OTP',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We have sent a 4-digit verification code to:\n${_emailController.text}',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.softGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: const InputDecoration(
              labelText: '4-Digit OTP',
              counterText: '',
              prefixIcon: Icon(Icons.security, size: 20),
              hintText: '0000',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'OTP is required';
              }
              if (value.trim().length != 4) {
                return 'OTP must be exactly 4 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          isLoading
              ? const Center(
                  child: SpinKitThreeBounce(
                    color: AppTheme.primaryPurple,
                    size: 30.0,
                  ),
                )
              : ElevatedButton(
                  onPressed: _verifyOtp,
                  child: const Text('Verify OTP'),
                ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: isLoading ? null : () {
              setState(() {
                _otpController.clear();
                _currentStep = 0; // Go back to request
              });
            },
            child: const Text('Change Email'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep(bool isLoading) {
    return Form(
      key: _formKeyPassword,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reset Password',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your new password below.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.softGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirm password is required';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          isLoading
              ? const Center(
                  child: SpinKitThreeBounce(
                    color: AppTheme.primaryPurple,
                    size: 30.0,
                  ),
                )
              : ElevatedButton(
                  onPressed: _resetPassword,
                  child: const Text('Update Password'),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0 && !isLoading) {
              setState(() {
                _currentStep--;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepIndicator(),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassCardDecoration(),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _currentStep == 0
                          ? _buildEmailStep(isLoading)
                          : _currentStep == 1
                              ? _buildOtpStep(isLoading)
                              : _buildPasswordStep(isLoading),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
