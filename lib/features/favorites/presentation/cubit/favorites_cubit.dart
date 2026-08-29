import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesCubit extends Cubit<List<String>> {
  FavoritesCubit() : super([]) {
    _loadFavorites();
  }

  static const _key = 'favorite_teams';

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList(_key) ?? [];
    emit(favs);
  }

  Future<void> toggleFavorite(String team) async {
    final prefs = await SharedPreferences.getInstance();
    final current = List<String>.from(state);
    if (current.contains(team)) {
      current.remove(team);
    } else {
      current.add(team);
    }
    await prefs.setStringList(_key, current);
    emit(current);
  }

  bool isFavorite(String team) {
    return state.contains(team);
  }
}