import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state_widget.dart';
import '../superadmin/screens/appointment_detail_screen.dart';
import '../admin/admin_patient_detail_screen.dart';
import 'jadwal_saya_screen.dart';
import 'laporan_saya_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.fetchFromApi();
  }

  Future<void> _markAllRead() async {
    await NotificationService.instance.markAllRead();
    if (mounted) setState(() {});
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Notifikasi'),
        content: const Text(
          'Semua notifikasi akan dihapus permanen. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.statusRed),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await NotificationService.instance.deleteAll();
    if (mounted) setState(() {});
  }

  Future<void> _handleNotificationTap(NotificationModel notif) async {
    await NotificationService.instance.markRead(notif.id);
    if (!mounted) return;

    if (notif.type == NotificationType.general) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    try {
      final me = await AuthService.getMe();
      final role = (me?['role'] ?? '').toString();

      if (notif.type == NotificationType.appointment) {
        if (role == 'PATIENT') {
          // Patients never see admin appointment detail — send them to
          // their own schedule screen instead.
          if (!mounted) return;
          Navigator.push(
            context,
            ParallaxPageRoute(
              page: JadwalSayaScreen(onBack: () {}, isEmbedded: false),
            ),
          );
          return;
        }
        final appointmentId = notif.data?['appointmentId'] as String?;
        if (appointmentId == null) {
          _showError('Data notifikasi tidak valid');
          return;
        }
        try {
          final appointment = await AppointmentService.getAppointmentById(
            appointmentId,
          );
          if (!mounted) return;
          Navigator.push(
            context,
            ParallaxPageRoute(
              page: AppointmentDetailScreen(appointment: appointment),
            ),
          );
        } catch (_) {
          _showError('Jadwal tidak ditemukan atau telah dihapus');
        }
      } else if (notif.type == NotificationType.screeningResult) {
        if (role == 'PATIENT') {
          final profile = ProfileService.instance.activeProfile;
          final gender = profile?.gender ?? 'Pria';
          if (!mounted) return;
          Navigator.push(
            context,
            ParallaxPageRoute(page: LaporanSayaScreen(gender: gender)),
          );
        } else {
          final profileId = notif.data?['profileId'] as String?;
          if (profileId == null) {
            _showError('Data notifikasi tidak valid');
            return;
          }
          if (!mounted) return;
          Navigator.push(
            context,
            ParallaxPageRoute(
              page: AdminPatientDetailScreen(patient: {'profileId': profileId}),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    showAppSnackBar(context, message, error: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('Notifikasi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          ValueListenableBuilder<List<NotificationModel>>(
            valueListenable: NotificationService.instance.notifications,
            builder: (context, list, _) {
              if (list.isEmpty) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'mark_all') _markAllRead();
                  if (value == 'delete_all') _deleteAll();
                },
                itemBuilder: (_) => [
                  if (list.any((n) => !n.isRead))
                    const PopupMenuItem(
                      value: 'mark_all',
                      child: Row(
                        children: [
                          Icon(
                            Icons.done_all,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text('Tandai semua dibaca'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: AppColors.statusRed,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Hapus semua',
                          style: TextStyle(color: AppColors.statusRed),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ValueListenableBuilder<List<NotificationModel>>(
            valueListenable: NotificationService.instance.notifications,
            builder: (context, list, _) {
              if (list.isEmpty) {
                return _buildEmpty();
              }
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: NotificationService.instance.fetchFromApi,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.divider,
                  ),
                  itemBuilder: (context, index) {
                    return _NotifTile(
                      notif: list[index],
                      onTap: () => _handleNotificationTap(list[index]),
                    );
                  },
                ),
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Memuat...',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const EmptyStateWidget(
      icon: Icons.notifications_none_outlined,
      title: 'Belum ada notifikasi',
      subtitle: 'Jadwal dan hasil skrining\nakan muncul di sini',
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;

  const _NotifTile({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notif.isRead ? Colors.transparent : AppColors.primarySurface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _typeIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: notif.isRead
                          ? FontWeight.w400
                          : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(notif.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!notif.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _typeIcon() {
    IconData icon;
    Color bg;
    Color fg;
    switch (notif.type) {
      case NotificationType.appointment:
        icon = Icons.calendar_month_outlined;
        bg = AppColors.primarySurface;
        fg = AppColors.primary;
        break;
      case NotificationType.screeningResult:
        icon = Icons.assignment_outlined;
        bg = AppColors.statusAmber.withValues(alpha: 0.12);
        fg = AppColors.statusAmber;
        break;
      case NotificationType.general:
        icon = Icons.info_outline;
        bg = AppColors.surface;
        fg = AppColors.textSecondary;
    }
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: fg, size: 22),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return DateFormat('d MMM yyyy, HH:mm', 'id').format(dt);
  }
}
