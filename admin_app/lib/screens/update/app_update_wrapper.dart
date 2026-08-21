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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final updateProvider = Provider.of<UpdateProvider>(context, listen: false);
      updateProvider.configureAppType('ADMIN_APP');
      updateProvider.checkForUpdates();
    });
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
