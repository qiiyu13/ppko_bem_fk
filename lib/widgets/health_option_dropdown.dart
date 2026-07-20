import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/screening_options.dart';

/// Label + styled dropdown for one health-variable option list. Used by the
/// profile forms (demografi, gaya hidup) and the medical screening form.
class HealthOptionDropdown extends StatelessWidget {
  final String label;
  final List<OptionItem> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  const HealthOptionDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surface),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                hint: const Text(
                  'Pilih',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                dropdownColor: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                items: [
                  for (final o in options)
                    DropdownMenuItem(value: o.key, child: Text(o.label)),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading matching the profile-form style ("Informasi Pribadi").
class HealthSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const HealthSectionHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
