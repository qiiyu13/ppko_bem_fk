import 'api_service.dart';

class RegionService {
  static Future<List<Map<String, dynamic>>> getVillages() async {
    final response = await ApiService.get('/regions/villages');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

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
    try {
      final response = await ApiService.get('/regions/stats');
      return response.data['data'] as Map<String, dynamic>;
    } catch (_) {
      return {'profileCount': 0};
    }
  }

  static Future<List<Map<String, dynamic>>> getUsersByRegion(String regionId) async {
    final response = await ApiService.get('/regions/$regionId/users');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  /// Paginated variant. The backend always paginates this endpoint (default
  /// limit 20), so callers that render the full list must page through it or
  /// they silently see only the first page.
  static Future<({List<Map<String, dynamic>> data, int totalPages})>
      getUsersByRegionPage(String regionId, {int page = 1, int limit = 20}) async {
    final response = await ApiService.get(
      '/regions/$regionId/users',
      queryParameters: {'page': page, 'limit': limit},
    );
    final List<dynamic> data = response.data['data'] ?? [];
    final meta = response.data['meta'] as Map<String, dynamic>?;
    return (
      data: data.cast<Map<String, dynamic>>(),
      totalPages: (meta?['totalPages'] as int?) ?? 1,
    );
  }
}
