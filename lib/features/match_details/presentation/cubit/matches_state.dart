import '../../data/models/match_model.dart';

abstract class MatchesState {}

class MatchesInitial extends MatchesState {}
class MatchesLoading extends MatchesState {}
class MatchesLoaded extends MatchesState {
  final List<MatchModel> matches;
  MatchesLoaded(this.matches);
}
class MatchesError extends MatchesState {
  final String message;
  MatchesError(this.message);
}