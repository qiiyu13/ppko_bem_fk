import 'api_service.dart';
import 'cache_service.dart';

class ScreeningService {
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await ApiService.get('/screenings/stats');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      return {'total': 0, 'byCategory': {}};
    }
  }

  static Future<List<Map<String, dynamic>>> getScreenings({String? profileId}) async {
    final queryParams = <String, dynamic>{};
    if (profileId != null) queryParams['profileId'] = profileId;

    try {
      final response = await ApiService.get('/screenings', queryParameters: queryParams);
      final List<dynamic> data = response.data['data'] ?? [];
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
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
    final requestData = <String, dynamic>{
      'profileId': profileId,
      'systolic': systolic,
      'diastolic': diastolic,
      if (bloodSugar != null) 'bloodSugar': bloodSugar,
      if (cholesterol != null) 'cholesterol': cholesterol,
      if (uricAcid != null) 'uricAcid': uricAcid,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (notes != null) 'notes': notes,
    };

    try {
      final response = await ApiService.post('/screenings', data: requestData);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      await CacheService.queueSync('/screenings', 'POST', requestData);
      return <String, dynamic>{
        'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
        ...requestData,
        'synced': false,
      };
    }
  }
}
