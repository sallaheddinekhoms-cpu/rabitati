import '../../../../core/network/api_client.dart';
import '../models/team_standing_model.dart';

class StandingsRepository {
  final ApiClient _apiClient = ApiClient();

  String resolveLeagueId(String leagueName) {
    final clean = leagueName.replaceAll('ال', '').replaceAll('-', '').trim();
    if (clean.contains('فوج ب') || clean.contains('فوج 2') || clean.endsWith('ب') || clean.contains('2 ب')) {
      return '3';
    } else if (clean.contains('فوج أ') || clean.contains('فوج 1') || clean.endsWith('أ') || clean.contains('2 أ')) {
      return '2';
    } else if (clean.contains('ثاني')) {
      return '2';
    }
    return '1';
  }

  Future<List<TeamStandingModel>> getStandingsForLeague(String leagueName) async {
    final leagueId = resolveLeagueId(leagueName);
    
    // 1. Try direct fetch with league ID
    final list = await _apiClient.getStandings(leagueId: leagueId);
    List<TeamStandingModel> result = [];

    for (var item in list) {
      if (item['standings'] is List) {
        for (var s in item['standings']) {
          result.add(TeamStandingModel.fromJson(s));
        }
      } else {
        result.add(TeamStandingModel.fromJson(item));
      }
    }

    // 2. If empty, try general standings and filter specifically by league_id or normalized name
    if (result.isEmpty) {
      final all = await _apiClient.getStandings();
      for (var item in all) {
        final itemLeagueId = (item['league_id'] ?? '').toString();
        final groupName = (item['league_name'] ?? '').toString();
        
        bool matches = false;
        if (itemLeagueId == leagueId) {
          matches = true;
        } else if (leagueId == '1' && (groupName.contains('أول') || groupName.contains('الجهوي الأول'))) {
          matches = true;
        } else if (leagueId == '2' && (groupName.contains('أ') || groupName.contains('فوج أ'))) {
          matches = true;
        } else if (leagueId == '3' && (groupName.contains('ب') || groupName.contains('فوج ب'))) {
          matches = true;
        }

        if (matches) {
          if (item['standings'] is List) {
            for (var s in item['standings']) {
              result.add(TeamStandingModel.fromJson(s));
            }
          } else {
            result.add(TeamStandingModel.fromJson(item));
          }
        }
      }
    }

    result.sort((a, b) => b.points.compareTo(a.points));
    return result;
  }

  Stream<List<TeamStandingModel>> getStandingsStream(String leagueName) async* {
    yield await getStandingsForLeague(leagueName);
    while (true) {
      await Future.delayed(const Duration(seconds: 30));
      yield await getStandingsForLeague(leagueName);
    }
  }
}
