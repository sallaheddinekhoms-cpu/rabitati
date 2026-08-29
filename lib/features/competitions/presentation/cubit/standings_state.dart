import '../../data/models/team_standing_model.dart';

abstract class StandingsState {}

class StandingsInitial extends StandingsState {}
class StandingsLoading extends StandingsState {}
class StandingsLoaded extends StandingsState {
  final List<TeamStandingModel> standings;
  StandingsLoaded(this.standings);
}
class StandingsError extends StandingsState {
  final String message;
  StandingsError(this.message);
}