import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';
import 'core/storage/storage_service.dart';
import 'providers/update_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  
  final storage = StorageService();
  await storage.init();

  await UpdateProvider().initPackageInfo(appType: 'ADMIN_APP');

  runApp(const AdminApp());
}
