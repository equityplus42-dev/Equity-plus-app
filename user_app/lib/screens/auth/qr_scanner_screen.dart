import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanCompleted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_isScanCompleted) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? rawValue = barcodes.first.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        _isScanCompleted = true;
        final String referralCode = _parseReferralCode(rawValue);
        Navigator.pop(context, referralCode);
      }
    }
  }

  String _parseReferralCode(String rawValue) {
    String value = rawValue.trim();
    if (value.contains('/')) {
      try {
        final Uri uri = Uri.parse(value.startsWith('http') ? value : 'http://$value');
        
        // 1. Try query parameters 'ref' or 'code'
        final ref = uri.queryParameters['ref'] ?? uri.queryParameters['code'];
        if (ref != null && ref.isNotEmpty) {
          return ref.trim();
        }
        
        // 2. Try known path segment markers
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segments.isNotEmpty) {
          final rIndex = segments.indexOf('r');
          final refIndex = segments.indexOf('ref');
          final registerIndex = segments.indexOf('register');
          
          if (rIndex != -1 && rIndex < segments.length - 1) {
            return segments[rIndex + 1].trim();
          } else if (refIndex != -1 && refIndex < segments.length - 1) {
            return segments[refIndex + 1].trim();
          } else if (registerIndex != -1 && registerIndex < segments.length - 1) {
            return segments[registerIndex + 1].trim();
          }
          
          // 3. Fallback to the very last segment of the path
          return segments.last.trim();
        }
      } catch (_) {
        final parts = value.split('/');
        if (parts.isNotEmpty) {
          return parts.last.trim();
        }
      }
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Referral QR'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                  case TorchState.unavailable:
                  default:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                  case CameraFacing.unknown:
                  default:
                    return const Icon(Icons.camera);
                }
              },
            ),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryPurple, width: 4),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Align QR code inside the frame',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
