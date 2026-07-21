import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/appointment_service.dart';
import '../../services/websocket_service.dart';
import '../../utils/date_utils.dart';
import '../../utils/responsive_size.dart';
import '../../utils/schedule_status.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/error_state_widget.dart';
import '../superadmin/screens/schedule_form_screen.dart';
import 'package:mediku/utils/page_transitions.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  bool _isLoading = true;
  bool _hasError = false;

  List<Map<String, dynamic>> _schedules = [];
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDate = _focusedDate;
    WidgetsBinding.instance.addObserver(this);
    _loadAppointments();
    _wsSub = WebSocketService.instance.dataUpdateStream.listen((payload) {
      if (payload['type'] == 'appointments' && mounted) {
        _loadAppointments();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  /// Resume and pull-to-refresh must see data created while the websocket was
  /// down (backgrounded app): drop the in-memory cache so the GET hits the
  /// network instead of replaying a response from before the change.
  Future<void> _refresh() {
    ApiService.cacheInterceptor.invalidateMemory('/appointments');
    return _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final appointments = await AppointmentService.getAppointments();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final mapped = appointments.map((a) {
        final date = DateTime.parse(a['date'] as String).toLocal();
        final dateOnly = DateTime(date.year, date.month, date.day);
        final isToday = dateOnly == today;

        String notesTime = '';
        String? mapsUrl;
        final rawNotes = a['notes'];
        if (rawNotes is String && rawNotes.isNotEmpty) {
          try {
            final parsed = jsonDecode(rawNotes) as Map<String, dynamic>;
            notesTime = parsed['time'] as String? ?? '';
            mapsUrl = parsed['mapsUrl'] as String?;
          } catch (_) {}
        }

        final fallbackRange =
            '${date.hour.toString().padLeft(2, '0')}:00 - ${(date.hour + 2).toString().padLeft(2, '0')}:00';
        final fallbackTime =
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

        final isPast = ScheduleStatus.isPast(date, notesTime, now);

        return {
          'id': a['id'],
          'title': a['title'],
          'date': date,
          'timeRange':
              notesTime.isNotEmpty ? notesTime : (isToday ? fallbackRange : null),
          'time': notesTime.isNotEmpty ? notesTime : fallbackTime,
          'location': a['location'] ?? 'Lokasi belum ditentukan',
          'mapsUrl': mapsUrl,
          'status': isPast ? 'Selesai' : (isToday ? 'Segera' : null),
          'type': isToday ? 'today' : (isPast ? 'past' : 'upcoming'),
          'isPast': isPast,
          'notes': rawNotes,
          'updatedAt': a['updatedAt'],
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _schedules = mapped;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      // No data yet: full error state so failure isn't mistaken for an empty
      // schedule. Refresh failure with data on screen keeps the snackbar.
      if (_schedules.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        showAppSnackBar(
            context, 'Gagal memuat jadwal. Periksa koneksi lalu coba lagi.',
            error: true);
      }
    }
  }

  Widget _buildErrorState() {
    return ErrorStateWidget(
      message: 'Gagal memuat jadwal. Periksa koneksi Anda.',
      onRetry: () {
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
        _loadAppointments();
      },
    );
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _todaySchedules {
    return _schedules
        .where((s) => s['type'] == 'today' && s['isPast'] != true)
        .toList();
  }

  List<Map<String, dynamic>> get _upcomingSchedules {
    return _schedules.where((s) => s['type'] == 'upcoming').toList();
  }

  List<DateTime> get _markedDates {
    return _schedules.map((s) => s['date'] as DateTime).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }


  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_schedule_create_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Jadwal Baru'),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            ParallaxPageRoute(
              page: const ScheduleFormScreen(),
            ),
          );
          if (created != null) _loadAppointments();
        },
      ),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Jadwal Monitoring',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: ResponsiveSize.fontXLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveSize.paddingMedium,
              vertical: ResponsiveSize.paddingSmall,
            ),
            padding: EdgeInsets.all(ResponsiveSize.paddingSmall * 0.5),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Daftar'),
                Tab(text: 'Kalender'),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildDaftarTab(), _buildKalenderTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaftarTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) return _buildErrorState();
    final today = DateTime.now();
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hari Ini Section
          _buildSectionHeader(
            'Hari Ini',
            trailing: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSize.paddingMedium,
                vertical: ResponsiveSize.paddingSmall * 0.5,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${today.day} ${IndonesianDate.fullMonth(today.month)} ${today.year}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveSize.spacingMedium),
          if (_todaySchedules.isEmpty)
            _buildEmptyState('Tidak ada jadwal monitoring hari ini')
          else
            ..._todaySchedules.map(
              (schedule) => _buildScheduleCard(schedule, true),
            ),

          SizedBox(height: ResponsiveSize.spacingXLarge),

          // Akan Datang Section
          _buildSectionHeader('Akan Datang'),
          SizedBox(height: ResponsiveSize.spacingMedium),
          if (_upcomingSchedules.isEmpty)
            _buildEmptyState('Belum ada jadwal monitoring mendatang')
          else
            ..._upcomingSchedules.map(
              (schedule) => _buildScheduleCard(schedule, false),
            ),
          // Bottom spacer for nav bar clearance
          const SizedBox(height: 100),
        ],
      ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            SizedBox(height: ResponsiveSize.spacingSmall),
            Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        ?trailing,
      ],
    );
  }

  Future<void> _openMaps(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      showAppSnackBar(context, 'Tidak dapat membuka Google Maps', error: true);
    }
  }

  Future<void> _editSchedule(Map<String, dynamic> schedule) async {
    final result = await Navigator.push(
      context,
      ParallaxPageRoute(
        page: ScheduleFormScreen(schedule: {
          'id': schedule['id'],
          'title': schedule['title'],
          'date': schedule['date'],
          'location': schedule['location'],
          'notes': schedule['notes'],
          'updatedAt': schedule['updatedAt'],
        }),
      ),
    );
    if (result != null) _loadAppointments();
  }

  Future<void> _deleteSchedule(Map<String, dynamic> schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: Text('Hapus jadwal "${schedule['title']}"? '
            'Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.statusRed),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final id = schedule['id'] as String;
      final updatedAt = schedule['updatedAt'] != null
          ? DateTime.tryParse(schedule['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now();
      await AppointmentService.deleteAppointment(id, updatedAt);
      if (!mounted) return;
      showAppSnackBar(context, 'Jadwal berhasil dihapus', success: true);
      _loadAppointments();
    } catch (e) {
      if (!mounted) return;
      final statusCode = e is DioException ? e.response?.statusCode : null;
      if (statusCode == 409) {
        _loadAppointments();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data telah diubah oleh pengguna lain. Silakan coba lagi.'),
            backgroundColor: AppColors.statusAmber,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Refresh',
              textColor: AppColors.textPrimary,
              onPressed: _loadAppointments,
            ),
          ),
        );
      } else {
        showAppSnackBar(context, 'Gagal menghapus jadwal. Coba lagi.',
            error: true);
      }
    }
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule, bool isToday) {
    final date = schedule['date'] as DateTime;
    final status = schedule['status'] as String?;
    final hasStatus = status != null;
    final isPast = schedule['isPast'] == true;
    final statusColor =
        status == 'Selesai' ? AppColors.textSecondary : AppColors.statusAmber;
    final mapsUrl = schedule['mapsUrl'] as String?;
    final hasMaps = mapsUrl != null && mapsUrl.isNotEmpty;
    final timeRange = schedule['timeRange'] as String?;
    final timeText = timeRange ?? schedule['time'] as String;

    return Opacity(
      opacity: isPast ? 0.6 : 1.0,
      child: Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date Badge
          Container(
            width: 60,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                left: BorderSide(color: AppColors.primary, width: 4),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  IndonesianDate.shortMonth(date.month).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date.day.toString(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveSize.paddingMedium),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        schedule['title'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (hasStatus)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: ResponsiveSize.spacingSmall),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeText,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        schedule['location'],
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (hasMaps) ...[
                  SizedBox(height: ResponsiveSize.spacingSmall),
                  InkWell(
                    onTap: () => _openMaps(mapsUrl),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Lihat di Google Maps',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            tooltip: 'Opsi jadwal',
            color: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'edit') {
                _editSchedule(schedule);
              } else if (value == 'delete') {
                _deleteSchedule(schedule);
              }
            },
            itemBuilder: (_) => [
              if (!isPast)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        color: AppColors.statusRed, size: 20),
                    SizedBox(width: 12),
                    Text('Hapus',
                        style: TextStyle(color: AppColors.statusRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildKalenderTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) return _buildErrorState();
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
        child: Column(
          children: [
            // Custom Calendar
            _buildCustomCalendar(),
            SizedBox(height: ResponsiveSize.spacingXLarge),
            // Selected date events
            if (_selectedDate != null) ...[
              _buildSectionHeader(
                'Jadwal ${_selectedDate!.day} ${IndonesianDate.fullMonth(_selectedDate!.month)} ${_selectedDate!.year}',
              ),
              SizedBox(height: ResponsiveSize.spacingMedium),
              _buildSelectedDateEvents(),
            ],
            // Bottom spacer for nav bar clearance
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCalendar() {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final daysInMonth = DateTime(
      _focusedDate.year,
      _focusedDate.month + 1,
      0,
    ).day;
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    // Adjust for Sunday start (Flutter weekday: 1=Mon, 7=Sun, we want 0=Sun)
    final startOffset = firstWeekday % 7;

    return Container(
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month/Year Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                onPressed: () {
                  setState(() {
                    _focusedDate = DateTime(
                      _focusedDate.year,
                      _focusedDate.month - 1,
                    );
                  });
                },
              ),
              Text(
                '${IndonesianDate.fullMonth(_focusedDate.month)} ${_focusedDate.year}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onPressed: () {
                  setState(() {
                    _focusedDate = DateTime(
                      _focusedDate.year,
                      _focusedDate.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.spacingMedium),
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: ResponsiveSize.spacingSmall),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startOffset) {
                return const SizedBox.shrink();
              }
              final day = index - startOffset + 1;
              final date = DateTime(_focusedDate.year, _focusedDate.month, day);
              final isSelected =
                  _selectedDate != null && _isSameDay(date, _selectedDate!);
              final isToday = _isSameDay(date, DateTime.now());
              final hasEvent = _markedDates.any((d) => _isSameDay(d, date));

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // FittedBox keeps large accessibility text scales from
                      // overflowing the square calendar cell.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          day.toString(),
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.textOnPrimary
                                : isToday
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: isToday || isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (hasEvent)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.background
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Legend
          if (_markedDates.isNotEmpty) ...[
            SizedBox(height: ResponsiveSize.spacingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Ada Jadwal',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedDateEvents() {
    final events = _schedules
        .where((s) => _isSameDay(s['date'] as DateTime, _selectedDate!))
        .toList();

    if (events.isEmpty) {
      return _buildEmptyState('Tidak ada jadwal');
    }

    return Column(
      children: events
          .map(
            (event) => _buildScheduleCard(
              event,
              _isSameDay(event['date'] as DateTime, DateTime.now()),
            ),
          )
          .toList(),
    );
  }
}
