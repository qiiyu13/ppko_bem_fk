import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../constants/app_colors.dart';

class BPGaugePainter extends CustomPainter {
  final double systolic;
  final double diastolic;
  final Color arcColor;

  BPGaugePainter({
    required this.systolic,
    required this.diastolic,
    required this.arcColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 30;

    // Calculate needle position FIRST
    // Gauge range: 80-180 for systolic
    final normalizedValue = (systolic - 80) / 100;
    final adjustedValue = (normalizedValue * 0.85) + 0.15;
    final clampedValue = adjustedValue.clamp(0.05, 0.95);
    final needleAngle = math.pi + (math.pi * clampedValue);

    // Background arc (surface color) - full semi-circle
    final backgroundPaint = Paint()
      ..color = AppColors.surface
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // Start from left (180 degrees)
      math.pi, // Sweep 180 degrees (semi-circle)
      false,
      backgroundPaint,
    );

    // Dynamic arc based on status color - STOPS at needle position!
    final statusPaint = Paint()
      ..color = arcColor
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw arc from left (math.pi) to needle position
    final sweepAngle = needleAngle - math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // Start from left
      sweepAngle, // Go up to needle position
      false,
      statusPaint,
    );

    // Draw "Low" text on the left side of the gauge
    final textPainterLow = TextPainter(
      text: TextSpan(
        text: 'Low',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterLow.layout();

    // Position "Low" at the left end of the arc
    final lowAngle = math.pi + 0.15;
    final lowX =
        center.dx +
        (radius - 35) * math.cos(lowAngle) -
        textPainterLow.width / 2;
    final lowY =
        center.dy +
        (radius - 35) * math.sin(lowAngle) -
        textPainterLow.height / 2;
    textPainterLow.paint(canvas, Offset(lowX, lowY));

    // Draw "High" text on the right side of the gauge
    final textPainterHigh = TextPainter(
      text: TextSpan(
        text: 'High',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterHigh.layout();

    // Position "High" at the right end of the arc
    final highAngle = 0 - 0.15;
    final highX =
        center.dx +
        (radius - 35) * math.cos(highAngle) -
        textPainterHigh.width / 2;
    final highY =
        center.dy +
        (radius - 35) * math.sin(highAngle) -
        textPainterHigh.height / 2;
    textPainterHigh.paint(canvas, Offset(highX, highY));

    // Draw needle with shadow
    final needleLength = radius - 40;
    final needleEnd = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    // Needle shadow
    final shadowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final shadowEnd = Offset(
      center.dx + (needleLength - 2) * math.cos(needleAngle),
      center.dy + (needleLength - 2) * math.sin(needleAngle) + 2,
    );
    canvas.drawLine(center, shadowEnd, shadowPaint);

    // Main needle
    final needlePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);

    // Draw center dot with gradient
    final centerDotPaint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.primarySurface, AppColors.primary],
      ).createShader(Rect.fromCircle(center: center, radius: 10));

    canvas.drawCircle(center, 8, centerDotPaint);

    // Inner highlight dot
    final highlightPaint = Paint()
      ..color = AppColors.background.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(center.dx - 2, center.dy - 2), 3, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BPGaugeWidget extends StatelessWidget {
  final double systolic;
  final double diastolic;

  const BPGaugeWidget({
    super.key,
    required this.systolic,
    required this.diastolic,
  });

  // Get BP status based on AHA guidelines
  static Map<String, dynamic> getBPStatus(double sys, double dia) {
    // Hypotension (Too Low): 90/60 mmHg or lower
    if (sys <= 90 && dia <= 60) {
      return {'status': 'RENDAH', 'color': AppColors.statusRed};
    }

    // Hypertension Stage 2 (Too High): 140 or higher systolic OR 90 or higher diastolic
    if (sys >= 140 || dia >= 90) {
      return {'status': 'TINGGI STAGE 2', 'color': AppColors.statusRed};
    }

    // Check Elevated BEFORE Stage 1 to handle 120-129 with dia <= 80
    // Elevated: 120-129 systolic AND less than or equal to 80 diastolic
    if (sys >= 120 && sys <= 129 && dia <= 80) {
      return {'status': 'ELEVATED', 'color': AppColors.primarySurface};
    }

    // Hypertension Stage 1 (Too High): 130-139 systolic OR 81-89 diastolic
    // Note: dia 80 with sys 120-129 is caught by Elevated above
    if ((sys >= 130 && sys <= 139) || (dia >= 81 && dia <= 89)) {
      return {'status': 'TINGGI STAGE 1', 'color': AppColors.statusRed};
    }

    // Normal: Less than 120 systolic AND less than 80 diastolic
    if (sys < 120 && dia < 80) {
      return {'status': 'NORMAL', 'color': AppColors.primarySurface};
    }

    // Borderline cases
    if (sys < 130 && dia <= 80) {
      return {'status': 'ELEVATED', 'color': AppColors.primarySurface};
    }

    // Catch any remaining cases
    if (dia >= 80) {
      return {'status': 'TINGGI STAGE 1', 'color': AppColors.error};
    }

    return {'status': 'NORMAL', 'color': AppColors.primarySurface};
  }

  @override
  Widget build(BuildContext context) {
    final statusData = getBPStatus(systolic, diastolic);
    final String status = statusData['status'];
    final Color statusColor = statusData['color'];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate proportional gauge size
        // Width: 85% of available space, max 320, min 240
        final gaugeWidth = (constraints.maxWidth * 0.85).clamp(240.0, 320.0);
        // Height: maintain aspect ratio ~0.54
        final gaugeHeight = gaugeWidth * 0.54;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gauge - fills available width proportionally
            CustomPaint(
              size: Size(gaugeWidth, gaugeHeight),
              painter: BPGaugePainter(
                systolic: systolic,
                diastolic: diastolic,
                arcColor: statusColor,
              ),
            ),
            // BP Reading - centered
            Transform.translate(
              offset: const Offset(0, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${systolic.toInt()}/${diastolic.toInt()}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'mmHg',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Status badge - centered
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getStatusIcon(status), color: statusColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'RENDAH':
        return Icons.arrow_downward;
      case 'NORMAL':
        return Icons.check_circle;
      case 'ELEVATED':
        return Icons.trending_up;
      case 'TINGGI STAGE 1':
        return Icons.warning;
      case 'TINGGI STAGE 2':
        return Icons.error;
      default:
        return Icons.check_circle;
    }
  }
}
