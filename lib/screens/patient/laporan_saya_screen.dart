import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';
import '../../utils/asset_helper.dart';
import '../../utils/responsive_size.dart';
import '../../services/api_service.dart';
import '../../services/profile_service.dart';

class LaporanSayaScreen extends StatefulWidget {
  final String gender;

  const LaporanSayaScreen({super.key, required this.gender});

  @override
  State<LaporanSayaScreen> createState() => _LaporanSayaScreenState();
}

class _LaporanSayaScreenState extends State<LaporanSayaScreen> {
  List<BPScreeningData> _screeningData = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScreenings();
  }

  Future<void> _loadScreenings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profileId = ProfileService.instance.activeProfile?.id;
      if (profileId == null) {
        setState(() {
          _isLoading = false;
          _error = 'Tidak ada profil aktif';
        });
        return;
      }

      final response = await ApiService.get(
        '/screenings',
        queryParameters: {'profileId': profileId},
      );

      final data = response.data['data'] as List? ?? [];
      setState(() {
        _screeningData = data.map((json) {
          final map = json as Map<String, dynamic>;
          return BPScreeningData(
            date: DateTime.parse(map['date'] as String),
            systolic: (map['systolic'] as num).toInt(),
            diastolic: (map['diastolic'] as num).toInt(),
            weight: (map['weight'] as num).toDouble(),
            height: (map['height'] as num).toDouble(),
            bloodSugar: (map['bloodSugar'] as num).toDouble(),
            uricAcid: (map['uricAcid'] as num).toDouble(),
            cholesterol: (map['cholesterol'] as num).toDouble(),
            gender: widget.gender,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Gagal memuat data screening. Periksa koneksi Anda.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Laporan Saya',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadScreenings,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (_screeningData.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada data screening',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Screening History Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.history,
                                color: AppColors.primary,
                                size: ResponsiveSize.iconMedium,
                              ),
                              SizedBox(width: ResponsiveSize.paddingSmall),
                              Text(
                                'Riwayat Screening',
                                style: TextStyle(
                                  fontSize: ResponsiveSize.fontLarge,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${_screeningData.length} screening',
                            style: TextStyle(
                              fontSize: ResponsiveSize.fontSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveSize.spacingMedium),
                      // Expandable Screening Cards
                      ..._screeningData.reversed.take(5).map((data) {
                        return _buildExpandableScreeningCard(
                          data: data,
                          isInitiallyExpanded: false,
                        );
                      }),

                      SizedBox(height: ResponsiveSize.spacingXLarge),

                      // Bottom Action Buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpandableScreeningCard({
    required BPScreeningData data,
    bool isInitiallyExpanded = false,
  }) {
    return ExpandableScreeningCardWidget(
      data: data,
      isInitiallyExpanded: isInitiallyExpanded,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TouchableButton(
            onTap: () {},
            isFilled: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.download,
                  color: AppColors.textSecondary,
                  size: ResponsiveSize.iconSmall,
                ),
                const SizedBox(width: 8),
                Text(
                  'UNDUH',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: ResponsiveSize.fontMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: ResponsiveSize.paddingSmall),
        Expanded(
          child: TouchableButton(
            onTap: () {},
            isFilled: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.share,
                  color: AppColors.background,
                  size: ResponsiveSize.iconSmall,
                ),
                const SizedBox(width: 8),
                Text(
                  'BAGIKAN',
                  style: TextStyle(
                    color: AppColors.background,
                    fontSize: ResponsiveSize.fontMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Data model for screening
class BPScreeningData {
  final DateTime date;
  final int systolic;
  final int diastolic;
  final double weight;
  final double height;
  final double bloodSugar;
  final double uricAcid;
  final double cholesterol;
  final String gender;

  BPScreeningData({
    required this.date,
    required this.systolic,
    required this.diastolic,
    required this.weight,
    required this.height,
    required this.bloodSugar,
    required this.uricAcid,
    required this.cholesterol,
    required this.gender,
  });

  double get bmi {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  String get bmiCategory {
    if (bmi < 18.5) return 'Kurus';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Gemuk';
    return 'Obesitas';
  }

  double get ird {
    final auDenominator = gender.toLowerCase() == 'pria' ? 7.0 : 6.0;
    final gdsComponent = 0.3 * (bloodSugar / 200);
    final bpComponent = 0.2 * ((systolic / 140 + diastolic / 90) / 2);
    final kolComponent = 0.2 * (cholesterol / 240);
    final auComponent = 0.15 * (uricAcid / auDenominator);
    final bmiComponent = 0.15 * (bmi / 25);
    return gdsComponent +
        bpComponent +
        kolComponent +
        auComponent +
        bmiComponent;
  }

  String get irdCategory {
    if (ird < 0.75) return 'Rendah';
    if (ird <= 1.0) return 'Sedang';
    return 'Berat';
  }
}

// Expandable Screening Card Widget
class ExpandableScreeningCardWidget extends StatefulWidget {
  final BPScreeningData data;
  final bool isInitiallyExpanded;

  const ExpandableScreeningCardWidget({
    super.key,
    required this.data,
    this.isInitiallyExpanded = false,
  });

  @override
  State<ExpandableScreeningCardWidget> createState() =>
      _ExpandableScreeningCardWidgetState();
}

class _ExpandableScreeningCardWidgetState
    extends State<ExpandableScreeningCardWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getBPStatus(int systolic, int diastolic) {
    if (systolic <= 90 && diastolic <= 60) return 'RENDAH';
    if (systolic >= 140 || diastolic >= 90) return 'TINGGI STAGE 2';
    if (systolic >= 120 && systolic <= 129 && diastolic <= 80)
      return 'ELEVATED';
    if ((systolic >= 130 && systolic <= 139) ||
        (diastolic >= 81 && diastolic <= 89)) {
      return 'TINGGI STAGE 1';
    }
    return 'NORMAL';
  }

  Color _getBPStatusColor(String status) {
    switch (status) {
      case 'NORMAL':
      case 'ELEVATED':
        return AppColors.success;
      case 'RENDAH':
      case 'TINGGI STAGE 1':
      case 'TINGGI STAGE 2':
        return const Color(0xFFEF5350);
      default:
        return AppColors.success;
    }
  }

  Color _getIRDStatusColor(String category) {
    switch (category) {
      case 'Rendah':
        return AppColors.success;
      case 'Sedang':
        return const Color(0xFFFF9800);
      case 'Berat':
        return const Color(0xFFEF5350);
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bpStatus = _getBPStatus(widget.data.systolic, widget.data.diastolic);
    final statusColor = _getBPStatusColor(bpStatus);

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(ResponsiveSize.cardBorderRadius),
        border: Border.all(color: AppColors.surface, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header - always visible
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(ResponsiveSize.cardBorderRadius),
              bottom: _isExpanded
                  ? Radius.zero
                  : Radius.circular(ResponsiveSize.cardBorderRadius),
            ),
            child: Padding(
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
              child: Row(
                children: [
                  // Document icon
                  SvgPicture.asset(
                    AssetHelper.getSvgPath('document_recolored_final_2.svg'),
                    width: ResponsiveSize.iconMedium * 1.2,
                    height: ResponsiveSize.iconMedium * 1.2,
                  ),
                  SizedBox(width: ResponsiveSize.paddingSmall),
                  Expanded(
                    child: Text(
                      _formatDate(widget.data.date),
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontMedium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                    size: ResponsiveSize.iconMedium,
                  ),
                ],
              ),
            ),
          ),
          // Expanded content - detailed report
          if (_isExpanded)
            Container(
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(ResponsiveSize.cardBorderRadius),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: ResponsiveSize.paddingSmall * 0.5),
                      Text(
                        'Detail Hasil Screening',
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontMedium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveSize.spacingMedium),
                  // Blood Pressure (Primary Focus)
                  _buildDetailSection(
                    title: 'Tekanan Darah (Fokus Utama)',
                    icon: Icons.favorite,
                    iconColor: statusColor,
                    children: [
                      _buildDetailRow(
                        'Sistolik',
                        '${widget.data.systolic} mmHg',
                        isHighlighted: true,
                      ),
                      _buildDetailRow(
                        'Diastolik',
                        '${widget.data.diastolic} mmHg',
                        isHighlighted: true,
                      ),
                      _buildDetailRow('Status', bpStatus, isStatus: true),
                    ],
                  ),
                  SizedBox(height: ResponsiveSize.spacingMedium),
                  // Weight & BMI
                  _buildDetailSection(
                    title: 'Berat & Tinggi Badan',
                    icon: Icons.monitor_weight_outlined,
                    iconColor: AppColors.primary,
                    children: [
                      _buildDetailRow(
                        'Berat Badan',
                        '${widget.data.weight.toStringAsFixed(1)} kg',
                      ),
                      _buildDetailRow(
                        'Tinggi Badan',
                        '${widget.data.height.toStringAsFixed(0)} cm',
                      ),
                      _buildDetailRow(
                        'BMI',
                        '${widget.data.bmi.toStringAsFixed(1)} (${widget.data.bmiCategory})',
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveSize.spacingMedium),
                  // Lab Results
                  _buildDetailSection(
                    title: 'Hasil Laboratorium',
                    icon: Icons.science_outlined,
                    iconColor: AppColors.primarySurface,
                    children: [
                      _buildDetailRow(
                        'Gula Darah',
                        '${widget.data.bloodSugar.toStringAsFixed(0)} mg/dL',
                      ),
                      _buildDetailRow(
                        'Asam Urat',
                        '${widget.data.uricAcid.toStringAsFixed(1)} mg/dL',
                      ),
                      _buildDetailRow(
                        'Kolesterol',
                        '${widget.data.cholesterol.toStringAsFixed(0)} mg/dL',
                      ),
                      SizedBox(height: ResponsiveSize.spacingSmall),
                      _buildDetailRow(
                        'IRD (Index Ratio Diabetes)',
                        '${widget.data.ird.toStringAsFixed(2)} (${widget.data.irdCategory})',
                        isIrd: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          ResponsiveSize.cardBorderRadius * 0.5,
        ),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveSize.fontSmall,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.spacingSmall),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlighted = false,
    bool isStatus = false,
    bool isIrd = false,
  }) {
    final bpStatus = isStatus
        ? _getBPStatus(widget.data.systolic, widget.data.diastolic)
        : '';
    final statusColor = isIrd
        ? _getIRDStatusColor(widget.data.irdCategory)
        : _getBPStatusColor(bpStatus);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveSize.fontSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (isStatus)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveSize.fontSmall,
                fontWeight: isHighlighted || isIrd
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: isHighlighted
                    ? AppColors.primary
                    : (isIrd ? statusColor : AppColors.textPrimary),
              ),
            ),
        ],
      ),
    );
  }
}

// Touchable Card Widget with press animation
class TouchableCard extends StatefulWidget {
  final Widget child;

  const TouchableCard({super.key, required this.child});

  @override
  State<TouchableCard> createState() => _TouchableCardState();
}

class _TouchableCardState extends State<TouchableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {},
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(
                  ResponsiveSize.cardBorderRadius,
                ),
                border: Border.all(color: AppColors.surface, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -5,
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

// Touchable Suggestion Card
class TouchableSuggestionCard extends StatefulWidget {
  final IconData? icon;
  final String? iconAsset;
  final bool isSvg;
  final String title;
  final String subtitle;
  final Color iconColor;

  const TouchableSuggestionCard({
    super.key,
    this.icon,
    this.iconAsset,
    this.isSvg = false,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  }) : assert(
         icon != null || iconAsset != null,
         'Must provide either icon or iconAsset',
       );

  @override
  State<TouchableSuggestionCard> createState() =>
      _TouchableSuggestionCardState();
}

class _TouchableSuggestionCardState extends State<TouchableSuggestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  Widget _buildIcon() {
    if (widget.iconAsset != null) {
      if (widget.isSvg) {
        return SvgPicture.asset(
          AssetHelper.getSvgPath(
            widget.iconAsset!
                .replaceFirst('assets/svg/', '')
                .replaceFirst('assets/images/', ''),
          ),
          width: ResponsiveSize.iconMedium,
          height: ResponsiveSize.iconMedium,
          colorFilter: ColorFilter.mode(widget.iconColor, BlendMode.srcIn),
        );
      } else {
        return Image.asset(
          widget.iconAsset!,
          width: ResponsiveSize.iconMedium,
          height: ResponsiveSize.iconMedium,
          color: widget.iconColor,
        );
      }
    }
    return Icon(
      widget.icon,
      color: widget.iconColor,
      size: ResponsiveSize.iconMedium,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {},
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.all(ResponsiveSize.paddingSmall),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(
                  ResponsiveSize.cardBorderRadius,
                ),
                border: Border.all(color: AppColors.surface, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: widget.iconColor.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveSize.paddingSmall),
              decoration: BoxDecoration(
                color: widget.iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: _buildIcon(),
            ),
            SizedBox(height: ResponsiveSize.spacingSmall),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: ResponsiveSize.fontMedium,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: ResponsiveSize.fontSmall,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Touchable Button Widget
class TouchableButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool isFilled;

  const TouchableButton({
    super.key,
    required this.onTap,
    required this.child,
    required this.isFilled,
  });

  @override
  State<TouchableButton> createState() => _TouchableButtonState();
}

class _TouchableButtonState extends State<TouchableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveSize.paddingMedium,
              ),
              decoration: BoxDecoration(
                color: widget.isFilled
                    ? AppColors.primary
                    : AppColors.background,
                borderRadius: BorderRadius.circular(
                  ResponsiveSize.buttonBorderRadius,
                ),
                border: Border.all(
                  color: widget.isFilled
                      ? AppColors.primary
                      : AppColors.surface,
                  width: 1,
                ),
                boxShadow: widget.isFilled
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                          spreadRadius: -2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.surface.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
