import 'package:flutter/material.dart';
import 'app.dart';
import 'core/storage/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final storage = StorageService();
  await storage.init();

  runApp(const AdminApp());
}
