import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/appointment_service.dart';
import '../../services/profile_service.dart';
import '../../utils/date_utils.dart';
import '../../utils/responsive_size.dart';

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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;

  List<Map<String, dynamic>> _schedules = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDate = _focusedDate;
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final profileId = ProfileService.instance.activeProfile?.id;
      final appointments = await AppointmentService.getAppointments(profileId: profileId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final mapped = appointments.map((a) {
        final date = DateTime.parse(a['date'] as String);
        final dateOnly = DateTime(date.year, date.month, date.day);
        final isToday = dateOnly == today;
        return {
          'id': a['id'],
          'title': a['title'],
          'date': date,
          'timeRange': isToday ? '${date.hour.toString().padLeft(2, '0')}:00 - ${(date.hour + 2).toString().padLeft(2, '0')}:00' : null,
          'time': '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
          'location': a['location'] ?? 'Lokasi belum ditentukan',
          'doctor': a['notes'],
          'status': isToday ? 'Segera' : null,
          'type': isToday ? 'today' : 'upcoming',
        };
      }).toList();

      setState(() {
        _schedules = mapped;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
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
        title: const Text(
          'Jadwal Screening',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: content,
    );
  }

  Widget _buildDaftarTab() {
    final today = DateTime.now();

    return SingleChildScrollView(
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
                '${today.day} ${_getFullMonthName(today.month)} ${today.year}',
                style: TextStyle(
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
            ..._todaySchedules.map((schedule) => _buildEventCard(schedule, true)),

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
          // Bottom spacer for nav bar clearance
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
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
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> schedule, bool isToday) {
    final date = schedule['date'] as DateTime;
    final hasStatus = schedule['status'] != null;
    final hasDoctor = schedule['doctor'] != null;

    return Container(
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
              border: Border(
                left: BorderSide(color: AppColors.primary, width: 4),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getMonthName(date.month).toUpperCase(),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  date.day.toString(),
                  style: TextStyle(
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
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (hasStatus)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          schedule['status'],
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
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
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      isToday ? schedule['timeRange'] : schedule['time'],
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        schedule['location'],
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (hasDoctor) ...[
                  SizedBox(height: ResponsiveSize.spacingSmall),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        schedule['doctor'],
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Detail',
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
                    ],
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
    return SingleChildScrollView(
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
          // Bottom spacer for nav bar clearance
          const SizedBox(height: 100),
        ],
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
                icon: Icon(Icons.chevron_left, color: AppColors.textSecondary),
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
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
                        style: TextStyle(
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
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
              final isToday = _isSameDay(
                date,
                DateTime.now(),
              );
              final hasEvent = _markedDates.any((d) => _isSameDay(d, date));

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  margin: EdgeInsets.all(2),
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
                          margin: EdgeInsets.only(top: 2),
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
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
                Text(
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
            (event) => _buildEventCard(
              event,
              _isSameDay(event['date'] as DateTime, DateTime.now()),
            ),
          )
          .toList(),
    );
  }
}
