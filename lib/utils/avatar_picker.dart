import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';

class AvatarPicker {
  static Future<File?> pickAndCrop() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 80,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Atur Foto',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: AppColors.textOnPrimary,
          activeControlsWidgetColor: AppColors.primary,
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
        IOSUiSettings(
          title: 'Atur Foto',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    if (cropped == null) return null;
    return File(cropped.path);
  }
}
