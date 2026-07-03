import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../constants/app_colors.dart';
import '../models/family_profile.dart';

/// Shared QR dialog for a family profile (used by home FAB and Profil tab).
void showProfileQrDialog(BuildContext context, FamilyProfile profile) {
  final qrData = jsonEncode({
    'profileId': profile.id,
    'name': profile.name,
    'nik': profile.nik,
  });

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        profile.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // QrImageView uses a LayoutBuilder internally, which cannot report
          // intrinsic dimensions; AlertDialog measures its content with
          // IntrinsicWidth, so the QR must live inside tight constraints.
          SizedBox.square(
            dimension: 220,
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
              embeddedImage: const AssetImage('assets/icon/logo_only.png'),
              embeddedImageStyle:
                  const QrEmbeddedImageStyle(size: Size(44, 44)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'NIK: ${profile.formattedNik}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Tutup',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
