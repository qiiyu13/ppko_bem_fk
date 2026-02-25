import 'dart:math' as math;
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

  // Generate mock historical data for Blood Pressure
  static List<MetricReading> getMockBloodPressureHistory() {
    final List<MetricReading> readings = [];
    final now = DateTime.now();
    final random = math.Random(42);
    
    // Generate 6 months of data, bi-weekly readings
    for (int i = 180; i >= 0; i -= 14) {
      final date = now.subtract(Duration(days: i));
      // Systolic: 110-145, Diastolic: 70-95
      final systolic = 115 + random.nextInt(35);
      final diastolic = 70 + random.nextInt(25);
      
      readings.add(MetricReading(
        date: date,
        value: systolic.toDouble(),
        secondaryValue: diastolic.toDouble(),
        notes: _getRandomNote(random),
      ));
    }
    return readings;
  }

  // Generate mock historical data for Cholesterol
  static List<MetricReading> getMockCholesterolHistory() {
    final List<MetricReading> readings = [];
    final now = DateTime.now();
    final random = math.Random(43);
    
    // Generate 1 year of data, monthly readings
    for (int i = 12; i >= 0; i--) {
      final date = now.subtract(Duration(days: i * 30));
      // 170-240 mg/dL with some trend
      final baseValue = 180;
      final trend = (12 - i) * 2; // Slight upward trend
      final variation = random.nextInt(40) - 20;
      final value = baseValue + trend + variation;
      
      readings.add(MetricReading(
        date: date,
        value: value.toDouble(),
        notes: _getRandomNote(random),
      ));
    }
    return readings;
  }

  // Generate mock historical data for Blood Sugar
  static List<MetricReading> getMockBloodSugarHistory() {
    final List<MetricReading> readings = [];
    final now = DateTime.now();
    final random = math.Random(44);
    
    // Generate 3 months of data, 3x per week
    for (int i = 90; i >= 0; i -= 3) {
      final date = now.subtract(Duration(days: i));
      // 75-130 mg/dL, mostly in normal range
      final baseValue = 90;
      final variation = random.nextInt(50) - 25;
      final value = math.max(70, math.min(140, baseValue + variation));
      
      readings.add(MetricReading(
        date: date,
        value: value.toDouble(),
        notes: _getRandomNote(random),
      ));
    }
    return readings;
  }

  // Generate mock historical data for Uric Acid
  static List<MetricReading> getMockUricAcidHistory() {
    final List<MetricReading> readings = [];
    final now = DateTime.now();
    final random = math.Random(45);
    
    // Generate 6 months of data, monthly readings
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i * 30));
      // 4.0-7.5 mg/dL
      final baseValue = 5.5;
      final variation = (random.nextDouble() * 3.0) - 1.5;
      final value = math.max(3.5, math.min(8.0, baseValue + variation));
      
      readings.add(MetricReading(
        date: date,
        value: double.parse(value.toStringAsFixed(1)),
        notes: _getRandomNote(random),
      ));
    }
    return readings;
  }

  static String? _getRandomNote(math.Random random) {
    final notes = [
      'Setelah sarapan',
      'Sebelum makan',
      'Pagi hari',
      'Sore hari',
      'Setelah istirahat',
      null,
      null,
      null,
    ];
    return notes[random.nextInt(notes.length)];
  }

  static List<MetricReading> getMockHistoryForType(MetricType type) {
    switch (type) {
      case MetricType.bloodPressure:
        return getMockBloodPressureHistory();
      case MetricType.cholesterol:
        return getMockCholesterolHistory();
      case MetricType.bloodSugar:
        return getMockBloodSugarHistory();
      case MetricType.uricAcid:
        return getMockUricAcidHistory();
    }
  }

  static List<HealthMetric> getMockMetrics({
    required int age,
    required String gender,
  }) {
    final now = DateTime.now();

    // Mock values
    final bpSystolic = 122;
    final bpDiastolic = 78;
    final cholesterol = 195.0;
    final bloodSugar = 95.0;
    final uricAcid = gender.toLowerCase() == 'pria' ? 5.8 : 4.5;

    return [
      HealthMetric(
        type: MetricType.bloodPressure,
        name: 'Blood Pressure',
        nameId: 'Tekanan Darah',
        unit: 'mmHg',
        displayValue: '$bpSystolic/$bpDiastolic',
        lastUpdated: now.subtract(const Duration(hours: 2)),
        status: getBloodPressureStatus(bpSystolic, bpDiastolic, age),
        icon: Icons.favorite,
        primaryColor: const Color(0xFFE53935),
      ),
      HealthMetric(
        type: MetricType.cholesterol,
        name: 'Cholesterol',
        nameId: 'Kolesterol',
        unit: 'mg/dL',
        displayValue: cholesterol.toStringAsFixed(0),
        lastUpdated: now.subtract(const Duration(days: 1)),
        status: getCholesterolStatus(cholesterol, age),
        icon: Icons.water_drop,
        primaryColor: const Color(0xFFFB8C00),
      ),
      HealthMetric(
        type: MetricType.bloodSugar,
        name: 'Blood Sugar',
        nameId: 'Gula Darah',
        unit: 'mg/dL',
        displayValue: bloodSugar.toStringAsFixed(0),
        lastUpdated: now.subtract(const Duration(hours: 4)),
        status: getBloodSugarStatus(bloodSugar, age),
        icon: Icons.bloodtype,
        primaryColor: const Color(0xFF43A047),
      ),
      HealthMetric(
        type: MetricType.uricAcid,
        name: 'Uric Acid',
        nameId: 'Asam Urat',
        unit: 'mg/dL',
        displayValue: uricAcid.toStringAsFixed(1),
        lastUpdated: now.subtract(const Duration(days: 2)),
        status: getUricAcidStatus(uricAcid, age, gender),
        icon: Icons.science,
        primaryColor: const Color(0xFF5E35B1),
      ),
    ];
  }
}
