import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';
import '../../services/chat_service.dart';
import '../../services/websocket_service.dart';
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
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ChatStorageService _storageService = ChatStorageService();
  bool _isTyping = false;
  bool _isLoading = true;
  bool _isInRecordingMode = false;
  bool _isRecordingActive = false;
  bool _isRecordingLocked = false;
  double _recordingDragDx = 0;
  double _recordingDragDy = 0;
  Timer? _saveTimer;
  StreamSubscription<Map<String, dynamic>>? _chatSubscription;
  String? _activeConversationId;

  static const double _cancelThreshold = 80;
  static const double _lockThreshold = 60;

  @override
  void initState() {
    super.initState();
    _activeConversationId = widget.conversationId;
    _messageController.addListener(_onTextChanged);
    _loadConversation();
    _chatSubscription = WebSocketService.instance.chatMessageStream.listen((event) {
      final convId = event['conversationId'] as String?;
      if (convId == _activeConversationId) {
        final messageData = event['message'] as Map<String, dynamic>;
        final role = messageData['role'] as String?;
        if (role == 'assistant') {
          setState(() {
            _isTyping = false;
            _messages.add(ChatMessage(
              text: messageData['content'] as String,
              isUser: false,
              timestamp: DateTime.parse(messageData['createdAt'] as String),
            ));
          });
          _scrollToBottom();
          _saveConversation();
        }
      }
    });
  }

  Future<void> _loadConversation() async {
    await _storageService.init();

    if (_activeConversationId != null) {
      try {
        final apiMessages = await ChatService.getMessages(_activeConversationId!);
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final now = DateTime.now();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: now));
      _messageController.clear();
      _isTyping = true;
    });

    _saveConversation();

    // Lazily create conversation on first message if not already open
    if (_activeConversationId == null && WebSocketService.instance.isConnected) {
      try {
        final conv = await ChatService.createConversation();
        _activeConversationId = conv['id'] as String;
      } catch (_) {
        // Fall through to offline message
      }
    }

    if (_activeConversationId != null) {
      ChatService.sendMessageViaWebSocket(_activeConversationId!, text);
      if (!WebSocketService.instance.isConnected) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isTyping = false;
              _messages.add(ChatMessage(
                text: 'Maaf, koneksi ke server terputus. Pesan Anda tersimpan secara lokal dan akan dikirim saat koneksi pulih.',
                isUser: false,
                timestamp: DateTime.now(),
              ));
            });
            _saveConversation();
          }
        });
      }
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isTyping = false;
            _messages.add(ChatMessage(
              text: 'Asisten AI membutuhkan koneksi internet. Silakan coba lagi saat online.',
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
          _saveConversation();
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
    if (_activeConversationId == null && _messages.isNotEmpty) {
      await _storageService.endCurrentConversation();
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _onTextChanged() {
    if (!_isInRecordingMode) {
      setState(() {});
    }
  }

  void _enterRecordingMode() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isInRecordingMode = true;
    });
  }

  void _exitRecordingMode() {
    setState(() {
      _isInRecordingMode = false;
      _isRecordingActive = false;
      _isRecordingLocked = false;
      _recordingDragDx = 0;
      _recordingDragDy = 0;
    });
  }

  void _onRecordStart(LongPressStartDetails details) {
    setState(() {
      _isRecordingActive = true;
      _isRecordingLocked = false;
      _recordingDragDx = 0;
      _recordingDragDy = 0;
    });
  }

  void _onRecordUpdate(LongPressMoveUpdateDetails details) {
    setState(() {
      _recordingDragDx = details.offsetFromOrigin.dx;
      _recordingDragDy = details.offsetFromOrigin.dy;

      if (_recordingDragDy < -_lockThreshold) {
        _isRecordingLocked = true;
      }
    });
  }

  void _onRecordEnd(LongPressEndDetails details) {
    if (_isRecordingLocked) {
      setState(() {}); // stay recording, keep overlay visible
      return;
    }

    if (_recordingDragDx < -_cancelThreshold) {
      _exitRecordingMode();
      return;
    }

    // Voice message recorded — placeholder for transcription integration
    _exitRecordingMode();
  }

  void _stopLockedRecording() {
    _exitRecordingMode();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

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
              controller: _scrollController,
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

  Widget _buildRecordingInput() {
    final isCancelling = _recordingDragDx < -_cancelThreshold;
    final isLocking = _recordingDragDy < -_lockThreshold && !_isRecordingLocked;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.paddingMedium,
        vertical: ResponsiveSize.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.surface, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lock hint (appears when dragging up)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _isRecordingActive ? 1.0 : 0.0,
              child: Padding(
                padding: EdgeInsets.only(bottom: ResponsiveSize.spacingMedium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cancel zone
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: isCancelling ? Colors.red : AppColors.textSecondary,
                          size: 20,
                        ),
                        SizedBox(width: ResponsiveSize.spacingSmall * 0.5),
                        Text(
                          'Batal',
                          style: TextStyle(
                            color: isCancelling ? Colors.red : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    // Lock zone
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isRecordingLocked ? 'Terkunci' : 'Kunci',
                          style: TextStyle(
                            color: isLocking || _isRecordingLocked
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: ResponsiveSize.spacingSmall * 0.5),
                        Icon(
                          _isRecordingLocked ? Icons.lock : Icons.lock_open,
                          color: isLocking || _isRecordingLocked
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Record button
            GestureDetector(
              onLongPressStart: _onRecordStart,
              onLongPressMoveUpdate: _onRecordUpdate,
              onLongPressEnd: _onRecordEnd,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _isRecordingActive ? Colors.red : AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecordingActive ? Colors.red : AppColors.primary)
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            SizedBox(height: ResponsiveSize.spacingMedium),
            // Hint text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _isRecordingLocked
                    ? 'Merekam...'
                    : _isRecordingActive
                        ? 'Geser kiri untuk batal, atas untuk kunci'
                        : 'Tahan untuk merekam',
                key: ValueKey(_isRecordingLocked
                    ? 'locked'
                    : _isRecordingActive
                        ? 'active'
                        : 'idle'),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            // Stop button (when locked)
            if (_isRecordingLocked)
              Padding(
                padding: EdgeInsets.only(top: ResponsiveSize.spacingSmall),
                child: TextButton(
                  onPressed: _stopLockedRecording,
                  child: const Text(
                    'Selesai & Kirim',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    // Recording mode replaces the entire input bar
    if (_isInRecordingMode) {
      return _buildRecordingInput();
    }

    final hasText = _messageController.text.isNotEmpty;

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
            Expanded(
              child: Container(
                padding: EdgeInsets.only(
                  right: ResponsiveSize.paddingMedium,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: AppColors.textSecondary,
                        size: ResponsiveSize.iconMedium * 0.8,
                      ),
                      padding: EdgeInsets.only(
                        left: ResponsiveSize.paddingSmall,
                        right: ResponsiveSize.spacingSmall * 0.5,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 44,
                      ),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ketik pesan...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: ResponsiveSize.fontMedium,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: ResponsiveSize.paddingSmall,
                          ),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: ResponsiveSize.spacingSmall),
            GestureDetector(
              onTap: hasText
                  ? () => _sendMessage(_messageController.text)
                  : _enterRecordingMode,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    hasText ? Icons.send : Icons.mic,
                    key: ValueKey(hasText ? 'send' : 'mic'),
                    color: AppColors.textOnPrimary,
                    size: ResponsiveSize.iconMedium * 0.7,
                  ),
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
    _chatSubscription?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
