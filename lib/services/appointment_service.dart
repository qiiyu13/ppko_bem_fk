import 'api_service.dart';
import 'cache_service.dart';

class AppointmentService {
  static Future<List<Map<String, dynamic>>> getAppointments({String? profileId}) async {
    final queryParams = <String, dynamic>{};
    if (profileId != null) queryParams['profileId'] = profileId;

    try {
      final response = await ApiService.get('/appointments', queryParameters: queryParams);
      final List<dynamic> data = response.data['data'] ?? [];
      final appointments = data.cast<Map<String, dynamic>>();
      for (final appt in appointments) {
        await CacheService.saveAppointment(appt['id'] as String, appt);
      }
      return appointments;
    } catch (e) {
      return CacheService.getAppointments();
    }
  }

  static Future<Map<String, dynamic>> createAppointment({
    required String title,
    required DateTime date,
    String? profileId,
    String? location,
    String? notes,
    String type = 'GENERAL',
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'date': date.toIso8601String(),
      'profileId': ?profileId,
      'location': ?location,
      'notes': ?notes,
      'type': type,
    };

    try {
      final response = await ApiService.post('/appointments', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      await CacheService.queueSync('/appointments', 'POST', data);
      return <String, dynamic>{
        'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
        ...data,
        'synced': false,
      };
    }
  }

  static Future<Map<String, dynamic>> updateAppointment(String id, {
    String? title,
    DateTime? date,
    String? location,
    String? notes,
    String? type,
    required DateTime updatedAt,
  }) async {
    final data = <String, dynamic>{
      'title': ?title,
      if (date != null) 'date': date.toIso8601String(),
      'location': ?location,
      'notes': ?notes,
      'type': ?type,
      'updatedAt': updatedAt.toIso8601String(),
    };

    try {
      final response = await ApiService.put('/appointments/$id', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      await CacheService.queueSync('/appointments/$id', 'PUT', data);
      return <String, dynamic>{'id': id, ...data, 'synced': false};
    }
  }

  static Future<void> deleteAppointment(String id, DateTime updatedAt) async {
    try {
      await ApiService.delete('/appointments/$id', data: {
        'updatedAt': updatedAt.toIso8601String(),
      });
    } catch (e) {
      await CacheService.queueSync('/appointments/$id', 'DELETE', {
        'updatedAt': updatedAt.toIso8601String(),
      });
    }
  }
}
