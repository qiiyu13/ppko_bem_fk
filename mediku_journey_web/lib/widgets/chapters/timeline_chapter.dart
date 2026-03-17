// lib/widgets/chapters/timeline_chapter.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/patient.dart';
import '../animations/slide_in_card.dart';

class TimelineChapter extends StatelessWidget {
  final Patient patient;

  const TimelineChapter({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Perjalanan Medis',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: patient.timeline.length,
              itemBuilder: (context, index) {
                final event = patient.timeline[index];
                final isLeft = index % 2 == 0;
                final delay = Duration(milliseconds: index * 300);

                return TimelineItem(
                  event: event,
                  isLeft: isLeft,
                  delay: delay,
                  isLast: index == patient.timeline.length - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineItem extends StatelessWidget {
  final TimelineEvent event;
  final bool isLeft;
  final Duration delay;
  final bool isLast;

  const TimelineItem({
    super.key,
    required this.event,
    required this.isLeft,
    required this.delay,
    required this.isLast,
  });

  IconData get _icon {
    switch (event.type) {
      case 'appointment':
        return Icons.event;
      case 'lab':
        return Icons.science;
      case 'medication':
        return Icons.medication;
      default:
        return Icons.info;
    }
  }

  Color get _color {
    switch (event.status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          if (isLeft) ...[
            Expanded(
              child: SlideInCard(
                delay: delay,
                direction: AxisDirection.left,
                child: _buildEventCard(),
              ),
            ),
            _buildTimelineLine(),
            const Expanded(child: SizedBox()),
          ] else ...[
            const Expanded(child: SizedBox()),
            _buildTimelineLine(),
            Expanded(
              child: SlideInCard(
                delay: delay,
                direction: AxisDirection.right,
                child: _buildEventCard(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon, color: _color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy').format(event.date),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              event.description,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineLine() {
    return Container(
      width: 40,
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
          if (!isLast)
            Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}
