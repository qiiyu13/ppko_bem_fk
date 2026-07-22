import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/responsive_size.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  String? _notesTime() {
    final raw = appointment['notes'];
    if (raw is! String || raw.isEmpty) return null;
    try {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      return parsed['time'] as String?;
    } catch (_) {
      return null;
    }
  }

  String? _mapsUrl() {
    final raw = appointment['notes'];
    if (raw is! String || raw.isEmpty) return null;
    try {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      return parsed['mapsUrl'] as String?;
    } catch (_) {
      return null;
    }
  }

  String? _notesText() {
    final raw = appointment['notes'];
    if (raw is! String || raw.isEmpty) return null;
    try {
      jsonDecode(raw);
      return null;
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    final title = appointment['title']?.toString() ?? '-';
    final type = appointment['type']?.toString() ?? '';
    final location = appointment['location']?.toString() ?? '';
    DateTime? date;
    try {
      date = DateTime.parse(appointment['date'] as String).toLocal();
    } catch (_) {}
    final dateLabel = date != null
        ? DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date)
        : '-';
    final timeFromNotes = _notesTime();
    final timeLabel = timeFromNotes ??
        (date != null
            ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
            : '-');
    final mapsUrl = _mapsUrl();
    final notesText = _notesText();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Detail Jadwal',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surface, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Hanya Lihat',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (type.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            type,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: ResponsiveSize.spacingMedium),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveSize.fontXLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveSize.spacingMedium),
            _infoTile(Icons.calendar_today, 'Tanggal', dateLabel),
            _infoTile(Icons.access_time, 'Waktu', timeLabel),
            if (location.isNotEmpty)
              _infoTile(Icons.location_on, 'Lokasi', location),
            if (mapsUrl != null && mapsUrl.isNotEmpty)
              _actionTile(
                Icons.map,
                'Buka di Maps',
                onTap: () async {
                  final uri = Uri.tryParse(mapsUrl);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            if (notesText != null && notesText.isNotEmpty)
              _infoTile(Icons.notes, 'Catatan', notesText),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingSmall),
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontMedium,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, {required VoidCallback onTap}) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingSmall),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontMedium,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
