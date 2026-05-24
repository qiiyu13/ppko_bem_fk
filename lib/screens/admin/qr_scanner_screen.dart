import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import '../../constants/app_colors.dart';
import '../superadmin/screens/medical_screening_screen.dart';
import 'package:mediku/utils/page_transitions.dart';

class QrScannerScreen extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onScanResult;

  const QrScannerScreen({super.key, this.onScanResult});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    _isProcessing = true;
    final qrData = barcode!.rawValue;

    try {
      final data = jsonDecode(qrData!) as Map<String, dynamic>;

      if (!data.containsKey('profileId') || !data.containsKey('name')) {
        _showError('QR Code tidak valid');
        _isProcessing = false;
        return;
      }

      if (widget.onScanResult != null) {
        widget.onScanResult!(data);
        if (mounted) Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          ParallaxPageRoute(
            page: MedicalScreeningScreen(initialPatient: data),
          ),
        );
      }
    } catch (e) {
      _showError('Gagal membaca QR Code');
      _isProcessing = false;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Pindai QR Pasien'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Text(
              'Arahkan kamera ke QR Code pasien',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
