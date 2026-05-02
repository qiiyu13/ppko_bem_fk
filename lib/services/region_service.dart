import 'api_service.dart';

class RegionService {
  static Future<List<Map<String, dynamic>>> getRegions() async {
    final response = await ApiService.get('/regions');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createRegion({
    required String type,
    required String name,
    String? parentId,
  }) async {
    final response = await ApiService.post('/regions', data: {
      'type': type,
      'name': name,
      if (parentId != null) 'parentId': parentId,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getResidents({String? regionId}) async {
    final queryParams = <String, dynamic>{};
    if (regionId != null) queryParams['regionId'] = regionId;
    final response = await ApiService.get('/regions/residents', queryParameters: queryParams);
    final List<dynamic> data = response.data['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createResident({
    required String regionId,
    required String name,
    required String nik,
    required String gender,
    required DateTime birthDate,
    String? phone,
    String? address,
  }) async {
    final response = await ApiService.post('/regions/residents', data: {
      'regionId': regionId,
      'name': name,
      'nik': nik,
      'gender': gender,
      'birthDate': birthDate.toIso8601String(),
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateResident(String id, {
    String? regionId,
    String? name,
    String? nik,
    String? gender,
    DateTime? birthDate,
    String? phone,
    String? address,
  }) async {
    final response = await ApiService.put('/regions/residents/$id', data: {
      if (regionId != null) 'regionId': regionId,
      if (name != null) 'name': name,
      if (nik != null) 'nik': nik,
      if (gender != null) 'gender': gender,
      if (birthDate != null) 'birthDate': birthDate.toIso8601String(),
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
    });
    return response.data['data'] as Map<String, dynamic>;
  }
}
