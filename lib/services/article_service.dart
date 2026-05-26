import 'dart:io';
import 'package:dio/dio.dart';
import 'api_service.dart';
import 'cache_service.dart';
import '../models/tanaman_article.dart';

class ArticleService {
  static Future<String> uploadImage(File file) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(file.path),
    });
    final response = await ApiService.dio.post('/articles/admin/image', data: formData);
    final imagePath = response.data?['data']?['imagePath'] as String?;
    if (imagePath == null) {
      throw Exception('Gagal upload gambar: respons server tidak valid');
    }
    return imagePath;
  }

  static Future<List<TanamanArticle>> getPublishedArticles() async {
    try {
      final response = await ApiService.get('/articles');
      final List<dynamic> data = response.data['data'] ?? [];
      final articles = data.map((json) => TanamanArticle.fromApi(json as Map<String, dynamic>)).toList();
      await CacheService.saveArticles(articles.map((a) => a.toMap()).toList());
      return articles;
    } catch (e) {
      final cached = await CacheService.getArticles();
      return cached.map((m) => TanamanArticle.fromMap(m)).toList();
    }
  }

  static Future<TanamanArticle> getArticle(String id) async {
    try {
      final response = await ApiService.get('/articles/$id');
      return TanamanArticle.fromApi(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      final cached = await CacheService.getArticles();
      return cached
          .map((m) => TanamanArticle.fromMap(m))
          .firstWhere((a) => a.id == id, orElse: () => throw Exception('Article not found in cache'));
    }
  }

  static Future<List<TanamanArticle>> getAllArticles() async {
    try {
      final response = await ApiService.get('/articles/admin/all');
      final List<dynamic> data = response.data['data'] ?? [];
      final articles = data.map((json) => TanamanArticle.fromApi(json as Map<String, dynamic>)).toList();
      await CacheService.saveArticles(articles.map((a) => a.toMap()).toList());
      return articles;
    } catch (e) {
      final cached = await CacheService.getArticles();
      return cached.map((m) => TanamanArticle.fromMap(m)).toList();
    }
  }

  static Future<TanamanArticle> createArticle({
    required String title,
    required String content,
    String? imagePath,
    List<String>? tags,
    bool isDraft = true,
    bool isPublished = false,
  }) async {
    final requestData = <String, dynamic>{
      'title': title,
      'content': content,
      'imagePath': ?imagePath,
      'tags': ?tags,
      'isDraft': isDraft,
      'isPublished': isPublished,
    };

    try {
      final response = await ApiService.post('/articles/admin', data: requestData);
      final article = TanamanArticle.fromApi(response.data['data'] as Map<String, dynamic>);
      // Server may omit content in response — preserve what we sent
      return article.content.isEmpty && content.isNotEmpty
          ? article.copyWith(content: content)
          : article;
    } catch (e) {
      await CacheService.queueSync('/articles/admin', 'POST', requestData);
      return TanamanArticle(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        content: content,
        imagePath: imagePath ?? '',
        publishDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: tags ?? [],
        isDraft: isDraft,
        isPublished: isPublished,
      );
    }
  }

  static Future<TanamanArticle> updateArticle(String id, {
    String? title,
    String? content,
    String? imagePath,
    List<String>? tags,
    bool? isDraft,
    bool? isPublished,
    required DateTime updatedAt,
  }) async {
    final requestData = <String, dynamic>{
      'title': ?title,
      'content': ?content,
      'imagePath': ?imagePath,
      'tags': ?tags,
      'isDraft': ?isDraft,
      'isPublished': ?isPublished,
      'updatedAt': updatedAt.toIso8601String(),
    };

    try {
      final response = await ApiService.put('/articles/admin/$id', data: requestData);
      final article = TanamanArticle.fromApi(response.data['data'] as Map<String, dynamic>);
      // Server may omit content in response — preserve what we sent
      return content != null && article.content.isEmpty && content.isNotEmpty
          ? article.copyWith(content: content)
          : article;
    } catch (e) {
      await CacheService.queueSync('/articles/admin/$id', 'PUT', requestData);
      return TanamanArticle(
        id: id,
        title: title ?? '',
        content: content ?? '',
        imagePath: imagePath ?? '',
        publishDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: updatedAt,
        tags: tags ?? [],
        isDraft: isDraft ?? false,
        isPublished: isPublished ?? false,
      );
    }
  }

  static Future<void> deleteArticle(String id, DateTime updatedAt) async {
    try {
      await ApiService.delete('/articles/admin/$id', data: {
        'updatedAt': updatedAt.toIso8601String(),
      });
    } catch (e) {
      await CacheService.queueSync('/articles/admin/$id', 'DELETE', {
        'updatedAt': updatedAt.toIso8601String(),
      });
    }
  }

  static Future<void> publishArticle(String id, DateTime updatedAt) async {
    try {
      await ApiService.post('/articles/admin/$id/publish', data: {
        'updatedAt': updatedAt.toIso8601String(),
      });
    } catch (e) {
      await CacheService.queueSync('/articles/admin/$id/publish', 'POST', {
        'updatedAt': updatedAt.toIso8601String(),
      });
    }
  }
}
