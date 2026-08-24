import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/update_provider.dart';
import '../../core/theme/app_theme.dart';

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final updateProvider = Provider.of<UpdateProvider>(context);

    return PopScope(
      canPop: false, // Block back navigation
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Premium Dark Slate
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                // Icon / Logo Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryGold.withOpacity(0.4), width: 2),
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    size: 64,
                    color: AppTheme.primaryGold,
                  ),
                ),
                const SizedBox(height: 28),

                // Main Title
                Text(
                  updateProvider.releaseTitle.isNotEmpty
                      ? updateProvider.releaseTitle
                      : 'Mandatory Update Required',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Version Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    'Installed: v${updateProvider.currentVersion}  ➔  New: v${updateProvider.latestVersion}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Release Notes Card
                if (updateProvider.releaseNotes.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 160),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "What's New:",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            updateProvider.releaseNotes,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Download Progress / Action Area
                _buildDownloadSection(context, updateProvider),

                const Spacer(),

                // Security Tagline
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.shield_outlined, size: 14, color: Colors.white38),
                    SizedBox(width: 6),
                    Text(
                      'Verified & Encrypted Release • VRIDHI Platform',
                      style: TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadSection(BuildContext context, UpdateProvider provider) {
    switch (provider.status) {
      case DownloadStatus.idle:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => provider.downloadAndInstallApk(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download_rounded, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Update Now (In-App Download)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => provider.openWebsiteDownloadUrl(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.language_rounded, size: 20, color: AppTheme.primaryGold),
                label: const Text('Download via Website / Browser', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );


      case DownloadStatus.downloading:
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Downloading update... ${(provider.progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  provider.downloadSpeed,
                  style: const TextStyle(color: AppTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: provider.progress > 0 ? provider.progress : null,
                minHeight: 10,
                backgroundColor: const Color(0xFF334155),
                color: AppTheme.primaryGold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(provider.receivedBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${provider.totalBytes > 0 ? (provider.totalBytes / (1024 * 1024)).toStringAsFixed(1) : "?"} MB',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        );

      case DownloadStatus.verifying:
        return const Column(
          children: [
            CircularProgressIndicator(color: AppTheme.primaryGold),
            SizedBox(height: 12),
            Text(
              'Verifying SHA-256 Package Integrity...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        );

      case DownloadStatus.readyToInstall:
      case DownloadStatus.installing:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => provider.triggerInstallation(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.system_security_update_good, size: 22),
                SizedBox(width: 8),
                Text(
                  'Install APK Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );

      case DownloadStatus.failed:
        return Column(
          children: [
            if (provider.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  provider.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => provider.downloadAndInstallApk(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGold,
                  side: const BorderSide(color: AppTheme.primaryGold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Download', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );

      case DownloadStatus.success:
        return const Text(
          'Update downloaded! Please complete installation.',
          style: TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.bold),
        );
    }
  }
}
