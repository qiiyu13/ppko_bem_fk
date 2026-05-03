import 'package:flutter/material.dart';

enum ConflictResolution { useServer, useLocal, cancel }

class ConflictResolutionDialog extends StatelessWidget {
  final String title;
  final String message;
  final Map<String, dynamic> serverData;
  final Map<String, dynamic> localData;

  const ConflictResolutionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.serverData,
    required this.localData,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text('Server version:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_formatData(serverData)),
            const SizedBox(height: 8),
            const Text('Your version:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_formatData(localData)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(ConflictResolution.cancel),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(ConflictResolution.useServer),
          child: const Text('Use Server'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(ConflictResolution.useLocal),
          child: const Text('Overwrite'),
        ),
      ],
    );
  }

  String _formatData(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }
}
