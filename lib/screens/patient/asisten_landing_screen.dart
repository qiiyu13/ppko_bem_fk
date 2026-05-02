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
  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when returning to this screen
    _loadConversations();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Percakapan dihapus'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearAllConversations() async {
    try {
      final apiConversations = await ChatService.getConversations();
      for (final c in apiConversations) {
        try {
          await ChatService.deleteConversation(c['id'] as String);
        } catch (_) {}
      }
    } catch (_) {}
    await _storageService.clearAllConversations();
    await _loadConversations();

    if (mounted) {
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Semua riwayat dihapus'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _navigateToChat() async {
    String? conversationId;
    try {
      final conv = await ChatService.createConversation();
      conversationId = conv['id'] as String;
    } catch (_) {
      // If API fails, we'll use local-only mode
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TanyaAsistenScreen(conversationId: conversationId)),
    );
    // Refresh when returning
    _loadConversations();
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Semua Riwayat',
          style: TextStyle(fontSize: 20, color: AppColors.textPrimary),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus semua riwayat percakapan?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: _clearAllConversations,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
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
        child: Column(
          children: [
            // Fixed header section
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
                  // Tanya mediku! Card
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
                                  color: AppColors.background.withValues(
                                    alpha: 0.2,
                                  ),
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
                                        color: AppColors.background.withValues(
                                          alpha: 0.9,
                                        ),
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
                  // Section title
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
                      Text(
                        '${_conversations.length} percakapan',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Scrollable history list
            Expanded(
              child: _conversations.isEmpty
                  ? _buildEmptyState(padding, spacing)
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: padding),
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
            // Clear All button (at bottom)
            if (_conversations.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    top: BorderSide(color: AppColors.surface, width: 1),
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: _showClearAllDialog,
                  icon: Icon(Icons.delete_outline, color: AppColors.background),
                  label: Text(
                    'Hapus Semua Riwayat',
                    style: TextStyle(color: AppColors.background, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: EdgeInsets.symmetric(vertical: padding * 0.75),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
          ],
        ),
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
      child: Container(
        margin: EdgeInsets.only(bottom: spacing),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surface, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: spacing * 0.5,
          ),
          leading: Container(
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
          subtitle: Text(
            conversation.lastMessageText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppColors.textSecondary,
          ),
          onTap: _navigateToChat,
        ),
      ),
    );
  }
}
