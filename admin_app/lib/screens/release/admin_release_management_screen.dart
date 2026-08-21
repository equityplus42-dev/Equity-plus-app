import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/admin_release_provider.dart';
import '../../core/theme/app_theme.dart';

class AdminReleaseManagementScreen extends StatefulWidget {
  const AdminReleaseManagementScreen({super.key});

  @override
  State<AdminReleaseManagementScreen> createState() => _AdminReleaseManagementScreenState();
}

class _AdminReleaseManagementScreenState extends State<AdminReleaseManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedAppType = 'USER_APP';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedAppType = _tabController.index == 0 ? 'USER_APP' : 'ADMIN_APP';
        });
        _loadReleases();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReleases();
    });
  }

  void _loadReleases() {
    Provider.of<AdminReleaseProvider>(context, listen: false).fetchReleases(appType: _selectedAppType);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminReleaseProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'App Version & Release Hub',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGold,
          labelColor: AppTheme.primaryGold,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'User App Releases'),
            Tab(text: 'Admin App Releases'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadReleases(),
        color: AppTheme.primaryGold,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
            : provider.releases.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.releases.length,
                    itemBuilder: (context, index) {
                      final release = provider.releases[index];
                      return _buildReleaseCard(context, release, provider);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateReleaseDialog(context),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Create New Release', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.system_update_alt_rounded, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'No releases found for $_selectedAppType',
            style: const TextStyle(fontSize: 16, color: Colors.white60),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap "Create New Release" below to publish an update APK.',
            style: TextStyle(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseCard(BuildContext context, Map<String, dynamic> release, AdminReleaseProvider provider) {
    final bool isLatest = release['isLatest'] == true;
    final bool isActive = release['isActive'] == true;
    final bool forceUpdate = release['forceUpdate'] == true;
    final String version = release['version'] ?? '1.0.0';
    final int buildNumber = release['buildNumber'] ?? 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLatest ? AppTheme.primaryGold : Colors.white10,
          width: isLatest ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'v$version ($buildNumber)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(width: 8),
                if (isLatest)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.primaryGold, width: 0.8),
                    ),
                    child: const Text(
                      'ACTIVE LATEST',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                    ),
                  )
                else if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'INACTIVE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white54),
                    ),
                  ),
                const Spacer(),
                if (forceUpdate)
                  const Chip(
                    label: Text('MANDATORY', style: TextStyle(fontSize: 9, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    backgroundColor: Color(0x33EF4444),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              release['releaseTitle'] ?? 'Release Title',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
            if (release['releaseNotes'] != null && (release['releaseNotes'] as String).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                release['releaseNotes'],
                style: const TextStyle(fontSize: 12, color: Colors.white54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Divider(color: Colors.white12, height: 24),
            Row(
              children: [
                const Icon(Icons.verified_outlined, size: 14, color: Colors.white38),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'SHA-256: ${release['sha256Checksum'] != null ? (release['sha256Checksum'] as String).substring(0, 16) + '...' : 'N/A'}',
                    style: const TextStyle(fontSize: 11, color: Colors.white38, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isLatest)
                  ElevatedButton.icon(
                    onPressed: provider.isSubmitting
                        ? null
                        : () async {
                            final success = await provider.activateRelease(release['id'], currentAppType: _selectedAppType);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Release v$version activated as latest!')),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                    label: const Text('Activate as Latest'),
                  ),
                if (isLatest)
                  OutlinedButton.icon(
                    onPressed: provider.isSubmitting
                        ? null
                        : () async {
                            final success = await provider.deactivateRelease(release['id'], currentAppType: _selectedAppType);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Release deactivated.')),
                              );
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    icon: const Icon(Icons.pause_circle_outline, size: 16),
                    label: const Text('Deactivate'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateReleaseDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CreateReleaseForm(appType: _selectedAppType),
    );
  }
}

class _CreateReleaseForm extends StatefulWidget {
  final String appType;
  const _CreateReleaseForm({required this.appType});

  @override
  State<_CreateReleaseForm> createState() => _CreateReleaseFormState();
}

class _CreateReleaseFormState extends State<_CreateReleaseForm> {
  final _formKey = GlobalKey<FormState>();
  late String _appType;
  final _versionController = TextEditingController(text: '1.1.0');
  final _buildNumberController = TextEditingController(text: '2');
  final _minVersionController = TextEditingController(text: '1.0.0');
  final _minBuildController = TextEditingController(text: '1');
  final _titleController = TextEditingController(text: 'New Performance & Stability Release');
  final _notesController = TextEditingController(text: '• Enhanced release security\n• Bug fixes and UI optimizations');
  final _downloadUrlController = TextEditingController();

  bool _forceUpdate = false;
  Uint8List? _selectedApkBytes;
  String? _selectedApkFileName;

  @override
  void initState() {
    super.initState();
    _appType = widget.appType;
  }

  Future<void> _pickApkFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedApkBytes = result.files.first.bytes;
          _selectedApkFileName = result.files.first.name;
        });
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminReleaseProvider>(context);

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upload & Publish Release (${_appType == "USER_APP" ? "User App" : "Admin App"})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // File Picker Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryGold.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.android_rounded, size: 36, color: AppTheme.primaryGold),
                    const SizedBox(height: 8),
                    Text(
                      _selectedApkFileName ?? 'No APK file selected yet',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedApkFileName != null ? AppTheme.primaryGold : Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickApkFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.folder_open_rounded, size: 18),
                      label: Text(_selectedApkFileName != null ? 'Change APK File' : 'Select APK File'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _versionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Version (e.g. 1.2.0)', labelStyle: TextStyle(color: Colors.white70)),
                validator: (v) => v == null || v.isEmpty ? 'Version is required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _buildNumberController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Build Number (e.g. 12)', labelStyle: TextStyle(color: Colors.white70)),
                validator: (v) => v == null || v.isEmpty ? 'Build number is required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Release Title', labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Release Notes', labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _downloadUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Website / Browser Download Page URL (Optional)',
                  hintText: 'https://vridhiapp.com/download',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),


              SwitchListTile(
                title: const Text('Enforce Mandatory Force Update', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Blocks obsolete client apps from logging in until updated', style: TextStyle(color: Colors.white54, fontSize: 12)),
                value: _forceUpdate,
                activeColor: AppTheme.primaryGold,
                onChanged: (val) => setState(() => _forceUpdate = val),
              ),
              const SizedBox(height: 20),

              if (provider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: provider.isSubmitting
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            final success = await provider.createRelease(
                              appType: _appType,
                              platform: 'ANDROID',
                              version: _versionController.text.trim(),
                              buildNumber: int.parse(_buildNumberController.text.trim()),
                              minimumSupportedVersion: _minVersionController.text.trim(),
                              minimumSupportedBuildNumber: int.parse(_minBuildController.text.trim()),
                              forceUpdate: _forceUpdate,
                              releaseTitle: _titleController.text.trim(),
                              releaseNotes: _notesController.text.trim(),
                              downloadUrl: _downloadUrlController.text.trim(),
                              fileBytes: _selectedApkBytes,
                              fileName: _selectedApkFileName,
                            );

                            if (success && mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Release uploaded and created successfully!')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.black,
                  ),
                  child: provider.isSubmitting
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Upload & Create Release', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
