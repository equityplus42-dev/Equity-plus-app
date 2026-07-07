import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/location_data.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsAppController;
  String? _selectedState;
  String? _selectedDistrict;
  bool _isOtherDistrict = false;
  late TextEditingController _otherDistrictController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _whatsAppController = TextEditingController(text: user?.whatsApp ?? '');
    _selectedState = user?.state?.isNotEmpty == true ? user!.state : null;
    
    // Check if district is in our predefined list, otherwise set to 'Other'
    final predefinedDistricts = LocationData.getDistrictsForState(_selectedState);
    if (user?.district?.isNotEmpty == true) {
      if (predefinedDistricts.contains(user!.district)) {
        _selectedDistrict = user.district;
      } else {
        _selectedDistrict = 'Other / Type Manually';
        _isOtherDistrict = true;
      }
    }
    _otherDistrictController = TextEditingController(
      text: _isOtherDistrict ? user?.district : ''
    );
    _bioController = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _whatsAppController.dispose();
    _otherDistrictController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await profileProvider.updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      whatsApp: _whatsAppController.text.trim(),
      state: _selectedState ?? '',
      district: _isOtherDistrict ? _otherDistrictController.text.trim() : (_selectedDistrict ?? ''),
      bio: _bioController.text.trim(),
    );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.errorMessage ?? 'Update failed'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      await authProvider.refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully! 🎉'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
      }
    }
  }

  Future<Uint8List?> _compressImage(Uint8List originalBytes) async {
    try {
      img.Image? decoded = img.decodeImage(originalBytes);
      if (decoded == null) return null;

      // Downscale if too large to save memory & space
      if (decoded.width > 800 || decoded.height > 800) {
        decoded = img.copyResize(decoded, width: 800);
      }

      int quality = 80;
      Uint8List compressed = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));

      // Loop to get under 50KB (51200 bytes)
      while (compressed.lengthInBytes > 50 * 1024 && quality > 15) {
        quality -= 15;
        compressed = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
      }

      debugPrint("Final compressed image size: ${compressed.lengthInBytes / 1024} KB (Quality: $quality)");
      return compressed;
    } catch (e) {
      debugPrint("Image compression error: $e");
      return originalBytes;
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Processing and compressing avatar... ⏳'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final Uint8List originalBytes = await image.readAsBytes();
      final Uint8List? compressedBytes = await _compressImage(originalBytes);

      if (compressedBytes == null) {
        throw Exception("Failed to process image");
      }

      final success = await profileProvider.uploadAvatar(
        compressedBytes,
        'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (success) {
        await authProvider.refreshProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar uploaded successfully! 🖼️'),
              backgroundColor: AppTheme.neonGreen,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(profileProvider.errorMessage ?? 'Avatar upload failed'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.lightText),
                title: Text('Gallery', style: GoogleFonts.outfit(color: AppTheme.lightText)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.lightText),
                title: Text('Camera', style: GoogleFonts.outfit(color: AppTheme.lightText)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);

    final String email = authProvider.user?.email ?? '';
    final String initial = authProvider.user?.fullName.isNotEmpty == true 
        ? authProvider.user!.fullName[0].toUpperCase() 
        : 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Avatar editing circle
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.primaryPurple.withOpacity(0.2),
                      backgroundImage: authProvider.user?.avatarUrl != null
                          ? NetworkImage(authProvider.user!.avatarUrl!)
                          : null,
                      child: authProvider.user?.avatarUrl == null
                          ? Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryPurple,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryPurple,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap icon to upload new picture',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.softGrey,
                  ),
                ),
                const SizedBox(height: 30),
                
                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassCardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Account Email (ReadOnly)',
                        style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightText.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(labelText: 'First Name'),
                              validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(labelText: 'Last Name'),
                              validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      TextFormField(
                        controller: _whatsAppController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp Number',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      DropdownButtonFormField<String>(
                        initialValue: LocationData.states.contains(_selectedState) ? _selectedState : null,
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
                      ),
                      const SizedBox(height: 20),
                      
                      DropdownButtonFormField<String>(
                        initialValue: LocationData.getDistrictsForState(_selectedState).contains(_selectedDistrict) ? _selectedDistrict : null,
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
                      ),
                      if (_isOtherDistrict) ...[
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _otherDistrictController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Type District / City',
                            prefixIcon: Icon(Icons.edit_location_alt_outlined, size: 20),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Biography',
                          prefixIcon: Icon(Icons.info_outline, size: 20),
                          alignLabelWithHint: true,
                        ),
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
                              onPressed: _save,
                              child: const Text('Save Details'),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
