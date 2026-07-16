import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';
import 'core/storage/storage_service.dart';

void main() async {
  // Ensure framework services are active
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  
  // Initialize storage preferences
  final storage = StorageService();
  await storage.init();

  runApp(const ReferralApp());
}
