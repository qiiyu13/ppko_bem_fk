import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';
import '../../services/chat_service.dart';
import '../../utils/asset_helper.dart';
import '../../utils/responsive_size.dart';
import '../../services/chat_storage_service.dart';

class TanyaAsistenScreen extends StatefulWidget {
  final String? conversationId;

  const TanyaAsistenScreen({super.key, this.conversationId});

  @override
  TanyaAsistenScreenState createState() => TanyaAsistenScreenState();
}

class TanyaAsistenScreenState extends State<TanyaAsistenScreen> {
  // Message background colors
  static const Color assistantBubbleColor = Color(0xFFF5F5F5);
  static const Color userBubbleColor = AppColors.primary;

  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ChatStorageService _storageService = ChatStorageService();
  bool _isTyping = false;
  bool _isLoading = true;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    await _storageService.init();

    if (widget.conversationId != null) {
      // Load from API
      try {
        final apiMessages = await ChatService.getMessages(widget.conversationId!);
        if (apiMessages.isNotEmpty) {
          setState(() {
            _messages.addAll(apiMessages.map((m) => ChatMessage(
              text: m['content'] as String,
              isUser: (m['role'] as String) == 'user',
              timestamp: DateTime.parse(m['createdAt'] as String),
            )));
          });
        } else {
          _addWelcomeMessages();
        }
      } catch (e) {
        // Fallback to local storage
        _loadFromLocalStorage();
      }
    } else {
      _loadFromLocalStorage();
    }

    setState(() {
      _isLoading = false;
    });

    await _storageService.updateLastActivity();
  }

  Future<void> _loadFromLocalStorage() async {
    final shouldEnd = await _storageService.shouldEndConversation();

    if (shouldEnd) {
      await _storageService.endCurrentConversation();
      _addWelcomeMessages();
    } else {
      final existingMessages = await _storageService.loadCurrentConversation();
      if (existingMessages != null && existingMessages.isNotEmpty) {
        setState(() {
          _messages.addAll(existingMessages);
        });
      } else {
        _addWelcomeMessages();
      }
    }
  }

  void _addWelcomeMessages() {
    final now = DateTime.now();
    _messages.addAll([
      ChatMessage(
        text:
            'Selamat pagi, Ibu/Bapak. Saya Asisten Sehat dari Desa Sejahtera.',
        isUser: false,
        timestamp: now.subtract(const Duration(minutes: 1)),
      ),
      ChatMessage(
        text:
            'Jangan ragu untuk bertanya. Ada yang bisa saya bantu terkait kesehatan Anda hari ini?',
        isUser: false,
        timestamp: now,
      ),
    ]);
  }

  Future<void> _saveConversation() async {
    await _storageService.saveCurrentConversation(_messages);
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final now = DateTime.now();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: now));
      _messageController.clear();
      _isTyping = true;
    });

    // Save conversation locally
    _saveConversation();

    // Send to API if conversationId is available
    if (widget.conversationId != null) {
      _sendMessageToApi(text);
    } else {
      // Simulate assistant response for local-only mode
      _simulateAssistantResponse();
    }
  }

  Future<void> _sendMessageToApi(String text) async {
    try {
      await ChatService.sendMessage(widget.conversationId!, text);
      // Simulate assistant response after API send
      _simulateAssistantResponse();
    } catch (e) {
      // If API fails, just simulate locally
      _simulateAssistantResponse();
    }
  }

  void _simulateAssistantResponse() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              text:
                  'Terima kasih atas pertanyaannya. Saya akan membantu menjelaskan.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _saveConversation();
      }
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _sendQuickMessage(String text) {
    _sendMessage(text);
  }

  Future<void> _onBackPressed() async {
    // End current local conversation if it has messages and we're in local-only mode
    if (widget.conversationId == null && _messages.isNotEmpty) {
      await _storageService.endCurrentConversation();
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveSize();
    responsive.init(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

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
                  isUser: message.isUser,
                  text: message.text,
                  time: _formatTime(message.timestamp),
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
        onPressed: _onBackPressed,
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
            AssetHelper.getSvgPath('doodle-01.svg'),
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
                    AssetHelper.getSvgPath('doodle-01.svg'),
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
                  AssetHelper.getSvgPath('doodle-01.svg'),
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
            // Send button
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
    _saveTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }
}
