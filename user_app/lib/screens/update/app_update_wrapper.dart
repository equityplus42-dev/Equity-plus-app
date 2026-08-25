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

class _AppUpdateWrapperState extends State<AppUpdateWrapper> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final updateProvider = Provider.of<UpdateProvider>(context, listen: false);
      updateProvider.configureAppType('USER_APP');
      updateProvider.checkForUpdates();
    });

    // Periodically re-check version every 4 seconds so that deactivating or deleting a release in admin instantly returns user to app dashboard
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        final updateProvider = Provider.of<UpdateProvider>(context, listen: false);
        updateProvider.checkForUpdates();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final updateProvider = Provider.of<UpdateProvider>(context);

    // If force update is active, block everything with full-screen ForceUpdateScreen
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
