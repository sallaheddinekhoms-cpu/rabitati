import 'package:cloud_firestore/cloud_firestore.dart';

class TeamStandingModel {
  final String id;
  final String league;
  final String team;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int gd;
  final int points;
  final String logoUrl;

  TeamStandingModel({
    required this.id,
    required this.league,
    required this.team,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.gd,
    required this.points,
    required this.logoUrl,
  });

  factory TeamStandingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TeamStandingModel(
      id: doc.id,
      league: data['league'] ?? '',
      team: data['team'] ?? '',
      played: data['played'] ?? 0,
      won: data['won'] ?? 0,
      drawn: data['drawn'] ?? 0,
      lost: data['lost'] ?? 0,
      gd: data['gd'] ?? 0,
      points: data['points'] ?? 0,
      logoUrl: data['logoUrl'] ?? '',
    );
  }
}