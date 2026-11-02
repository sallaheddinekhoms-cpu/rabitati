import '../../../../core/network/api_client.dart';
import '../models/match_model.dart';

class MatchesRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<MatchModel>> getMatches({String? leagueId, String? round, String? status}) async {
    final list = await _apiClient.getMatches(leagueId: leagueId, round: round, status: status);
    return list.map((json) => MatchModel.fromJson(json)).toList();
  }

  Stream<List<MatchModel>> getLiveMatches() async* {
    // 1. Initial emit
    final initialList = await getMatches();
    yield initialList;

    // 2. Poll every 20 seconds during active usage
    while (true) {
      await Future.delayed(const Duration(seconds: 20));
      final updatedList = await getMatches();
      yield updatedList;
    }
  }

  Stream<Map<String, dynamic>?> getMatchDetailsStream(String matchId) async* {
    yield await _apiClient.getMatchDetails(matchId);
    while (true) {
      await Future.delayed(const Duration(seconds: 15));
      yield await _apiClient.getMatchDetails(matchId);
    }
  }
}