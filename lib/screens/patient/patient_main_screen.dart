import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;
import '../../constants/app_colors.dart';
import '../../widgets/custom_bottom_nav.dart';
import 'tabs/home_tab.dart';
import 'tabs/profil_tab.dart';
import 'tabs/settings_tab.dart';
import 'jadwal_saya_screen.dart';
import 'tanya_asisten_screen.dart';

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // Animation for center button movement + nav bar slide
  late AnimationController _animController;
  late Animation<double> _animation;

  // Keys for positioning
  final GlobalKey _sendTargetKey = GlobalKey();
  final GlobalKey<TanyaAsistenScreenState> _tanyaKey = GlobalKey();

  // Cached send button center position (screen coordinates)
  Offset? _cachedSendCenter;

  static const double _notchButtonSize = 75.0;
  static const double _sendButtonSize = 44.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index == _currentIndex) return;

    final wasChat = _currentIndex == 2;
    final isChat = index == 2;

    setState(() {
      _currentIndex = index;
    });

    if (isChat && !wasChat) {
      // Switching TO chat — wait for chat screen to build, then animate
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateSendPosition();
        _animController.forward();
      });
    } else if (wasChat && !isChat) {
      // Switching FROM chat — animate back to notch
      _animController.reverse();
    }
  }

  void _updateSendPosition() {
    final sendBox =
        _sendTargetKey.currentContext?.findRenderObject() as RenderBox?;
    if (sendBox != null && sendBox.hasSize) {
      final sendPos = sendBox.localToGlobal(Offset.zero);
      _cachedSendCenter =
          sendPos + Offset(sendBox.size.width / 2, sendBox.size.height / 2);
    }
  }

  Widget _buildTabContent() {
    switch (_currentIndex) {
      case 0:
        return HomeTab();
      case 1:
        return JadwalSayaScreen(onBack: () => _onTabChanged(0));
      case 2:
        return TanyaAsistenScreen(
          key: _tanyaKey,
          sendTargetKey: _sendTargetKey,
          isEmbedded: true,
          onBack: () => _onTabChanged(0),
        );
      case 3:
        return const ProfilTab();
      case 4:
        return const SettingsTab();
      default:
        return HomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Notch center position (center of screen, at top edge of nav bar)
    final notchCenter = Offset(
      screenSize.width / 2,
      screenSize.height - bottomPadding - CustomBottomNav.barHeight,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main tab content — NO bottom padding, content extends behind nav bar
          // so the notch cutout reveals the actual page content
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentIndex),
                  child: _buildTabContent(),
                ),
              ),
            ),
          ),

          // Nav bar overlay — slides down when switching to chat tab
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                // Calculate total slide distance including SafeArea padding
                final totalSlideDistance =
                    CustomBottomNav.barHeight + bottomPadding;
                return Transform.translate(
                  offset: Offset(0, totalSlideDistance * _animation.value),
                  child: Material(
                    elevation: 8,
                    child: SafeArea(
                      top: false,
                      child: CustomBottomNav(
                        currentIndex: _currentIndex,
                        onTap: _onTabChanged,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Animated center button
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final t = _animation.value;

              // Determine send center (use cached or fallback to notch)
              final sendCenter = _cachedSendCenter ?? notchCenter;

              // Interpolate position and size
              final currentCenter = Offset.lerp(notchCenter, sendCenter, t)!;
              final currentSize = lerpDouble(
                _notchButtonSize,
                _sendButtonSize,
                t,
              )!;

              return Positioned(
                left: currentCenter.dx - currentSize / 2,
                top: currentCenter.dy - currentSize / 2,
                child: RepaintBoundary(
                  child: CenterActionButton(
                    animationValue: t,
                    size: currentSize,
                    onTap: t > 0.5
                        ? () => _tanyaKey.currentState?.sendCurrentMessage()
                        : () => _onTabChanged(2),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
