import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_standing_model.dart';

class StandingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<TeamStandingModel>> getStandingsForLeague(String leagueName) {
    return _firestore
        .collection('standings')
        .where('league', isEqualTo: leagueName)
        .snapshots()
        .map((snapshot) {
      final teams = snapshot.docs.map((doc) => TeamStandingModel.fromFirestore(doc)).toList();
      // الترتيب المحلي حسب النقاط لتجنب مشكلة الـ Composite Index في فايربيز
      teams.sort((a, b) => b.points.compareTo(a.points));
      return teams;
    });
  }
}