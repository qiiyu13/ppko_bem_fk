import 'package:flutter/material.dart';
import '../../utils/responsive_size.dart';
import '../../utils/date_utils.dart';
import '../../constants/app_colors.dart';
import 'bp_chart_widget.dart';

class ExpandableScreeningCard extends StatefulWidget {
  final BPScreeningData data;
  final bool isInitiallyExpanded;

  const ExpandableScreeningCard({
    super.key,
    required this.data,
    this.isInitiallyExpanded = false,
  });

  @override
  State<ExpandableScreeningCard> createState() =>
      _ExpandableScreeningCardState();
}

class _ExpandableScreeningCardState extends State<ExpandableScreeningCard> {
  late bool _isExpanded;

  static const Color successGreen = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;
  }

  String _formatDate(DateTime date) => IndonesianDate.format(date);

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
        return successGreen;
      case 'RENDAH':
      case 'TINGGI STAGE 1':
      case 'TINGGI STAGE 2':
        return AppColors.error;
      default:
        return successGreen;
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
                  // Date badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveSize.paddingSmall,
                      vertical: ResponsiveSize.paddingSmall * 0.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.data.date.day}',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveSize.paddingSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(widget.data.date),
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontMedium,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
                        Row(
                          children: [
                            Icon(Icons.favorite, size: 14, color: statusColor),
                            SizedBox(width: 4),
                            Text(
                              '${widget.data.systolic}/${widget.data.diastolic} mmHg',
                              style: TextStyle(
                                fontSize: ResponsiveSize.fontSmall,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: ResponsiveSize.paddingSmall),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                bpStatus,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expand/collapse icon
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
                  // Section title
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
  }) {
    final bpStatus = isStatus
        ? _getBPStatus(widget.data.systolic, widget.data.diastolic)
        : '';
    final statusColor = _getBPStatusColor(bpStatus);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveSize.fontSmall,
              color: AppColors.textSecondary,
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
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                color: isHighlighted
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
