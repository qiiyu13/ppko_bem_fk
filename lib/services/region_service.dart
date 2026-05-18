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
      'parentId': ?parentId,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getStats() async {
    final response = await ApiService.get('/regions/stats');
    return response.data['data'] as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getUsersByRegion(String regionId) async {
    final response = await ApiService.get('/regions/$regionId/users');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }
}
