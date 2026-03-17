// lib/widgets/chapters/profile_chapter.dart

import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../animations/slide_in_card.dart';

class ProfileChapter extends StatelessWidget {
  final Patient patient;

  const ProfileChapter({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal.shade50, Colors.white],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SlideInCard(
            delay: const Duration(milliseconds: 0),
            child: _buildInfoCard(
              context,
              icon: Icons.person,
              label: 'Nama',
              value: patient.name,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 16),
          SlideInCard(
            delay: const Duration(milliseconds: 200),
            direction: AxisDirection.left,
            child: _buildInfoCard(
              context,
              icon: Icons.cake,
              label: 'Usia',
              value: '${patient.age} tahun',
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          SlideInCard(
            delay: const Duration(milliseconds: 400),
            direction: AxisDirection.right,
            child: _buildInfoCard(
              context,
              icon: Icons.bloodtype,
              label: 'Golongan Darah',
              value: patient.bloodType ?? '-',
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          SlideInCard(
            delay: const Duration(milliseconds: 600),
            child: _buildInfoCard(
              context,
              icon: patient.gender == 'Pria' ? Icons.male : Icons.female,
              label: 'Jenis Kelamin',
              value: patient.gender,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 32),
          SlideInCard(
            delay: const Duration(milliseconds: 800),
            child: Text(
              patient.summary,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
