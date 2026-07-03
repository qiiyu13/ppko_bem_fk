import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zxing2/qrcode.dart';

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
  // mobile_scanner only ships Android/iOS/macOS/web implementations;
  // on Linux/Windows we fall back to decoding a picked image instead.
  static final bool _cameraSupported =
      kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  MobileScannerController? _controller;
  final TextEditingController _pasteController = TextEditingController();
  bool _isProcessing = false;
  bool _torchOn = false;
  DateTime? _lastErrorAt;

  @override
  void initState() {
    super.initState();
    if (_cameraSupported) {
      _controller = MobileScannerController();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null) return;
    _handleRawValue(rawValue);
  }

  void _handleRawValue(String qrData) {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;

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

  Future<void> _pickAndDecodeImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isProcessing = true);
    try {
      final bytes = await picked.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        _showError('File bukan gambar yang valid');
        return;
      }

      final source = RGBLuminanceSource(
        decoded.width,
        decoded.height,
        decoded
            .convert(numChannels: 4)
            .getBytes(order: img.ChannelOrder.abgr)
            .buffer
            .asInt32List(),
      );
      final result =
          QRCodeReader().decode(BinaryBitmap(GlobalHistogramBinarizer(source)));

      setState(() => _isProcessing = false);
      _handleRawValue(result.text);
    } on ReaderException {
      _showError('QR Code tidak ditemukan pada gambar');
    } catch (e) {
      _showError('Gagal membaca QR Code');
    } finally {
      if (mounted && _isProcessing) {
        setState(() => _isProcessing = false);
      }
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

  Widget _buildCameraScanner() {
    return Stack(
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
    );
  }

  Widget _buildDesktopFallback() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.qr_code_scanner,
                size: 56,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              const Text(
                'Kamera tidak tersedia di desktop',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih gambar QR Code pasien, atau tempel isi QR secara manual.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isProcessing ? null : _pickAndDecodeImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Pilih Gambar QR'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _pasteController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tempel isi QR Code di sini…',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isProcessing
                    ? null
                    : () => _handleRawValue(_pasteController.text.trim()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Proses'),
              ),
              if (_isProcessing) ...[
                const SizedBox(height: 24),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ],
            ],
          ),
        ),
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
          if (_cameraSupported)
            IconButton(
              icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
              tooltip: _torchOn ? 'Matikan senter' : 'Nyalakan senter',
              onPressed: _toggleTorch,
            ),
        ],
      ),
      body: _cameraSupported ? _buildCameraScanner() : _buildDesktopFallback(),
    );
  }
}
