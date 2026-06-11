import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/appointment_service.dart';
import '../../widgets/error_state_widget.dart';
import '../../services/profile_service.dart';
import '../../services/websocket_service.dart';
import '../../utils/date_utils.dart';
import '../../utils/responsive_size.dart';
import '../../utils/schedule_status.dart';

class JadwalSayaScreen extends StatefulWidget {
  final VoidCallback onBack;
  final bool isEmbedded;

  const JadwalSayaScreen({
    super.key,
    required this.onBack,
    this.isEmbedded = true,
  });

  @override
  State<JadwalSayaScreen> createState() => _JadwalSayaScreenState();
}

class _JadwalSayaScreenState extends State<JadwalSayaScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;

  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;
  String? _error;
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
      final profileId = ProfileService.instance.activeProfile?.id;
      final appointments = await AppointmentService.getAppointments(
        profileId: profileId,
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final mapped = appointments
          .map((a) {
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

            return {
              'id': a['id'],
              'title': a['title'],
              'date': date,
              'timeRange': notesTime.isNotEmpty
                  ? notesTime
                  : (isToday ? fallbackRange : null),
              'time': notesTime.isNotEmpty ? notesTime : fallbackTime,
              'location': a['location'] ?? 'Lokasi belum ditentukan',
              'mapsUrl': mapsUrl,
              'status': isToday ? 'Segera' : null,
              'type': isToday ? 'today' : 'upcoming',
              'isPast': ScheduleStatus.isPast(date, notesTime, now),
            };
          })
          .where((s) => s['isPast'] != true)
          .toList();

      if (!mounted) return;
      setState(() {
        _schedules = mapped;
        _isLoading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Keep existing data on background refresh failures; only surface
        // the error when there is nothing to show.
        if (_schedules.isEmpty) {
          _error = 'Gagal memuat jadwal. Periksa koneksi Anda.';
        }
      });
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _todaySchedules {
    return _schedules.where((s) => s['type'] == 'today').toList();
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

  String _getMonthName(int month) => IndonesianDate.shortMonth(month);

  String _getFullMonthName(int month) => IndonesianDate.fullMonth(month);

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    if (_isLoading) {
      final loading = Container(
        color: AppColors.background,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
      if (widget.isEmbedded) return loading;
      return Scaffold(backgroundColor: AppColors.background, body: loading);
    }

    if (_error != null) {
      final error = Container(
        color: AppColors.background,
        child: ErrorStateWidget(
          message: _error!,
          onRetry: () {
            setState(() {
              _isLoading = true;
              _error = null;
            });
            _loadAppointments();
          },
        ),
      );
      if (widget.isEmbedded) return error;
      return Scaffold(backgroundColor: AppColors.background, body: error);
    }

    final content = Column(
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
    );

    if (widget.isEmbedded) {
      return Container(color: AppColors.background, child: content);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Jadwal Screening'),
        centerTitle: true,
      ),
      body: content,
    );
  }

  Widget _buildDaftarTab() {
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
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${today.day} ${_getFullMonthName(today.month)} ${today.year}',
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
              _buildEmptyState('Tidak ada jadwal screening hari ini')
            else
              ..._todaySchedules.map(
                (schedule) => _buildEventCard(schedule, true),
              ),

            SizedBox(height: ResponsiveSize.spacingXLarge),

            // Akan Datang Section
            _buildSectionHeader('Akan Datang'),
            SizedBox(height: ResponsiveSize.spacingMedium),
            if (_upcomingSchedules.isEmpty)
              _buildEmptyState('Belum ada jadwal screening mendatang')
            else
              ..._upcomingSchedules.map(
                (schedule) => _buildEventCard(schedule, false),
              ),
            const SizedBox(height: 24),
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

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.event_busy_outlined,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: ResponsiveSize.spacingSmall),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMaps(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
      );
    }
  }

  Widget _buildEventCard(Map<String, dynamic> schedule, bool isToday) {
    final date = schedule['date'] as DateTime;
    final hasStatus = schedule['status'] != null;
    final mapsUrl = schedule['mapsUrl'] as String?;
    final hasMaps = mapsUrl != null && mapsUrl.isNotEmpty;
    final timeRange = schedule['timeRange'] as String?;
    final timeText = timeRange ?? schedule['time'] as String;

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
      padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface, width: 1),
        boxShadow: AppTheme.cardShadowLight,
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
                  _getMonthName(date.month).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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
                          color: AppColors.statusGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          schedule['status'],
                          style: const TextStyle(
                            color: AppColors.statusGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: ResponsiveSize.spacingSmall),
                // Time
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
                // Location
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
        ],
      ),
    );
  }

  Widget _buildKalenderTab() {
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
                'Jadwal ${_selectedDate!.day} ${_getFullMonthName(_selectedDate!.month)} ${_selectedDate!.year}',
              ),
              SizedBox(height: ResponsiveSize.spacingMedium),
              _buildSelectedDateEvents(),
            ],
            const SizedBox(height: 24),
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
        boxShadow: AppTheme.cardShadowLight,
      ),
      child: Column(
        children: [
          // Month/Year Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chevron_left,
                  color: AppColors.textSecondary,
                ),
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
                '${_getFullMonthName(_focusedDate.month)} ${_focusedDate.year}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
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
                      Text(
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
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
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
            (event) => _buildEventCard(
              event,
              _isSameDay(event['date'] as DateTime, DateTime.now()),
            ),
          )
          .toList(),
    );
  }
}
