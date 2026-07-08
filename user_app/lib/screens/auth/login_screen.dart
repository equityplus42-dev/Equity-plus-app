import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/biometric_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final _biometricService = BiometricService();
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canAuthenticate = await _biometricService.canAuthenticate();
    if (mounted) {
      setState(() {
        _canCheckBiometrics = canAuthenticate;
      });
    }
  }

  Future<void> _submitBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    final email = prefs.getString('biometric_email');
    final password = prefs.getString('biometric_password');

    // If biometric login is not enabled in settings or we have no saved credentials, prompt to login with password first
    if (!isBiometricEnabled || email == null || password == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in using your password at least once to enable biometric login.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final result = await _biometricService.authenticate();
    if (!mounted) return;

    if (result['success'] == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(email, password);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: AppTheme.neonGreen),
        );
        final user = authProvider.user;
        final bool hasKyc = user != null &&
            user.panNumber != null &&
            user.panNumber!.isNotEmpty &&
            user.aadharNumber != null &&
            user.aadharNumber!.isNotEmpty;
        if (hasKyc) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.kyc);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Biometric login failed.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Save credentials locally so biometric login can perform a real API login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('biometric_email', _emailController.text.trim());
      await prefs.setString('biometric_password', _passwordController.text);

      final user = authProvider.user;
      final bool hasKyc = user != null &&
          user.panNumber != null &&
          user.panNumber!.isNotEmpty &&
          user.aadharNumber != null &&
          user.aadharNumber!.isNotEmpty;
      if (hasKyc) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.kyc);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: AppTheme.bgGradient,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryPurple.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 60,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome Back',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightText,
                    ),
                  ),
                  Text(
                    'Enter details to access your account',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppTheme.softGrey,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Glassmorphic Card container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined, size: 20),
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
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Password',
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
                              return 'Password is too short';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 30),
                        
                        authProvider.isLoading
                            ? const Center(
                                child: SpinKitThreeBounce(
                                  color: AppTheme.primaryPurple,
                                  size: 30.0,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Login'),
                              ),
                        if (_canCheckBiometrics) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _submitBiometric,
                            icon: const Icon(Icons.fingerprint, color: AppTheme.primaryPurple),
                            label: const Text('Use Biometrics', style: TextStyle(color: AppTheme.primaryPurple)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppTheme.primaryPurple),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Register redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: AppTheme.softGrey),
                      ),
                      GestureDetector(
                        onTap: () {
                          authProvider.clearError();
                          Navigator.pushReplacementNamed(context, AppRoutes.register);
                        },
                        child: const Text(
                          'Register Here',
                          style: TextStyle(
                            color: AppTheme.primaryPurple,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
