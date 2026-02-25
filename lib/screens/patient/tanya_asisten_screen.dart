import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';
import '../../utils/responsive_size.dart';

class TanyaAsistenScreen extends StatefulWidget {
  final GlobalKey? sendTargetKey;
  final bool isEmbedded;
  final VoidCallback? onBack;

  const TanyaAsistenScreen({
    super.key,
    this.sendTargetKey,
    this.isEmbedded = false,
    this.onBack,
  });

  @override
  TanyaAsistenScreenState createState() => TanyaAsistenScreenState();
}

class TanyaAsistenScreenState extends State<TanyaAsistenScreen> {
  /// Public method so the dashboard can trigger send via GlobalKey.
  void sendCurrentMessage() {
    _sendMessage(_messageController.text);
  }

  // Message background colors
  static const Color assistantBubbleColor = Color(0xFFF5F5F5);
  static const Color userBubbleColor = AppColors.primary;

  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Initial welcome messages
    _messages.addAll([
      {
        'isUser': false,
        'text':
            'Selamat pagi, Ibu/Bapak. Saya Asisten Sehat dari Desa Sejahtera.',
        'time': '08:30',
      },
      {
        'isUser': false,
        'text':
            'Jangan ragu untuk bertanya. Ada yang bisa saya bantu terkait kesehatan Anda hari ini?',
        'time': '08:31',
      },
    ]);
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'isUser': true, 'text': text, 'time': _getCurrentTime()});
      _messageController.clear();
      _isTyping = true;
    });

    // Simulate assistant response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'isUser': false,
            'text':
                'Terima kasih atas pertanyaannya. Saya akan membantu menjelaskan.',
            'time': _getCurrentTime(),
          });
        });
      }
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _sendQuickMessage(String text) {
    _sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveSize();
    responsive.init(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Date separator
          _buildDateSeparator(),

          // Chat messages
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSize.paddingMedium,
                vertical: ResponsiveSize.paddingSmall,
              ),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(
                  isUser: message['isUser'],
                  text: message['text'],
                  time: message['time'],
                );
              },
            ),
          ),

          // Typing indicator
          if (_isTyping) _buildTypingIndicator(),

          // Quick action chips
          _buildQuickActions(),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () {
          if (widget.isEmbedded && widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Row(
        children: [
          // Doctor avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surface, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SvgPicture.asset(
                'assets/svg/doodle-01.svg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: ResponsiveSize.paddingSmall),
          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Asisten Sehat',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Online',
                      style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone, color: AppColors.textPrimary),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildDateSeparator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ResponsiveSize.paddingSmall),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.paddingMedium,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Hari ini',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required bool isUser,
    required String text,
    required String time,
  }) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: ResponsiveSize.spacingMedium,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar for assistant
                if (!isUser) ...[
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.surface, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SvgPicture.asset(
                        'assets/svg/doodle-01.svg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
                // Message bubble
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
                    decoration: BoxDecoration(
                      color: isUser ? userBubbleColor : assistantBubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Asisten Sehat',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Text(
                          text,
                          style: TextStyle(
                            color: isUser
                                ? AppColors.textOnPrimary
                                : AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.spacingSmall * 0.5),
            // Timestamp
            Padding(
              padding: EdgeInsets.only(
                left: isUser ? 0 : 40,
                right: isUser ? 0 : 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (isUser) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.check,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(left: 40, bottom: ResponsiveSize.spacingMedium),
        padding: EdgeInsets.all(ResponsiveSize.paddingMedium),
        decoration: BoxDecoration(
          color: assistantBubbleColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.surface, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SvgPicture.asset(
                  'assets/svg/doodle-01.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            _buildAnimatedDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(0),
        const SizedBox(width: 4),
        _buildDot(1),
        const SizedBox(width: 4),
        _buildDot(2),
      ],
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.paddingMedium,
        vertical: ResponsiveSize.paddingSmall,
      ),
      child: Row(
        children: [
          _buildQuickActionChip(
            icon: Icons.description_outlined,
            label: 'Jelaskan hasil saya',
            onTap: () => _sendQuickMessage('Jelaskan hasil saya'),
          ),
          SizedBox(width: ResponsiveSize.paddingSmall),
          _buildQuickActionChip(
            icon: Icons.lightbulb_outline,
            label: 'Tips Kesehatan',
            onTap: () => _sendQuickMessage('Tips Kesehatan'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveSize.paddingMedium,
          vertical: ResponsiveSize.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            SizedBox(width: ResponsiveSize.paddingSmall * 0.5),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.paddingMedium,
        vertical: ResponsiveSize.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.surface, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button - fixed size 44x44
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: AppColors.textSecondary,
                  size: ResponsiveSize.iconMedium * 0.8,
                ),
                padding: EdgeInsets.zero,
                onPressed: () {},
              ),
            ),
            // Equal spacing
            SizedBox(width: ResponsiveSize.spacingSmall),
            // Text input - expanded to fill space
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSize.paddingMedium,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Ketik pesan...',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: ResponsiveSize.fontMedium,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: ResponsiveSize.paddingSmall,
                    ),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            // Equal spacing
            SizedBox(width: ResponsiveSize.spacingSmall),
            // Microphone button - fixed size 44x44
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                icon: Icon(
                  Icons.mic,
                  color: AppColors.textSecondary,
                  size: ResponsiveSize.iconMedium * 0.8,
                ),
                padding: EdgeInsets.zero,
                onPressed: () {},
              ),
            ),
            // Equal spacing
            SizedBox(width: ResponsiveSize.spacingSmall),
            // Send button - 44x44 (placeholder when embedded, real button otherwise)
            if (widget.sendTargetKey != null)
              SizedBox(key: widget.sendTargetKey, width: 44, height: 44)
            else
              GestureDetector(
                onTap: () => _sendMessage(_messageController.text),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send,
                    color: AppColors.textOnPrimary,
                    size: ResponsiveSize.iconMedium * 0.7,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
