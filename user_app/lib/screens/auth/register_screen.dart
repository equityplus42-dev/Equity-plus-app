import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/network/api_client.dart';
import '../../services/deep_link_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _refCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _initializedWithArgs = false;
  StreamSubscription<String>? _codeSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedWithArgs) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is String && args.isNotEmpty) {
        _refCodeController.text = args;
      }
      _initializedWithArgs = true;
    }
  }

  Future<void> _scanQrCode() async {
    final scannedCode = await Navigator.pushNamed(context, AppRoutes.qrScanner);
    if (scannedCode != null && scannedCode is String && mounted) {
      setState(() {
        _refCodeController.text = scannedCode;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _codeSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _refCodeController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _availableLanguages = [];
  String? _selectedLanguageId;
  bool _isLoadingLanguages = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchLanguages();
    _loadDeferredReferralCode();

    _codeSubscription = DeepLinkService().referralCodeStream.listen((code) {
      if (mounted && code.isNotEmpty && _refCodeController.text.isEmpty) {
        setState(() {
          _refCodeController.text = code;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDeferredReferralCode();
    }
  }

  Future<void> _loadDeferredReferralCode() async {
    final code = await DeepLinkService().getOrRecoverPendingReferralCode();
    if (code != null && code.isNotEmpty && mounted) {
      if (_refCodeController.text.isEmpty) {
        setState(() {
          _refCodeController.text = code;
        });
      }
    }
  }

  Future<void> _fetchLanguages() async {
    try {
      final response = await ApiClient().get('/languages');
      final List data = response['data'] ?? [];
      if (mounted && data.isNotEmpty) {
        setState(() {
          _availableLanguages = data.cast<Map<String, dynamic>>();
          _selectedLanguageId = _availableLanguages.first['id'];
          _isLoadingLanguages = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error fetching languages: $e');
    }

    // Fallback default languages if offline or network fetch fails
    if (mounted) {
      setState(() {
        _availableLanguages = [
          {'id': 'en', 'name': 'English', 'code': 'en'},
          {'id': 'hi', 'name': 'Hindi', 'code': 'hi'},
          {'id': 'bn', 'name': 'Bengali', 'code': 'bn'},
        ];
        _selectedLanguageId = 'en';
        _isLoadingLanguages = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLanguageId == null || _selectedLanguageId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your preferred language.')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      referralCode: _refCodeController.text.trim(),
      preferredLanguageId: _selectedLanguageId!,
    );

    if (!mounted) return;

    if (success) {
      await DeepLinkService().clearPendingReferralCode();
      final user = authProvider.user;
      final bool hasKyc = user != null &&
          user.panNumber != null &&
          user.panNumber!.isNotEmpty &&
          user.aadharNumber != null &&
          user.aadharNumber!.isNotEmpty;
      if (hasKyc) {
        Navigator.pushReplacementNamed(context, AppRoutes.paymentCheckout);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.kyc);
      }
    } else {
      if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Pending admin approval.'),
            backgroundColor: AppTheme.neonGreen,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create Account',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightText,
                    ),
                  ),
                  Text(
                    'Join the Vridhi Network today',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppTheme.softGrey,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Glassmorphic Form
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'First Name',
                                ),
                                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Last Name',
                                ),
                                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Email is required';
                            if (!value.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
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
                            if (value == null || value.isEmpty) return 'Password is required';
                            if (value.length < 6) return 'Must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _isLoadingLanguages
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Center(child: SpinKitRing(color: AppTheme.primaryPurple, size: 24)),
                              )
                            : DropdownButtonFormField<String>(
                                value: _selectedLanguageId,
                                dropdownColor: AppTheme.cardBg,
                                style: GoogleFonts.outfit(color: AppTheme.lightText),
                                decoration: const InputDecoration(
                                  labelText: 'Preferred Language (Required)',
                                  prefixIcon: Icon(Icons.language, color: AppTheme.primaryPurple, size: 20),
                                ),
                                items: _availableLanguages.map((l) {
                                  return DropdownMenuItem<String>(
                                    value: l['id'],
                                    child: Text('${l['name']} (${l['code']})'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedLanguageId = val;
                                    });
                                  }
                                },
                                validator: (val) => val == null || val.isEmpty ? 'Preferred Language is required' : null,
                              ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _refCodeController,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Referral Code (Required)',
                            prefixIcon: const Icon(Icons.card_giftcard_outlined, size: 20),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryPurple),
                              onPressed: _scanQrCode,
                            ),
                            hintText: 'e.g. 3A0N94Y2',
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Referral Code is required' : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 24),
                        
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
                                child: const Text('Register'),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Login redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account? ",
                        style: TextStyle(color: AppTheme.softGrey),
                      ),
                      GestureDetector(
                        onTap: () {
                          authProvider.clearError();
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        },
                        child: const Text(
                          'Login Here',
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
