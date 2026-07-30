import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../../widgets/change_password_dialog.dart';
import '../../providers/admin_settings_provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _l1Controller;
  late TextEditingController _l2Controller;
  late TextEditingController _l3Controller;
  late TextEditingController _depthController;
  bool _requireApproval = false;

  late TextEditingController _campaignTitleController;
  late TextEditingController _campaignDescController;
  late TextEditingController _campaignImageController;
  late TextEditingController _campaignRedirectController;
  bool _campaignEnabled = false;

  @override
  void initState() {
    super.initState();
    _l1Controller = TextEditingController();
    _l2Controller = TextEditingController();
    _l3Controller = TextEditingController();
    _depthController = TextEditingController();
    _campaignTitleController = TextEditingController();
    _campaignDescController = TextEditingController();
    _campaignImageController = TextEditingController();
    _campaignRedirectController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<AdminSettingsProvider>(context, listen: false);
      await provider.fetchSettings();
      
      final currentSettings = provider.settings;
      _l1Controller.text = currentSettings['points_level_1'] ?? '100';
      _l2Controller.text = currentSettings['points_level_2'] ?? '50';
      _l3Controller.text = currentSettings['points_level_3'] ?? '25';
      _depthController.text = currentSettings['max_hierarchy_depth'] ?? '3';
      _campaignTitleController.text = currentSettings['campaign_ad_title'] ?? 'Special Equity Offer';
      _campaignDescController.text = currentSettings['campaign_ad_description'] ?? 'Earn 2x reward points today! Check out details.';
      _campaignImageController.text = currentSettings['campaign_ad_image_url'] ?? 'https://picsum.photos/400/250';
      _campaignRedirectController.text = currentSettings['campaign_ad_redirect_url'] ?? 'https://google.com';
      
      setState(() {
        _requireApproval = currentSettings['require_admin_approval'] == 'true';
        _campaignEnabled = currentSettings['campaign_ad_enabled'] == 'true';
      });
    });
  }

  @override
  void dispose() {
    _l1Controller.dispose();
    _l2Controller.dispose();
    _l3Controller.dispose();
    _depthController.dispose();
    _campaignTitleController.dispose();
    _campaignDescController.dispose();
    _campaignImageController.dispose();
    _campaignRedirectController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _compressImage(Uint8List originalBytes) async {
    try {
      img.Image? decoded = img.decodeImage(originalBytes);
      if (decoded == null) return null;

      if (decoded.width > 800 || decoded.height > 800) {
        decoded = img.copyResize(decoded, width: 800);
      }

      int quality = 80;
      Uint8List compressed = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));

      while (compressed.lengthInBytes > 100 * 1024 && quality > 15) {
        quality -= 15;
        compressed = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
      }

      debugPrint("Final compressed campaign image size: ${compressed.lengthInBytes / 1024} KB (Quality: $quality)");
      return compressed;
    } catch (e) {
      debugPrint("Image compression error: $e");
      return originalBytes;
    }
  }

  Future<void> _pickAndUploadCampaignImage(ImageSource source) async {
    final provider = Provider.of<AdminSettingsProvider>(context, listen: false);

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
            content: Text('Processing and compressing campaign image... ⏳'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final Uint8List originalBytes = await image.readAsBytes();
      final Uint8List? compressedBytes = await _compressImage(originalBytes);

      if (compressedBytes == null) {
        throw Exception("Failed to process image");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading campaign image to Cloudinary... 🚀'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final String? imageUrl = await provider.uploadCampaignImage(
        compressedBytes,
        'campaign_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (imageUrl != null) {
        setState(() {
          _campaignImageController.text = imageUrl;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Campaign image uploaded successfully! 🖼️'),
              backgroundColor: AppTheme.neonGreen,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Campaign image upload failed'),
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

  void _showCampaignImageSourceOptions() {
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
                  _pickAndUploadCampaignImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.lightText),
                title: Text('Camera', style: GoogleFonts.outfit(color: AppTheme.lightText)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadCampaignImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AdminSettingsProvider>(context, listen: false);

    bool s1 = await provider.updateSetting('points_level_1', _l1Controller.text.trim());
    bool s2 = await provider.updateSetting('points_level_2', _l2Controller.text.trim());
    bool s3 = await provider.updateSetting('points_level_3', _l3Controller.text.trim());
    bool s4 = await provider.updateSetting('max_hierarchy_depth', _depthController.text.trim());
    bool s5 = await provider.updateSetting('require_admin_approval', _requireApproval.toString());
    bool s6 = await provider.updateSetting('campaign_ad_title', _campaignTitleController.text.trim());
    bool s7 = await provider.updateSetting('campaign_ad_description', _campaignDescController.text.trim());
    bool s8 = await provider.updateSetting('campaign_ad_image_url', _campaignImageController.text.trim());
    bool s9 = await provider.updateSetting('campaign_ad_redirect_url', _campaignRedirectController.text.trim());
    bool s10 = await provider.updateSetting('campaign_ad_enabled', _campaignEnabled.toString());

    if (mounted) {
      if (s1 && s2 && s3 && s4 && s5 && s6 && s7 && s8 && s9 && s10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully! 🎉'), backgroundColor: AppTheme.neonGreen),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Failed to save settings'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminSettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign Settings'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: provider.isLoading && provider.settings.isEmpty
            ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACCOUNT SECURITY',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.softGrey,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: AppTheme.glassCardDecoration(),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPurple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.lock_reset_outlined, color: AppTheme.primaryPurple),
                          ),
                          title: Text(
                            'Change Admin Password',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.lightText),
                          ),
                          subtitle: Text(
                            'Update your login credentials securely',
                            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: AppTheme.softGrey),
                          onTap: () => ChangePasswordDialog.show(context),
                        ),
                      ),
                      const SizedBox(height: 30),

                      Text(
                        'REWARD POINTS CONSTANTS',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.softGrey,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.glassCardDecoration(),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _l1Controller,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Level 1 Points (Direct Referral)',
                                prefixIcon: Icon(Icons.stars, color: AppTheme.primaryPurple),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _l2Controller,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Level 2 Points (Indirect Referral)',
                                prefixIcon: Icon(Icons.stars, color: AppTheme.primaryPink),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _l3Controller,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Level 3 Points (Indirect Referral)',
                                prefixIcon: Icon(Icons.stars, color: AppTheme.neonCyan),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      Text(
                        'POLICIES & LIMITS',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.softGrey,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.glassCardDecoration(),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _depthController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Max Hierarchy depth limit (1 - 10)',
                                prefixIcon: Icon(Icons.account_tree_outlined),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              value: _requireApproval,
                              onChanged: (val) {
                                setState(() {
                                  _requireApproval = val;
                                });
                              },
                              title: Text(
                                'Require Admin Approvals',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.lightText),
                              ),
                              subtitle: Text(
                                'If true, rewards will not pay out until manually approved.',
                                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
                              ),
                              activeColor: AppTheme.primaryPurple,
                              contentPadding: EdgeInsets.zero,
                            )
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      Text(
                        'FLOATING CAMPAIGN ADVERTISEMENT',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.softGrey,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.glassCardDecoration(),
                        child: Column(
                          children: [
                            SwitchListTile(
                              value: _campaignEnabled,
                              onChanged: (val) {
                                setState(() {
                                  _campaignEnabled = val;
                                });
                              },
                              title: Text(
                                'Enable Floating Campaign Ad',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.lightText),
                              ),
                              subtitle: Text(
                                'Show/hide campaign ad drawer on user app dashboard.',
                                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
                              ),
                              activeColor: AppTheme.primaryPurple,
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _campaignTitleController,
                              style: GoogleFonts.outfit(color: AppTheme.lightText),
                              decoration: const InputDecoration(
                                labelText: 'Ad Title',
                                prefixIcon: Icon(Icons.title, color: AppTheme.primaryPurple),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _campaignDescController,
                              style: GoogleFonts.outfit(color: AppTheme.lightText),
                              decoration: const InputDecoration(
                                labelText: 'Ad Description',
                                prefixIcon: Icon(Icons.description, color: AppTheme.primaryPink),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
                                    image: _campaignImageController.text.isNotEmpty && _campaignImageController.text.startsWith('http')
                                        ? DecorationImage(
                                            image: NetworkImage(_campaignImageController.text),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: _campaignImageController.text.isEmpty || !_campaignImageController.text.startsWith('http')
                                      ? const Icon(Icons.image_not_supported, color: AppTheme.softGrey)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _showCampaignImageSourceOptions,
                                        icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                                        label: const Text('Pick & Upload Image'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryPurple,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Supports PNG, JPG, JPEG, GIF. Uploads to Cloudinary.',
                                        style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _campaignImageController,
                              style: GoogleFonts.outfit(color: AppTheme.lightText),
                              decoration: const InputDecoration(
                                labelText: 'Ad Image / Thumbnail URL',
                                prefixIcon: Icon(Icons.image, color: AppTheme.neonCyan),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                              onChanged: (val) {
                                setState(() {});
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _campaignRedirectController,
                              style: GoogleFonts.outfit(color: AppTheme.lightText),
                              decoration: const InputDecoration(
                                labelText: 'Redirect / Website URL',
                                prefixIcon: Icon(Icons.link, color: AppTheme.neonGreen),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      provider.isLoading
                          ? const Center(child: SpinKitThreeBounce(color: AppTheme.primaryPurple, size: 30))
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _save,
                                child: const Text('Save System Configs'),
                              ),
                            )
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
