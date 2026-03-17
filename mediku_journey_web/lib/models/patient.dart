// lib/models/patient.dart

class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String? bloodType;
  final String? avatarUrl;
  final String summary;
  final Map<String, HealthMetricData> metrics;
  final List<TimelineEvent> timeline;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.bloodType,
    this.avatarUrl,
    required this.summary,
    required this.metrics,
    required this.timeline,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      bloodType: json['bloodType'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      summary: json['summary'] as String,
      metrics: (json['metrics'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, HealthMetricData.fromJson(value)),
      ),
      timeline: (json['timeline'] as List)
          .map((e) => TimelineEvent.fromJson(e))
          .toList(),
    );
  }
}

class HealthMetricData {
  final String current;
  final String? unit;
  final List<MetricReading> history;

  HealthMetricData({required this.current, this.unit, required this.history});

  factory HealthMetricData.fromJson(Map<String, dynamic> json) {
    return HealthMetricData(
      current: json['current'] as String,
      unit: json['unit'] as String?,
      history: (json['history'] as List)
          .map((e) => MetricReading.fromJson(e))
          .toList(),
    );
  }
}

class MetricReading {
  final DateTime date;
  final double value;
  final double? secondaryValue;

  MetricReading({required this.date, required this.value, this.secondaryValue});

  factory MetricReading.fromJson(Map<String, dynamic> json) {
    return MetricReading(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
      secondaryValue: json['secondaryValue'] != null
          ? (json['secondaryValue'] as num).toDouble()
          : null,
    );
  }
}

class TimelineEvent {
  final DateTime date;
  final String type;
  final String title;
  final String description;
  final String status;

  TimelineEvent({
    required this.date,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
    );
  }
}
