import 'api_service.dart';

/// Result of the admin/superadmin report query. [truncated] is true when the
/// backend hit its hard row cap and the set is incomplete.
typedef ScreeningReport = ({List<Map<String, dynamic>> rows, bool truncated});

class ScreeningService {
  static Future<Map<String, dynamic>> getStats() async {
    final response = await ApiService.get('/screenings/stats');
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Report listing for admins/superadmins, filtered by screener + date range.
  /// [screenedBy] is only honoured for superadmins (the backend forces admins
  /// to their own id). [from]/[to] are inclusive day bounds. Throws on failure
  /// so callers can show a real error state instead of a fake empty one.
  static Future<ScreeningReport> getScreeningReport({
    String? screenedBy,
    DateTime? from,
    DateTime? to,
  }) async {
    final queryParams = <String, dynamic>{};
    if (screenedBy != null) queryParams['screenedBy'] = screenedBy;
    // Always send UTC instants — a timezone-less local string would be
    // re-interpreted in the server's zone.
    if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
    if (to != null) queryParams['to'] = to.toUtc().toIso8601String();

    final response = await ApiService.get('/screenings/report',
        queryParameters: queryParams);
    final List<dynamic> data = response.data['data'] ?? [];
    final meta = response.data['meta'] as Map<String, dynamic>?;
    return (
      rows: data.cast<Map<String, dynamic>>(),
      truncated: meta?['truncated'] == true,
    );
  }
}
