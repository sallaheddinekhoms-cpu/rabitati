import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/standings_repository.dart';
import 'standings_state.dart';

class StandingsCubit extends Cubit<StandingsState> {
  final StandingsRepository _repository;
  StreamSubscription? _subscription;
  
  String currentLeague = 'جهوي أول';

  StandingsCubit(this._repository) : super(StandingsInitial()) {
    loadStandings(currentLeague);
  }

  void loadStandings(String leagueName) {
    currentLeague = leagueName;
    emit(StandingsLoading());
    _subscription?.cancel(); // إلغاء الاشتراك القديم عند تغيير القسم
    _subscription = _repository.getStandingsForLeague(leagueName).listen(
      (teams) => emit(StandingsLoaded(teams)),
      onError: (error) => emit(StandingsError("حدث خطأ في تحميل الترتيب.")),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}