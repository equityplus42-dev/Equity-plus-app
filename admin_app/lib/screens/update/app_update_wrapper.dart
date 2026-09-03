import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/update_provider.dart';
import 'force_update_screen.dart';
import 'optional_update_dialog.dart';

class AppUpdateWrapper extends StatefulWidget {
  final Widget child;
  const AppUpdateWrapper({super.key, required this.child});

  @override
  State<AppUpdateWrapper> createState() => _AppUpdateWrapperState();
}

class _AppUpdateWrapperState extends State<AppUpdateWrapper> with WidgetsBindingObserver {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final updateProvider = Provider.of<UpdateProvider>(context, listen: false);
      updateProvider.configureAppType('ADMIN_APP');
      updateProvider.checkForUpdates(forceRefreshPackageInfo: true);
    });

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        final updateProvider = Provider.of<UpdateProvider>(context, listen: false);
        // Only poll background checks when not actively in an update flow or download
        if (!updateProvider.forceUpdate && updateProvider.status == DownloadStatus.idle) {
          updateProvider.checkForUpdates();
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final updateProvider = Provider.of<UpdateProvider>(context, listen: false);
      // Re-read installed PackageInfo binary version from platform when resuming app
      updateProvider.checkForUpdates(forceRefreshPackageInfo: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final updateProvider = Provider.of<UpdateProvider>(context);

    if (updateProvider.forceUpdate) {
      return const ForceUpdateScreen();
    }

    return Stack(
      children: [
        widget.child,
        if (updateProvider.shouldShowOptionalDialog)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: OptionalUpdateDialog(),
              ),
            ),
          ),
      ],
    );
  }
}
