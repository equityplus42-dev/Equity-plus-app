import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/location_data.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _formKey = GlobalKey<FormState>();
  final _panController = TextEditingController();
  final _aadharController = TextEditingController();
  final _whatsAppController = TextEditingController();
  String? _selectedState;
  String? _selectedDistrict;
  bool _isOtherDistrict = false;
  final _otherDistrictController = TextEditingController();

  @override
  void dispose() {
    _panController.dispose();
    _aadharController.dispose();
    _whatsAppController.dispose();
    _otherDistrictController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await profileProvider.updateProfile(
      panNumber: _panController.text.trim().toUpperCase(),
      aadharNumber: _aadharController.text.trim(),
      whatsApp: _whatsAppController.text.trim(),
      state: _selectedState ?? '',
      district: _isOtherDistrict ? _otherDistrictController.text.trim() : (_selectedDistrict ?? ''),
    );

    if (!mounted) return;

    if (success) {
      // Reload profile to update UserModel state
      await authProvider.refreshProfile();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileProvider.errorMessage ?? 'Failed to save details'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.security,
                      size: 60,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Verification Required',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Please complete your profile, location, and KYC details to secure and activate your account.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.softGrey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _whatsAppController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'WhatsApp Number',
                            prefixIcon: Icon(Icons.phone_outlined, size: 20),
                            hintText: 'e.g. 9876543210',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'WhatsApp number is required';
                            }
                            final regex = RegExp(r'^[0-9]{10}$');
                            if (!regex.hasMatch(value.trim())) {
                              return 'Enter a valid 10-digit mobile number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _selectedState,
                          decoration: const InputDecoration(
                            labelText: 'State',
                            prefixIcon: Icon(Icons.map_outlined, size: 20),
                          ),
                          items: LocationData.states.map((String state) {
                            return DropdownMenuItem<String>(
                              value: state,
                              child: Text(state),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedState = newValue;
                              _selectedDistrict = null;
                              _isOtherDistrict = false;
                            });
                          },
                          validator: (value) => value == null ? 'State is required' : null,
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _selectedDistrict,
                          decoration: const InputDecoration(
                            labelText: 'District / City',
                            prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                          ),
                          items: LocationData.getDistrictsForState(_selectedState).map((String district) {
                            return DropdownMenuItem<String>(
                              value: district,
                              child: Text(district),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedDistrict = newValue;
                              _isOtherDistrict = newValue == 'Other / Type Manually';
                            });
                          },
                          validator: (value) => value == null ? 'District is required' : null,
                        ),
                        if (_isOtherDistrict) ...[
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _otherDistrictController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Type District / City',
                              prefixIcon: Icon(Icons.edit_location_alt_outlined, size: 20),
                              hintText: 'Enter city name',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'City name is required';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _panController,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'PAN Card Number',
                            prefixIcon: Icon(Icons.badge_outlined, size: 20),
                            hintText: 'e.g. ABCDE1234F',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'PAN number is required';
                            }
                            final regex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
                            if (!regex.hasMatch(value.trim().toUpperCase())) {
                              return 'Enter a valid 10-character PAN (e.g. ABCDE1234F)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _aadharController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Aadhar Card Number',
                            prefixIcon: Icon(Icons.credit_card_outlined, size: 20),
                            hintText: '12-digit number',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Aadhar number is required';
                            }
                            final regex = RegExp(r'^[0-9]{12}$');
                            if (!regex.hasMatch(value.trim())) {
                              return 'Enter a valid 12-digit Aadhar number';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 30),
                        
                        profileProvider.isLoading
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
                                child: const Text('Complete Verification'),
                              ),
                      ],
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
