import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String id;
  final String league;
  final String team1;
  final String team2;
  final String score1;
  final String score2;
  final String time;
  final String status;
  final String round;
  final DateTime? timestamp;

  MatchModel({
    required this.id,
    required this.league,
    required this.team1,
    required this.team2,
    required this.score1,
    required this.score2,
    required this.time,
    required this.status,
    required this.round,
    this.timestamp,
  });

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MatchModel(
      id: doc.id,
      league: data['league'] ?? '',
      team1: data['team1'] ?? '',
      team2: data['team2'] ?? '',
      score1: data['score1']?.toString() ?? '0',
      score2: data['score2']?.toString() ?? '0',
      time: data['time'] ?? '00:00',
      status: data['status'] ?? 'لم تبدأ',
      round: data['round'] ?? 'الجولة 1',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}