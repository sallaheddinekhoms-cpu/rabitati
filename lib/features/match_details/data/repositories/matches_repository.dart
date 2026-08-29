import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';

class MatchesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<MatchModel>> getLiveMatches() {
    return _firestore
        .collection('matches')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MatchModel.fromFirestore(doc)).toList());
  }
}