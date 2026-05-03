import 'api_service.dart';

class AppointmentService {
  static Future<List<Map<String, dynamic>>> getAppointments({String? profileId}) async {
    final queryParams = <String, dynamic>{};
    if (profileId != null) queryParams['profileId'] = profileId;
    final response = await ApiService.get('/appointments', queryParameters: queryParams);
    final List<dynamic> data = response.data['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createAppointment({
    required String title,
    required DateTime date,
    String? profileId,
    String? location,
    String? notes,
    String type = 'GENERAL',
  }) async {
    final response = await ApiService.post('/appointments', data: {
      'title': title,
      'date': date.toIso8601String(),
      if (profileId != null) 'profileId': profileId,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      'type': type,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateAppointment(String id, {
    String? title,
    DateTime? date,
    String? location,
    String? notes,
    String? type,
    required DateTime updatedAt,
  }) async {
    final response = await ApiService.put('/appointments/$id', data: {
      if (title != null) 'title': title,
      if (date != null) 'date': date.toIso8601String(),
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      if (type != null) 'type': type,
      'updatedAt': updatedAt.toIso8601String(),
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  static Future<void> deleteAppointment(String id, DateTime updatedAt) async {
    await ApiService.delete('/appointments/$id', data: {
      'updatedAt': updatedAt.toIso8601String(),
    });
  }
}
