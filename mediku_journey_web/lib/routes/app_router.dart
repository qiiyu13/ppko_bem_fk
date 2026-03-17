// lib/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/journey_screen.dart';
import '../screens/not_found_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          // Check if patient_id is provided on root route
          final patientId = state.uri.queryParameters['patient_id'];
          if (patientId != null && patientId.isNotEmpty) {
            return JourneyScreen(patientId: patientId);
          }
          return const NotFoundScreen(
            message:
                'Silakan scan QR code untuk melihat perjalanan kesehatan pasien',
          );
        },
      ),
      GoRoute(
        path: '/journey',
        builder: (context, state) {
          final patientId = state.uri.queryParameters['patient_id'];
          if (patientId == null || patientId.isEmpty) {
            return const NotFoundScreen(message: 'ID Pasien tidak ditemukan');
          }
          return JourneyScreen(patientId: patientId);
        },
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(message: 'Halaman tidak ditemukan: ${state.uri.path}'),
  );
}
