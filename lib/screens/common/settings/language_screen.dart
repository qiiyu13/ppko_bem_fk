import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bahasa',
          style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            flag: '🇮🇩',
            label: 'Bahasa Indonesia',
            selected: true,
            enabled: true,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _tile(
            flag: '🇬🇧',
            label: 'English',
            selected: false,
            enabled: false,
            onTap: () {},
            trailingText: 'Segera hadir',
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required String flag,
    required String label,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
    String? trailingText,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surface,
            width: selected ? 2 : 1,
          ),
        ),
        child: ListTile(
          leading: Text(flag, style: const TextStyle(fontSize: 28)),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          trailing: selected
              ? const Icon(Icons.check_circle, color: AppColors.primary)
              : (trailingText != null
                  ? Text(trailingText,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))
                  : null),
          onTap: enabled ? onTap : null,
        ),
      ),
    );
  }
}
