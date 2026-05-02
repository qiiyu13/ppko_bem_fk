import 'api_service.dart';

class ScreeningService {
  static Future<Map<String, dynamic>> getStats() async {
    final response = await ApiService.get('/screenings/stats');
    return response.data['data'] as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getScreenings({String? profileId}) async {
    final queryParams = <String, dynamic>{};
    if (profileId != null) queryParams['profileId'] = profileId;
    final response = await ApiService.get('/screenings', queryParameters: queryParams);
    final List<dynamic> data = response.data['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createScreening({
    required String profileId,
    required int systolic,
    required int diastolic,
    double? bloodSugar,
    double? cholesterol,
    double? uricAcid,
    double? height,
    double? weight,
    String? notes,
  }) async {
    final response = await ApiService.post('/screenings', data: {
      'profileId': profileId,
      'systolic': systolic,
      'diastolic': diastolic,
      if (bloodSugar != null) 'bloodSugar': bloodSugar,
      if (cholesterol != null) 'cholesterol': cholesterol,
      if (uricAcid != null) 'uricAcid': uricAcid,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (notes != null) 'notes': notes,
    });
    return response.data['data'] as Map<String, dynamic>;
  }
}
