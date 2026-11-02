import '../../../../core/network/api_client.dart';
import '../models/news_model.dart';

class NewsRepository {
  final ApiClient _apiClient;

  NewsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<NewsModel>> getNews({int? categoryId, String? search}) async {
    final list = await _apiClient.getNews(categoryId: categoryId, search: search);
    return list.map((json) => NewsModel.fromJson(json)).toList();
  }

  Stream<List<NewsModel>> getLiveNews() async* {
    // 1. Emits immediately from cache/API
    final initialList = await getNews();
    yield initialList;

    // 2. Poll every 60 seconds
    while (true) {
      await Future.delayed(const Duration(seconds: 60));
      final updatedList = await getNews();
      yield updatedList;
    }
  }

  Stream<List<Map<String, dynamic>>> getUrgentNewsStream() async* {
    yield await _apiClient.getUrgentNews();
    while (true) {
      await Future.delayed(const Duration(seconds: 45));
      yield await _apiClient.getUrgentNews();
    }
  }
}