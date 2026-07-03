import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

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
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
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

  /**
   * Simulates selecting a local image file and uploads dummy bytes to the backend
   */
  Future<void> _simulateImageUpload() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating avatar file stream and uploading... ⏳'),
        duration: Duration(seconds: 1),
      ),
    );

    // Create 1x1 black pixel PNG mockup bytes to upload
    final List<int> pngBytes = [
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 
      0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84, 
      120, 94, 99, 96, 96, 96, 0, 0, 0, 5, 0, 1, 164, 118, 56, 240, 0, 0, 0, 0, 
      73, 69, 78, 68, 174, 66, 96, 130
    ];
    final Uint8List uploadBytes = Uint8List.fromList(pngBytes);

    final success = await profileProvider.uploadAvatar(
      uploadBytes,
      'simulated_avatar_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    if (success) {
      await authProvider.refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar uploaded successfully! (Mock fallback active) 🖼️'),
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
                        onTap: _simulateImageUpload,
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
