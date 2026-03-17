// lib/screens/journey_screen.dart

import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/data_service.dart';
import '../widgets/chapters/profile_chapter.dart';
import '../widgets/chapters/metrics_chapter.dart';
import '../widgets/chapters/timeline_chapter.dart';
import '../widgets/chapters/snapshot_chapter.dart';
import '../widgets/progress_indicator.dart';

class JourneyScreen extends StatefulWidget {
  final String patientId;

  const JourneyScreen({super.key, required this.patientId});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  Patient? _patient;
  bool _isLoading = true;
  String? _error;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    try {
      final patient = await DataService.fetchPatient(widget.patientId);
      setState(() {
        _patient = patient;
        _isLoading = false;
        if (patient == null) {
          _error = 'Pasien tidak ditemukan';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat perjalanan kesehatan...'),
            ],
          ),
        ),
      );
    }

    if (_error != null || _patient == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Terjadi kesalahan'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPatient,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          JourneyProgressIndicator(currentPage: _currentPage, totalPages: 4),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const ClampingScrollPhysics(),
              children: [
                ProfileChapter(patient: _patient!),
                MetricsChapter(patient: _patient!),
                TimelineChapter(patient: _patient!),
                SnapshotChapter(patient: _patient!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
