import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _busy = false;

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    await NotificationService.instance.setEnabled(value);
    if (mounted) setState(() => _busy = false);
  }

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
          'Notifikasi',
          style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: NotificationService.instance.enabled,
        builder: (context, enabled, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surface),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Izinkan Notifikasi',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    enabled
                        ? 'Anda akan menerima pengingat dan pemberitahuan'
                        : 'Notifikasi dinonaktifkan',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  value: enabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: _busy ? null : _toggle,
                  secondary: Icon(
                    enabled ? Icons.notifications_active : Icons.notifications_off,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Mematikan notifikasi akan menghentikan semua pengingat janji temu, hasil skrining, dan pesan dari aplikasi.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
            ],
          );
        },
      ),
    );
  }
}
