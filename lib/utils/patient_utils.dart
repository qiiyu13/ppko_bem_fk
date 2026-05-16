import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PatientUtils {
  PatientUtils._();

  static Color riskColor(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return AppColors.error;
      case 'attention':
        return AppColors.warning;
      case 'normal':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  static String riskLabel(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return 'High Risk';
      case 'attention':
        return 'Attention';
      case 'normal':
        return 'Normal';
      default:
        return 'Unknown';
    }
  }
}
