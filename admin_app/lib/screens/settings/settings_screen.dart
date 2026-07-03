import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _l1Controller = TextEditingController();
    _l2Controller = TextEditingController();
    _l3Controller = TextEditingController();
    _depthController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<AdminSettingsProvider>(context, listen: false);
      await provider.fetchSettings();
      
      final currentSettings = provider.settings;
      _l1Controller.text = currentSettings['points_level_1'] ?? '100';
      _l2Controller.text = currentSettings['points_level_2'] ?? '50';
      _l3Controller.text = currentSettings['points_level_3'] ?? '25';
      _depthController.text = currentSettings['max_hierarchy_depth'] ?? '3';
      
      setState(() {
        _requireApproval = currentSettings['require_admin_approval'] == 'true';
      });
    });
  }

  @override
  void dispose() {
    _l1Controller.dispose();
    _l2Controller.dispose();
    _l3Controller.dispose();
    _depthController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AdminSettingsProvider>(context, listen: false);

    bool s1 = await provider.updateSetting('points_level_1', _l1Controller.text.trim());
    bool s2 = await provider.updateSetting('points_level_2', _l2Controller.text.trim());
    bool s3 = await provider.updateSetting('points_level_3', _l3Controller.text.trim());
    bool s4 = await provider.updateSetting('max_hierarchy_depth', _depthController.text.trim());
    bool s5 = await provider.updateSetting('require_admin_approval', _requireApproval.toString());

    if (mounted) {
      if (s1 && s2 && s3 && s4 && s5) {
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
                              activeThumbColor: AppTheme.primaryPurple,
                              contentPadding: EdgeInsets.zero,
                            )
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
