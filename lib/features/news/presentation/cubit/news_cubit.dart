import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/news_repository.dart';
import 'news_state.dart';

class NewsCubit extends Cubit<NewsState> {
  final NewsRepository _newsRepository;
  StreamSubscription? _newsSubscription;

  NewsCubit(this._newsRepository) : super(NewsInitial()) {
    _loadNews();
  }

  void _loadNews() {
    emit(NewsLoading());
    _newsSubscription = _newsRepository.getLiveNews().listen(
      (newsList) {
        emit(NewsLoaded(newsList));
      },
      onError: (error) {
        emit(NewsError("حدث خطأ أثناء جلب الأخبار: $error"));
      },
    );
  }

  @override
  Future<void> close() {
    _newsSubscription?.cancel();
    return super.close();
  }
}