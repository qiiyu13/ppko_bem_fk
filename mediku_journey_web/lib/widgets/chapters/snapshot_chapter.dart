// lib/widgets/chapters/snapshot_chapter.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/patient.dart';
import '../animations/slide_in_card.dart';

class SnapshotChapter extends StatelessWidget {
  final Patient patient;

  const SnapshotChapter({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final currentUrl = Uri.base.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              'Status Kesehatan Saat Ini',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                if (patient.metrics.containsKey('bloodPressure'))
                  SlideInCard(
                    delay: const Duration(milliseconds: 0),
                    direction: AxisDirection.left,
                    child: _buildMetricSnapshot(
                      'Tekanan Darah',
                      patient.metrics['bloodPressure']!.current,
                      'mmHg',
                      Colors.red,
                      Icons.favorite,
                    ),
                  ),
                if (patient.metrics.containsKey('cholesterol'))
                  SlideInCard(
                    delay: const Duration(milliseconds: 100),
                    direction: AxisDirection.up,
                    child: _buildMetricSnapshot(
                      'Kolesterol',
                      patient.metrics['cholesterol']!.current,
                      'mg/dL',
                      Colors.orange,
                      Icons.water_drop,
                    ),
                  ),
                if (patient.metrics.containsKey('bloodSugar'))
                  SlideInCard(
                    delay: const Duration(milliseconds: 200),
                    direction: AxisDirection.right,
                    child: _buildMetricSnapshot(
                      'Gula Darah',
                      patient.metrics['bloodSugar']!.current,
                      'mg/dL',
                      Colors.green,
                      Icons.bloodtype,
                    ),
                  ),
                if (patient.metrics.containsKey('uricAcid'))
                  SlideInCard(
                    delay: const Duration(milliseconds: 300),
                    direction: AxisDirection.left,
                    child: _buildMetricSnapshot(
                      'Asam Urat',
                      patient.metrics['uricAcid']!.current,
                      'mg/dL',
                      Colors.purple,
                      Icons.science,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            SlideInCard(
              delay: const Duration(milliseconds: 500),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'Bagikan Perjalanan Ini',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      QrImageView(
                        data: currentUrl,
                        version: QrVersions.auto,
                        size: 150,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scan untuk melihat perjalanan kesehatan ${patient.name}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // Copy to clipboard
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Link disalin ke clipboard'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy Link'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Share functionality
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSnapshot(
    String title,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
