import 'api_service.dart';

class AdminService {
  static Future<Map<String, dynamic>> getPatients({
    int page = 1,
    int limit = 20,
    String? search,
    String? irdCategory,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null) queryParams['search'] = search;
    if (irdCategory != null) queryParams['irdCategory'] = irdCategory;
    final response = await ApiService.get('/admin/patients', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getPatientDetail(String patientId) async {
    final response = await ApiService.get('/admin/patients/$patientId');
    return response.data['data'] as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getUsers({String? role}) async {
    final queryParams = <String, dynamic>{};
    if (role != null) queryParams['role'] = role;
    final response = await ApiService.get('/admin/users', queryParameters: queryParams);
    final List<dynamic> data = response.data['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createUser({
    required String kkNumber,
    required String responsibleName,
    required String password,
    String? phone,
    String role = 'ADMIN',
    bool isActive = true,
    String? regionId,
  }) async {
    final response = await ApiService.post('/admin/users', data: {
      'kkNumber': kkNumber,
      'responsibleName': responsibleName,
      'password': password,
      'phone': ?phone,
      'role': role,
      'isActive': isActive,
      'regionId': ?regionId,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateUser(String id, {
    String? responsibleName,
    String? phone,
    String? role,
    bool? isActive,
    String? password,
    String? regionId,
    required DateTime updatedAt,
  }) async {
    final response = await ApiService.put('/admin/users/$id', data: {
      'responsibleName': ?responsibleName,
      'phone': ?phone,
      'role': ?role,
      'isActive': ?isActive,
      'password': ?password,
      'regionId': ?regionId,
      'updatedAt': updatedAt.toIso8601String(),
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  static Future<void> deleteUser(String id, DateTime updatedAt) async {
    await ApiService.delete('/admin/users/$id', data: {
      'updatedAt': updatedAt.toIso8601String(),
    });
  }
}
