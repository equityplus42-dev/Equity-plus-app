import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/update_provider.dart';
import '../../core/theme/app_theme.dart';

class OptionalUpdateDialog extends StatelessWidget {
  const OptionalUpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final updateProvider = Provider.of<UpdateProvider>(context);

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primaryGold.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.system_update_rounded, color: AppTheme.primaryGold, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        updateProvider.releaseTitle.isNotEmpty
                            ? updateProvider.releaseTitle
                            : 'Update Available',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Version v${updateProvider.latestVersion} is ready',
                        style: const TextStyle(fontSize: 12, color: AppTheme.primaryGold, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (updateProvider.releaseNotes.isNotEmpty) ...[
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    updateProvider.releaseNotes,
                    style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (updateProvider.status == DownloadStatus.downloading) ...[
              LinearProgressIndicator(
                value: updateProvider.progress > 0 ? updateProvider.progress : null,
                backgroundColor: const Color(0xFF334155),
                color: AppTheme.primaryGold,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Downloading... ${(updateProvider.progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    updateProvider.downloadSpeed,
                    style: const TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () {
                    updateProvider.dismissOptionalUpdate();
                  },
                  child: const Text('Later', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: updateProvider.status == DownloadStatus.downloading
                      ? null
                      : () {
                          if (updateProvider.status == DownloadStatus.readyToInstall ||
                              updateProvider.status == DownloadStatus.installing ||
                              updateProvider.status == DownloadStatus.success) {
                            updateProvider.triggerInstallation();
                          } else {
                            updateProvider.downloadAndInstallApk();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: updateProvider.status == DownloadStatus.readyToInstall || updateProvider.status == DownloadStatus.success
                        ? AppTheme.emerald
                        : AppTheme.primaryGold,
                    foregroundColor: updateProvider.status == DownloadStatus.readyToInstall || updateProvider.status == DownloadStatus.success
                        ? Colors.white
                        : Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    (updateProvider.status == DownloadStatus.readyToInstall || updateProvider.status == DownloadStatus.success)
                        ? 'Install Now'
                        : 'Update Now',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
