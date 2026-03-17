// lib/services/data_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient.dart';

class DataService {
  static const String _baseUrl = 'patients';

  // For local development vs production
  static String get _cdnBaseUrl {
    const isProduction = bool.fromEnvironment('dart.vm.product');
    if (isProduction) {
      // Will be served from same domain in production via vercel
      return '/$_baseUrl';
    }
    // Local development - adjust as needed
    return '/$_baseUrl';
  }

  static Future<Patient?> fetchPatient(String patientId) async {
    try {
      final url = '$_cdnBaseUrl/$patientId.json';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Patient.fromJson(json);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load patient: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching patient: $e');
    }
  }

  static Future<List<String>> listAvailablePatients() async {
    // This would ideally come from an index file
    // For now, return hardcoded demo patients
    return ['patient-001', 'patient-002', 'demo-patient'];
  }
}
