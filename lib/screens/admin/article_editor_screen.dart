import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../models/tanaman_article.dart';
import '../../services/article_service.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/article_image.dart';

class ArticleEditorScreen extends StatefulWidget {
  final TanamanArticle? article;

  const ArticleEditorScreen({super.key, this.article});

  @override
  State<ArticleEditorScreen> createState() => _ArticleEditorScreenState();
}

class _ArticleEditorScreenState extends State<ArticleEditorScreen> {
  late QuillController _quillController;
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  File? _selectedImage;
  String? _existingImagePath;
  bool _isLoading = false;

  // Snapshot of initial state for unsaved-changes detection
  late final String _initialTitle;
  late final String _initialTags;
  late final String? _initialImagePath;
  late final String _initialContentJson;

  @override
  void initState() {
    super.initState();
    _initializeEditor();
    _initialTitle = _titleController.text;
    _initialTags = _tagsController.text;
    _initialImagePath = _existingImagePath;
    _initialContentJson =
        jsonEncode(_quillController.document.toDelta().toJson());
  }

  bool get _isDirty {
    if (_titleController.text != _initialTitle) return true;
    if (_tagsController.text != _initialTags) return true;
    if (_selectedImage != null) return true;
    if (_existingImagePath != _initialImagePath) return true;
    return jsonEncode(_quillController.document.toDelta().toJson()) !=
        _initialContentJson;
  }

  Future<void> _confirmDiscard() async {
    if (!_isDirty) {
      Navigator.pop(context);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buang Perubahan?'),
        content: const Text(
            'Perubahan artikel belum disimpan dan akan hilang jika keluar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Lanjut Menulis'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buang',
                style: TextStyle(color: AppColors.statusRed)),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  void _initializeEditor() {
    if (widget.article != null) {
      // Edit mode
      _titleController.text = widget.article!.title;
      _tagsController.text = widget.article!.tags.join(', ');
      _existingImagePath = widget.article!.imagePath.isNotEmpty
          ? widget.article!.imagePath
          : null;

      // Parse content for Quill
      try {
        final doc = Document.fromJson(
          widget.article!.content.startsWith('[')
              ? List<dynamic>.from(jsonDecode(widget.article!.content) as List)
              : [
                  {"insert": "${widget.article!.content}\n"},
                ],
        );
        _quillController = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        _quillController = QuillController.basic();
        _quillController.document.insert(0, widget.article!.content);
      }
    } else {
      // Create mode
      _quillController = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _existingImagePath = null;
        });
      }
    } catch (e) {
      _showSnackBar('Gagal memilih gambar: $e', error: true);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Gambar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.primary),
              ),
              title: const Text('Kamera'),
              subtitle: const Text('Ambil foto baru'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: AppColors.primary),
              ),
              title: const Text('Galeri'),
              subtitle: const Text('Pilih dari galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImage != null || _existingImagePath != null) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.statusRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete, color: AppColors.statusRed),
                ),
                title: const Text(
                  'Hapus Gambar',
                  style: TextStyle(color: AppColors.statusRed),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _existingImagePath = null;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Judul artikel tidak boleh kosong', error: true);
      return false;
    }
    if (_quillController.document.isEmpty()) {
      _showSnackBar('Konten artikel tidak boleh kosong', error: true);
      return false;
    }
    return true;
  }

  Future<void> _saveArticle({required bool publish}) async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    String imagePath = _existingImagePath ?? '';

    try {
      if (_selectedImage != null) {
        imagePath = await ArticleService.uploadImage(_selectedImage!);
      }

      final TanamanArticle article;
      if (widget.article != null) {
        article = await ArticleService.updateArticle(
          widget.article!.id,
          title: _titleController.text.trim(),
          content: jsonEncode(_quillController.document.toDelta().toJson()),
          imagePath: imagePath.isNotEmpty ? imagePath : null,
          tags: tags,
          isDraft: !publish,
          isPublished: publish,
          updatedAt: widget.article!.updatedAt,
        );
      } else {
        article = await ArticleService.createArticle(
          title: _titleController.text.trim(),
          content: jsonEncode(_quillController.document.toDelta().toJson()),
          imagePath: imagePath.isNotEmpty ? imagePath : null,
          tags: tags,
          isDraft: !publish,
          isPublished: publish,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.pop(context, article);
      }
    } catch (e) {
      // Reachable when image upload fails — article was NOT saved or queued.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
            'Gagal mengunggah gambar. Artikel belum disimpan — coba lagi.',
            error: true);
      }
    }
  }

  void _showSnackBar(String message, {bool success = false, bool error = false}) =>
      showAppSnackBar(context, message, success: success, error: error);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _confirmDiscard,
        ),
        title: Text(
          widget.article != null ? 'Edit Artikel' : 'Artikel Baru',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  _buildImageSection(),
                  const SizedBox(height: 20),

                  // Title Input
                  _buildTitleInput(),
                  const SizedBox(height: 16),

                  // Tags Input
                  _buildTagsInput(),
                  const SizedBox(height: 24),

                  // Rich Text Editor
                  _buildRichTextEditor(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          _buildBottomActionBar(),
        ],
      ),
      ),
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(_selectedImage!, fit: BoxFit.cover),
              )
            : _existingImagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ArticleImage(
                  imagePath: _existingImagePath!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 48,
          color: AppColors.textSecondary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap untuk tambah gambar',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Judul Artikel',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Masukkan judul artikel...',
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _tagsController,
          decoration: InputDecoration(
            hintText: 'TipsSehat, TanamanObat, Jahe (pisahkan dengan koma)',
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              fontSize: 13,
            ),
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
            prefixIcon: const Icon(Icons.tag, color: AppColors.textSecondary),
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildRichTextEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Konten Artikel',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              // Toolbar - single horizontally-scrollable row for mobile
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  color: AppColors.background,
                  child: QuillSimpleToolbar(
                    controller: _quillController,
                    config: const QuillSimpleToolbarConfig(
                      toolbarSize: 44,
                      multiRowsDisplay: false,
                      axis: Axis.horizontal,
                      // Text formatting
                      showBoldButton: true,
                  showItalicButton: true,
                  showUnderLineButton: true,
                  // Lists
                  showListNumbers: true,
                  showListBullets: true,
                  // Alignment (left & center only)
                  showLeftAlignment: true,
                  showCenterAlignment: true,
                  showRightAlignment: false,
                  showAlignmentButtons: false,
                  // Utility
                  showClearFormat: true,
                  // Hide everything else
                  showStrikeThrough: false,
                  showColorButton: false,
                  showBackgroundColorButton: false,
                  showHeaderStyle: false,
                  showCodeBlock: false,
                  showQuote: false,
                  showIndent: false,
                  showLink: false,
                  showUndo: false,
                  showRedo: false,
                  showFontFamily: false,
                  showFontSize: false,
                  showClipboardCut: false,
                  showClipboardCopy: false,
                  showClipboardPaste: false,
                  showSearchButton: false,
                  showSubscript: false,
                  showSuperscript: false,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              // Editor
              Container(
                height: 320,
                padding: const EdgeInsets.all(14),
                child: QuillEditor(
                  controller: _quillController,
                  focusNode: _editorFocusNode,
                  scrollController: _editorScrollController,
                  config: const QuillEditorConfig(
                    placeholder: 'Tulis konten artikel di sini...',
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _saveArticle(publish: false),
                icon: const Icon(Icons.save),
                label: const Text('Simpan Draft'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _saveArticle(publish: true),
                icon: const Icon(Icons.publish),
                label: const Text('Publikasikan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
