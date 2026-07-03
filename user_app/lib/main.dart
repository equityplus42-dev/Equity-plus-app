import 'package:flutter/material.dart';
import 'app.dart';
import 'core/storage/storage_service.dart';

void main() async {
  // Ensure framework services are active
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage preferences
  final storage = StorageService();
  await storage.init();

  runApp(const ReferralApp());
}
