import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/chat_service.dart';
import '../../services/chat_storage_service.dart';
import 'tanya_asisten_screen.dart';

class AsistenLandingScreen extends StatefulWidget {
  const AsistenLandingScreen({super.key});

  @override
  State<AsistenLandingScreen> createState() => _AsistenLandingScreenState();
}

class _AsistenLandingScreenState extends State<AsistenLandingScreen> {
  final ChatStorageService _storageService = ChatStorageService();
  final ScrollController _conversationScrollController = ScrollController();
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  bool _dependenciesLoaded = false;
  bool _isSelecting = false;
  final Set<String> _selectedIds = {};
  String? _toastMessage;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dependenciesLoaded) {
      _dependenciesLoaded = true;
      _loadConversations();
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _conversationScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    await _storageService.init();
    try {
      final apiConversations = await ChatService.getConversations();
      final localConversations = await _storageService.getAllConversations();

      // Merge API conversations with local ones, preferring API data
      final merged = <Conversation>[];
      final seenIds = <String>{};

      for (final c in apiConversations) {
        final id = c['id'] as String;
        seenIds.add(id);
        final messages = c['messages'] as List<dynamic>?;
        final lastMessage = messages != null && messages.isNotEmpty
            ? messages.first['content'] as String? ?? ''
            : '';
        merged.add(Conversation(
          id: id,
          startedAt: DateTime.parse(c['startedAt'] as String),
          lastActivityAt: DateTime.parse(c['lastActivityAt'] as String),
          messages: [
            ChatMessage(
              text: lastMessage,
              isUser: false,
              timestamp: DateTime.parse(c['lastActivityAt'] as String),
            ),
          ],
        ));
      }

      // Add local-only conversations
      for (final c in localConversations) {
        if (!seenIds.contains(c.id)) {
          merged.add(c);
        }
      }

      merged.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));

      if (mounted) {
        setState(() {
          _conversations = merged;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to local only
      final conversations = await _storageService.getAllConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteConversation(String id) async {
    try {
      await ChatService.deleteConversation(id);
    } catch (_) {}
    await _storageService.deleteConversation(id);
    await _loadConversations();

    if (mounted) {
      _showToast('Percakapan dihapus');
    }
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelecting = !_isSelecting;
      if (!_isSelecting) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
    });
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _toastMessage = null;
        });
      }
    });
  }

  Future<void> _batchDelete() async {
    final ids = _selectedIds.toList();
    for (final id in ids) {
      try {
        await ChatService.deleteConversation(id);
      } catch (_) {}
      await _storageService.deleteConversation(id);
    }

    _toggleSelectMode();
    await _loadConversations();

    if (mounted) {
      _showToast('${ids.length} percakapan dihapus');
    }
  }

  Future<void> _navigateToChat({String? conversationId}) async {
    // Only create a new conversation if opening from history (ID provided) or
    // defer creation to when the user actually sends their first message.
    // Previously _navigateToChat() always called createConversation(), which
    // produced empty conversations in the history when no messages were sent.

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TanyaAsistenScreen(conversationId: conversationId)),
    );
    _loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.04;
    final spacing = screenWidth * 0.03;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                if (_isSelecting)
              _buildSelectionHeader(padding, spacing)
            else ...[
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    bottom: BorderSide(color: AppColors.surface, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _navigateToChat,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(padding * 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(padding * 0.75),
                                  decoration: BoxDecoration(
                                    color: AppColors.background.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline,
                                    color: AppColors.background,
                                    size: 32,
                                  ),
                                ),
                                SizedBox(width: padding),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tanya mediku!',
                                        style: TextStyle(
                                          color: AppColors.background,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: spacing * 0.5),
                                      Text(
                                        'Konsultasi kesehatan dengan Asisten Sehat',
                                        style: TextStyle(
                                          color: AppColors.background.withValues(alpha: 0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing * 1.5),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: padding,
                                vertical: spacing,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_forward,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                  SizedBox(width: spacing * 0.5),
                                  Text(
                                    'Mulai Percakapan',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: spacing * 1.5),
                    Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        SizedBox(width: spacing * 0.75),
                        Text(
                          'Riwayat Percakapan',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 22),
                          color: AppColors.textSecondary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _conversations.isNotEmpty ? _toggleSelectMode : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: _conversations.isEmpty
                  ? _buildEmptyState(padding, spacing)
                  : Stack(
                      children: [
                        Scrollbar(
                          controller: _conversationScrollController,
                          child: ListView.builder(
                            controller: _conversationScrollController,
                            padding: EdgeInsets.symmetric(horizontal: padding).copyWith(top: spacing),
                            itemCount: _conversations.length,
                            itemBuilder: (context, index) {
                              final conversation = _conversations[index];
                              return _buildConversationItem(
                                conversation,
                                padding,
                                spacing,
                              );
                            },
                          ),
                        ),
                        if (!_isSelecting)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 40,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.background.withValues(alpha: 0),
                                      AppColors.background.withValues(alpha: 0.8),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 80,
          left: 16,
          right: 16,
          child: IgnorePointer(
            ignoring: _toastMessage == null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _toastMessage != null ? 1.0 : 0.0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _toastMessage ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
      ),
    );
  }

  Widget _buildSelectionHeader(double padding, double spacing) {
    final count = _selectedIds.length;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
      color: AppColors.primary,
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _toggleSelectMode,
            icon: const Icon(Icons.close, size: 16),
            label: const Text(
              'Batal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: count > 0 ? () => _batchDelete() : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: count > 0 ? Colors.red : Colors.red.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.delete_outline, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Hapus ($count)',
                    style: TextStyle(
                      color: count > 0 ? Colors.white : Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double padding, double spacing) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          SizedBox(height: spacing * 1.5),
          Text(
            'Belum Ada Percakapan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: spacing * 0.5),
          Text(
            'Mulai percakapan pertama Anda\ndengan menekan tombol di atas',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(
    Conversation conversation,
    double padding,
    double spacing,
  ) {
    final isSelected = _selectedIds.contains(conversation.id);
    final lastMessage = conversation.lastMessageText;

    final child = Container(
      margin: EdgeInsets.only(bottom: spacing),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.surface,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: spacing * 0.25,
        ),
        leading: _isSelecting
            ? Checkbox(
                value: isSelected,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (_) => _toggleSelection(conversation.id),
              )
            : Container(
                padding: EdgeInsets.all(padding * 0.5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chat, color: AppColors.primary, size: 20),
              ),
        title: Text(
          conversation.formattedTimestamp,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: lastMessage.isNotEmpty
            ? Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              )
            : null,
        trailing: _isSelecting
            ? null
            : Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
        onTap: _isSelecting ? () => _toggleSelection(conversation.id) : () => _navigateToChat(conversationId: conversation.id),
      ),
    );

    if (_isSelecting) return child;

    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: spacing),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: padding),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteConversation(conversation.id);
      },
      child: child,
    );
  }
}
