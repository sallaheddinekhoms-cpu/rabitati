import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/matches_repository.dart';
import 'matches_state.dart';

class MatchesCubit extends Cubit<MatchesState> {
  final MatchesRepository _repository;
  StreamSubscription? _subscription;
  
  String currentDateTab = 'اليوم';

  MatchesCubit(this._repository) : super(MatchesInitial()) {
    loadMatches('اليوم');
  }

  void loadMatches(String dateTab) {
    currentDateTab = dateTab;
    emit(MatchesLoading());
    // في المستقبل يمكن تمرير التاريخ للفلترة من المستودع
    _subscription?.cancel();
    _subscription = _repository.getLiveMatches().listen(
      (matches) => emit(MatchesLoaded(matches)),
      onError: (error) => emit(MatchesError("حدث خطأ في تحميل المباريات.")),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}