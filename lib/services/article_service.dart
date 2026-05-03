import 'api_service.dart';
import '../models/tanaman_article.dart';

class ArticleService {
  static Future<List<TanamanArticle>> getPublishedArticles() async {
    final response = await ApiService.get('/articles');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => TanamanArticle.fromApi(json as Map<String, dynamic>)).toList();
  }

  static Future<TanamanArticle> getArticle(String id) async {
    final response = await ApiService.get('/articles/$id');
    return TanamanArticle.fromApi(response.data['data'] as Map<String, dynamic>);
  }

  static Future<List<TanamanArticle>> getAllArticles() async {
    final response = await ApiService.get('/articles/admin/all');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => TanamanArticle.fromApi(json as Map<String, dynamic>)).toList();
  }

  static Future<TanamanArticle> createArticle({
    required String title,
    required String content,
    String? imagePath,
    List<String>? tags,
    bool isDraft = true,
    bool isPublished = false,
  }) async {
    final response = await ApiService.post('/articles/admin', data: {
      'title': title,
      'content': content,
      if (imagePath != null) 'imagePath': imagePath,
      if (tags != null) 'tags': tags,
      'isDraft': isDraft,
      'isPublished': isPublished,
    });
    return TanamanArticle.fromApi(response.data['data'] as Map<String, dynamic>);
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
    final response = await ApiService.put('/articles/admin/$id', data: {
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (imagePath != null) 'imagePath': imagePath,
      if (tags != null) 'tags': tags,
      if (isDraft != null) 'isDraft': isDraft,
      if (isPublished != null) 'isPublished': isPublished,
      'updatedAt': updatedAt.toIso8601String(),
    });
    return TanamanArticle.fromApi(response.data['data'] as Map<String, dynamic>);
  }

  static Future<void> deleteArticle(String id, DateTime updatedAt) async {
    await ApiService.delete('/articles/admin/$id', data: {
      'updatedAt': updatedAt.toIso8601String(),
    });
  }

  static Future<void> publishArticle(String id, DateTime updatedAt) async {
    await ApiService.post('/articles/admin/$id/publish', data: {
      'updatedAt': updatedAt.toIso8601String(),
    });
  }
}
