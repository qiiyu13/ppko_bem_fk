import '../constants/feature_flags.dart';
import 'api_service.dart';

class AuditService {
  static Future<void> logAdminAction({
    required String action,
    required String targetType,
    required String targetId,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    if (!FeatureFlags.superadminAuditFeed) return;
    try {
      await ApiService.post('/audit', data: {
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'reason': ?reason,
        'metadata': ?metadata,
      });
    } catch (_) {
    }
  }

  static Future<List<Map<String, dynamic>>> getRecent({int limit = 20}) async {
    if (!FeatureFlags.superadminAuditFeed) return [];
    try {
      final response = await ApiService.get('/audit', queryParameters: {
        'limit': limit,
      });
      final List<dynamic> data = response.data['data'] ?? [];
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
