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
        return 'Risiko Tinggi';
      case 'attention':
        return 'Waspada';
      case 'normal':
        return 'Normal';
      default:
        return 'Tidak Diketahui';
    }
  }

  /// IRD score thresholds: >= 1.0 high, >= 0.75 attention, else normal.
  static String irdCategoryFromScore(double score) {
    if (score >= 1.0) return 'high';
    if (score >= 0.75) return 'attention';
    return 'normal';
  }
}
