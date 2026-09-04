import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';
import 'core/storage/storage_service.dart';
import 'providers/update_provider.dart';
import 'services/deep_link_service.dart';

void main() async {
  // Ensure framework services are active
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  
  // Initialize storage preferences
  final storage = StorageService();
  await storage.init();

  await UpdateProvider().initPackageInfo(appType: 'USER_APP');
  await DeepLinkService().initDeepLinks();

  runApp(const ReferralApp());
}
