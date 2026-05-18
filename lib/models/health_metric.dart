import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum MetricType { bloodPressure, cholesterol, bloodSugar, uricAcid }

enum MetricStatus { normal, warning, critical }

class HealthMetric {
  final MetricType type;
  final String name;
  final String nameId;
  final String unit;
  final String displayValue;
  final DateTime lastUpdated;
  final MetricStatus status;
  final IconData icon;
  final Color primaryColor;
  final List<double> recentValues;

  const HealthMetric({
    required this.type,
    required this.name,
    required this.nameId,
    required this.unit,
    required this.displayValue,
    required this.lastUpdated,
    required this.status,
    required this.icon,
    required this.primaryColor,
    this.recentValues = const [],
  });
}

class ReferenceRange {
  final double min;
  final double? max;
  final String description;

  const ReferenceRange({
    required this.min,
    this.max,
    required this.description,
  });
}

class AgeBasedRange {
  final int minAge;
  final int? maxAge;
  final ReferenceRange range;

  const AgeBasedRange({required this.minAge, this.maxAge, required this.range});
}

// Historical reading model
class MetricReading {
  final DateTime date;
  final double value;
  final double? secondaryValue; // For blood pressure (diastolic)
  final String? notes;

  const MetricReading({
    required this.date,
    required this.value,
    this.secondaryValue,
    this.notes,
  });
}

class HealthMetricData {
  // Status colors using AppColors
  static Color get greenAccent => AppColors.success;
  static Color get orangeAccent => AppColors.warning;
  static Color get redAccent => AppColors.error;

  static List<AgeBasedRange> getBloodPressureRanges() {
    return [
      AgeBasedRange(
        minAge: 18,
        maxAge: 39,
        range: ReferenceRange(
          min: 90,
          max: 120,
          description: 'Normal untuk usia 18-39 tahun',
        ),
      ),
      AgeBasedRange(
        minAge: 40,
        maxAge: 59,
        range: ReferenceRange(
          min: 90,
          max: 125,
          description: 'Normal untuk usia 40-59 tahun',
        ),
      ),
      AgeBasedRange(
        minAge: 60,
        range: ReferenceRange(
          min: 90,
          max: 130,
          description: 'Normal untuk usia 60+ tahun',
        ),
      ),
    ];
  }

  static List<AgeBasedRange> getCholesterolRanges() {
    return [
      AgeBasedRange(
        minAge: 20,
        maxAge: 39,
        range: ReferenceRange(
          min: 0,
          max: 200,
          description: 'Normal untuk usia 20-39 tahun',
        ),
      ),
      AgeBasedRange(
        minAge: 40,
        maxAge: 59,
        range: ReferenceRange(
          min: 0,
          max: 220,
          description: 'Normal untuk usia 40-59 tahun',
        ),
      ),
      AgeBasedRange(
        minAge: 60,
        range: ReferenceRange(
          min: 0,
          max: 240,
          description: 'Normal untuk usia 60+ tahun',
        ),
      ),
    ];
  }

  static List<AgeBasedRange> getBloodSugarRanges() {
    return [
      AgeBasedRange(
        minAge: 18,
        maxAge: 59,
        range: ReferenceRange(
          min: 70,
          max: 100,
          description: 'Normal puasa untuk usia 18-59 tahun',
        ),
      ),
      AgeBasedRange(
        minAge: 60,
        range: ReferenceRange(
          min: 80,
          max: 110,
          description: 'Normal puasa untuk usia 60+ tahun',
        ),
      ),
    ];
  }

  static List<AgeBasedRange> getUricAcidRanges(String gender) {
    if (gender.toLowerCase() == 'pria') {
      return [
        AgeBasedRange(
          minAge: 18,
          maxAge: 59,
          range: ReferenceRange(
            min: 3.5,
            max: 7.2,
            description: 'Normal untuk pria usia 18-59 tahun',
          ),
        ),
        AgeBasedRange(
          minAge: 60,
          range: ReferenceRange(
            min: 3.5,
            max: 8.0,
            description: 'Normal untuk pria usia 60+ tahun',
          ),
        ),
      ];
    } else {
      return [
        AgeBasedRange(
          minAge: 18,
          maxAge: 59,
          range: ReferenceRange(
            min: 2.6,
            max: 6.0,
            description: 'Normal untuk wanita usia 18-59 tahun',
          ),
        ),
        AgeBasedRange(
          minAge: 60,
          range: ReferenceRange(
            min: 2.6,
            max: 7.0,
            description: 'Normal untuk wanita usia 60+ tahun',
          ),
        ),
      ];
    }
  }

  static ReferenceRange? getRangeForAge(List<AgeBasedRange> ranges, int age) {
    for (final range in ranges) {
      if (age >= range.minAge) {
        if (range.maxAge == null || age <= range.maxAge!) {
          return range.range;
        }
      }
    }
    return ranges.isNotEmpty ? ranges.first.range : null;
  }

  static MetricStatus getBloodPressureStatus(
    int systolic,
    int diastolic,
    int age,
  ) {
    final range = getRangeForAge(getBloodPressureRanges(), age);
    if (range == null) return MetricStatus.normal;

    if (systolic > range.max! || diastolic > 80) {
      if (systolic > 140 || diastolic > 90) return MetricStatus.critical;
      return MetricStatus.warning;
    }
    return MetricStatus.normal;
  }

  static MetricStatus getCholesterolStatus(double value, int age) {
    final range = getRangeForAge(getCholesterolRanges(), age);
    if (range == null) return MetricStatus.normal;

    if (value > range.max!) {
      if (value > 240) return MetricStatus.critical;
      return MetricStatus.warning;
    }
    return MetricStatus.normal;
  }

  static MetricStatus getBloodSugarStatus(double value, int age) {
    final range = getRangeForAge(getBloodSugarRanges(), age);
    if (range == null) return MetricStatus.normal;

    if (value > range.max!) {
      if (value > 126) return MetricStatus.critical;
      return MetricStatus.warning;
    } else if (value < range.min) {
      return MetricStatus.warning;
    }
    return MetricStatus.normal;
  }

  static MetricStatus getUricAcidStatus(double value, int age, String gender) {
    final range = getRangeForAge(getUricAcidRanges(gender), age);
    if (range == null) return MetricStatus.normal;

    if (value > range.max!) {
      if (value > (gender.toLowerCase() == 'pria' ? 8.0 : 7.0)) {
        return MetricStatus.critical;
      }
      return MetricStatus.warning;
    } else if (value < range.min) {
      return MetricStatus.warning;
    }
    return MetricStatus.normal;
  }

  static Color getStatusColor(MetricStatus status) {
    switch (status) {
      case MetricStatus.normal:
        return greenAccent;
      case MetricStatus.warning:
        return orangeAccent;
      case MetricStatus.critical:
        return redAccent;
    }
  }

  static String getStatusLabel(MetricStatus status) {
    switch (status) {
      case MetricStatus.normal:
        return 'Normal';
      case MetricStatus.warning:
        return 'Waspada';
      case MetricStatus.critical:
        return 'Perhatian';
    }
  }

  static IconData getStatusIcon(MetricStatus status) {
    switch (status) {
      case MetricStatus.normal:
        return Icons.check_circle;
      case MetricStatus.warning:
        return Icons.warning;
      case MetricStatus.critical:
        return Icons.error;
    }
  }

}
