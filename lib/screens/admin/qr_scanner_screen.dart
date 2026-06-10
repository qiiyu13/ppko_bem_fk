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
  bool _torchOn = false;
  DateTime? _lastErrorAt;

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

    setState(() => _isProcessing = true);
    final qrData = barcode!.rawValue;

    try {
      final data = jsonDecode(qrData!) as Map<String, dynamic>;

      if (!data.containsKey('profileId') || !data.containsKey('name')) {
        _showError('QR Code tidak valid');
        setState(() => _isProcessing = false);
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
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    // Throttle: continuous detection of the same invalid code would
    // otherwise spam snackbars every frame.
    final now = DateTime.now();
    if (_lastErrorAt != null &&
        now.difference(_lastErrorAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastErrorAt = now;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.statusRed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleTorch() async {
    await _controller?.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  Widget _buildCameraError(BuildContext context, MobileScannerException error) {
    final isPermission =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPermission ? Icons.no_photography_outlined : Icons.error_outline,
            size: 56,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          Text(
            isPermission
                ? 'Izin kamera ditolak'
                : 'Kamera tidak dapat dibuka',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPermission
                ? 'Buka pengaturan aplikasi lalu izinkan akses kamera untuk memindai QR pasien.'
                : 'Tutup layar ini lalu coba lagi.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
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
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            tooltip: _torchOn ? 'Matikan senter' : 'Nyalakan senter',
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) =>
                _buildCameraError(context, error),
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
