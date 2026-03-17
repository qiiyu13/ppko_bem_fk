// lib/screens/not_found_screen.dart

import 'package:flutter/material.dart';

class NotFoundScreen extends StatelessWidget {
  final String message;

  const NotFoundScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              const Text(
                'Demo tersedia untuk pasien:',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['patient-001', 'patient-002', 'demo-patient']
                    .map(
                      (id) => ActionChip(
                        label: Text(id),
                        onPressed: () {
                          // Navigate to demo
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
