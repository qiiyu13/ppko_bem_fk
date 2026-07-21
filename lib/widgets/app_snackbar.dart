import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Single snackbar style for the whole app: always floating, colored by intent.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool success = false,
  bool error = false,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor:
          success ? AppColors.statusGreen : (error ? AppColors.statusRed : null),
      action: action,
      duration: duration,
    ),
  );
}
