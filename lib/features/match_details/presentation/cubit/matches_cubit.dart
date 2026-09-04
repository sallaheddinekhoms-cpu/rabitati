import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/match_model.dart';
import '../../data/repositories/matches_repository.dart';
import 'matches_state.dart';

class MatchesCubit extends Cubit<MatchesState> {
  final MatchesRepository _repository;
  StreamSubscription? _subscription;
  List<MatchModel> _allMatches = [];
  
  String currentDateTab = 'اليوم';

  MatchesCubit(this._repository) : super(MatchesInitial()) {
    _initMatches();
  }

  void _initMatches() {
    emit(MatchesLoading());
    _subscription?.cancel();
    _subscription = _repository.getLiveMatches().listen(
      (matches) {
        _allMatches = matches;
        _applyDateFilter();
      },
      onError: (error) => emit(MatchesError("حدث خطأ في تحميل المباريات.")),
    );
  }

  void loadMatches(String dateTab) {
    currentDateTab = dateTab;
    if (_allMatches.isEmpty && state is! MatchesLoaded) {
      emit(MatchesLoading());
    } else {
      _applyDateFilter();
    }
  }

  void _applyDateFilter() {
    final now = DateTime.now();
    final todayStr = _formatDate(now);
    final yesterdayStr = _formatDate(now.subtract(const Duration(days: 1)));
    final tomorrowStr = _formatDate(now.add(const Duration(days: 1)));

    List<MatchModel> filtered = [];

    if (currentDateTab == 'اليوم') {
      filtered = _allMatches.where((m) => m.date == todayStr).toList();
    } else if (currentDateTab == 'الأمس') {
      filtered = _allMatches.where((m) => m.date == yesterdayStr).toList();
    } else if (currentDateTab == 'غداً') {
      filtered = _allMatches.where((m) => m.date == tomorrowStr).toList();
    } else if (currentDateTab == 'الأسبوع') {
      // مباريات الأسبوع الحالي (ضمن 7 أيام سابقة أو قادمة)
      final weekStart = now.subtract(const Duration(days: 7));
      final weekEnd = now.add(const Duration(days: 7));
      filtered = _allMatches.where((m) {
        if (m.date.isEmpty) return false;
        try {
          final mDate = DateTime.parse(m.date);
          return mDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                 mDate.isBefore(weekEnd.add(const Duration(days: 1)));
        } catch (_) {
          return false;
        }
      }).toList();
    } else {
      filtered = _allMatches;
    }

    emit(MatchesLoaded(filtered));
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}