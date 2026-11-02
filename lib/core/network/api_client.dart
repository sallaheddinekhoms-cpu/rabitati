import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  static const String baseUrl = 'https://lrf-blida.dz/api/v1';

  late final Dio dio;
  String? _token;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_token == null) {
            final prefs = await SharedPreferences.getInstance();
            _token = prefs.getString('auth_token');
          }
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  // ── Token & Auth Management ──────────────────────────────
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }

  Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('auth_user');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  // ── Offline Cache Helpers ────────────────────────────────
  Future<void> _saveCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cache_$key', jsonEncode(data));
    } catch (_) {}
  }

  Future<dynamic> _getCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('cache_$key');
      if (str != null && str.isNotEmpty) {
        return jsonDecode(str);
      }
    } catch (_) {}
    return null;
  }

  // ── Remote Configuration ─────────────────────────────────
  Future<Map<String, dynamic>?> getConfig() async {
    try {
      final res = await dio.get('/config');
      if (res.statusCode == 200 && res.data['status'] == 'success') {
        final data = res.data['data'];
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (_) {}
    return null;
  }

  // ── News APIs ────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getNews({int? categoryId, String? search, int page = 1}) async {
    final cacheKey = 'news_${categoryId ?? "all"}_page$page';
    try {
      final res = await dio.get('/news', queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
        if (search != null && search.isNotEmpty) 'q': search,
        'page': page,
      });

      if (res.statusCode == 200 && res.data['status'] == 'success') {
        final List list = res.data['data'] ?? [];
        final items = list.map((e) => Map<String, dynamic>.from(e)).toList();
        await _saveCache(cacheKey, items);
        return items;
      }
    } catch (_) {
      // Fallback to cache if offline
      final cached = await _getCache(cacheKey);
      if (cached is List) {
        return cached.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getUrgentNews() async {
    try {
      final res = await dio.get('/news/urgent');
      if (res.statusCode == 200 && res.data['status'] == 'success') {
        final List list = res.data['data'] ?? [];
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> getArticleDetails(String id) async {
    try {
      final res = await dio.get('/news/$id');
      if (res.statusCode == 200 && res.data['status'] == 'success') {
        return Map<String, dynamic>.from(res.data['data']);
      }
    } catch (_) {}
    return null;
  }

  // ── Matches & Live APIs ──────────────────────────────────
  Future<List<Map<String, dynamic>>> getMatches({String? leagueId, String? round, String? status}) async {
    final cacheKey = 'matches_${leagueId ?? "all"}_${round ?? "all"}';
    try {
      final res = await dio.get('/matches', queryParameters: {
        if (leagueId != null) 'league_id': leagueId,
        if (round != null) 'round': round,
        if (status != null) 'status': status,
      });

      if (res.statusCode == 200 && res.data['status'] == 'success') {
        final List list = res.data['data'] ?? [];
        final items = list.map((e) => Map<String, dynamic>.from(e)).toList();
        await _saveCache(cacheKey, items);
        return items;
      }
    } catch (_) {
      final cached = await _getCache(cacheKey);
      if (cached is List) {
        return cached.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return [];
  }

  String? _lastMatchesETag;

  Future<List<Map<String, dynamic>>> getLiveMatches() async {
    try {
      final res = await dio.get(
        '/matches/live',
        options: Options(
          headers: {
            if (_lastMatchesETag != null) 'If-None-Match': _lastMatchesETag,
          },
          validateStatus: (status) => status != null && (status == 200 || status == 304),
        ),
      );

      if (res.statusCode == 304) {
        // Nothing changed! Return cached list instantly
        final cached = await _getCache('matches_live');
        if (cached is List) return cached.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      if (res.statusCode == 200 && res.data['status'] == 'success') {
        _lastMatchesETag = res.headers.value('etag');
        final List list = res.data['data'] ?? [];
        final items = list.map((e) => Map<String, dynamic>.from(e)).toList();
        await _saveCache('matches_live', items);
        return items;
      }
    } catch (_) {
      final cached = await _getCache('matches_live');
      if (cached is List) return cached.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>?> getMatchDetails(String id) async {
    try {
      final res = await dio.get('/matches/$id');
      if (res.statusCode == 200 && res.data['status'] == 'success') {
        return Map<String, dynamic>.from(res.data['data']);
      }
    } catch (_) {}
    return null;
  }

  // ── Standings APIs ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> getStandings({String? leagueId}) async {
    final cacheKey = 'standings_${leagueId ?? "all"}';
    try {
      final endpoint = leagueId != null ? '/standings/$leagueId' : '/standings';
      final res = await dio.get(endpoint);

      if (res.statusCode == 200 && res.data['status'] == 'success') {
        final List list = res.data['data'] ?? [];
        final items = list.map((e) => Map<String, dynamic>.from(e)).toList();
        await _saveCache(cacheKey, items);
        return items;
      }
    } catch (_) {
      final cached = await _getCache(cacheKey);
      if (cached is List) {
        return cached.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return [];
  }

  // ── Clubs & Players APIs ─────────────────────────────────
  Future<List<Map<String, dynamic>>> getClubs({String? leagueId}) async {
    final cacheKey = 'clubs_${leagueId ?? "all"}';
    try {
      final res = await dio.get('/clubs', queryParameters: {
        if (leagueId != null) 'league_id': leagueId,
      });

      if (res.statusCode == 200 && res.data['status'] == 'success') {
        final List list = res.data['data'] ?? [];
        final items = list.map((e) => Map<String, dynamic>.from(e)).toList();
        await _saveCache(cacheKey, items);
        return items;
      }
    } catch (_) {
      final cached = await _getCache(cacheKey);
      if (cached is List) {
        return cached.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getClubPlayers(String clubId) async {
    try {
      final res = await dio.get('/clubs/$clubId/players');
      if (res.statusCode == 200 && res.data['status'] == 'success') {
        final List list = res.data['data'] ?? [];
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ── Documents APIs ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> getDocuments({String? category}) async {
    final cacheKey = 'docs_${category ?? "all"}';
    try {
      final res = await dio.get('/documents', queryParameters: {
        if (category != null) 'category': category,
      });

      if (res.statusCode == 200 && res.data['status'] == 'success') {
        final List list = res.data['data'] ?? [];
        final items = list.map((e) => Map<String, dynamic>.from(e)).toList();
        await _saveCache(cacheKey, items);
        return items;
      }
    } catch (_) {
      final cached = await _getCache(cacheKey);
      if (cached is List) {
        return cached.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return [];
  }

  // ── Delegate & Match Reporting APIs ──────────────────────
  Future<Map<String, dynamic>> loginDelegate(String email, String password) async {
    try {
      final res = await dio.post('/delegate/login', data: {
        'email': email,
        'password': password,
      });

      if (res.statusCode == 200 && res.data['status'] == 'success') {
        final token = res.data['token'] as String;
        final user = res.data['user'] as Map<String, dynamic>;

        await setToken(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_user', jsonEncode(user));

        return {'success': true, 'user': user};
      }
      return {'success': false, 'message': res.data['message'] ?? 'فشل تسجيل الدخول'};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'فشل الاتصال بالخادم، تحقق من البيانات';
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getDelegateMatches({String? email}) async {
    try {
      final res = await dio.get('/delegate/matches', queryParameters: email != null ? {'email': email} : null);
      if (res.statusCode == 200 && res.data['status'] == 'success') {
        final List list = res.data['data'] ?? [];
        final mapped = list.map((e) => Map<String, dynamic>.from(e)).toList();
        await _saveCache('delegate_matches', mapped);
        return mapped;
      }
    } catch (_) {}

    final cached = await _getCache('delegate_matches');
    if (cached is List) {
      return cached.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<bool> updateMatchStatus(String matchId, Map<String, dynamic> data) async {
    try {
      final res = await dio.post('/delegate/matches/$matchId/status', data: data);
      return res.statusCode == 200 && res.data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitDelegateReport(String matchId, Map<String, dynamic> reportData) async {
    try {
      final res = await dio.post('/delegate/matches/$matchId/report', data: {
        'delegate_report': reportData,
      });
      return res.statusCode == 200 && res.data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  Future<bool> addMatchEvent(String matchId, Map<String, dynamic> event) async {
    try {
      final res = await dio.post('/matches/$matchId/events', data: event);
      return res.statusCode == 200 && res.data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateMatchLineup(String matchId, List<dynamic> team1Lineup, List<dynamic> team2Lineup) async {
    try {
      final res = await dio.post('/matches/$matchId/lineup', data: {
        'team1_lineup': team1Lineup,
        'team2_lineup': team2Lineup,
      });
      return res.statusCode == 200 && res.data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  // ── Media Accreditations API ────────────────────────────
  Future<List<Map<String, dynamic>>> getAccreditationMatches() async {
    try {
      final res = await dio.get('/accreditations/matches');
      if (res.statusCode == 200 && res.data['status'] == 'success') {
        return (res.data['data'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> submitAccreditation(Map<String, dynamic> data) async {
    try {
      final res = await dio.post('/accreditations', data: data);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return Map<String, dynamic>.from(res.data);
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        return Map<String, dynamic>.from(e.response!.data);
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> trackAccreditations(String query) async {
    try {
      final res = await dio.get('/accreditations/track', queryParameters: {'query': query});
      if (res.statusCode == 200 && res.data['status'] == 'success') {
        return (res.data['data'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getMatchAccreditations(String matchId) async {
    try {
      final res = await dio.get('/matches/$matchId/accreditations');
      if (res.statusCode == 200 && res.data['status'] == 'success') {
        return (res.data['data'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }
}
