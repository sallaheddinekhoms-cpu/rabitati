import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../news/presentation/cubit/news_cubit.dart';
import '../../../news/presentation/cubit/news_state.dart';
import '../../../competitions/presentation/cubit/standings_cubit.dart';
import '../../../competitions/presentation/cubit/standings_state.dart';
import '../../../match_details/presentation/cubit/matches_cubit.dart';
import '../../../match_details/presentation/cubit/matches_state.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../news/presentation/pages/news_details_page.dart';
import '../../../match_details/presentation/pages/match_details_page.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          CountdownWidget(targetDate: DateTime(2026, 9, 25, 0, 0, 0)),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'أبرز المباريات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 12),
          _buildFavoriteMatchesSection(),
          _buildLiveMatchesSection(),
          
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'أحدث الأخبار',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 12),
          _buildNewsSection(),
          
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'الترتيب العام',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 12),
          _buildStandingsSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

    Widget _buildFavoriteMatchesSection() {
    return BlocBuilder<FavoritesCubit, List<String>>(
      builder: (context, favorites) {
        if (favorites.isEmpty) return const SizedBox();
        return BlocBuilder<MatchesCubit, MatchesState>(
          builder: (context, matchState) {
            if (matchState is MatchesLoaded) {
              final favMatches = matchState.matches.where((m) => favorites.contains(m.team1) || favorites.contains(m.team2)).toList();
              if (favMatches.isEmpty) return const SizedBox();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text('مباريات فرقك المفضلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: favMatches.length,
                      itemBuilder: (context, index) {
                        final match = favMatches[index];
                        bool isLive = match.status == 'مباشر';
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => MatchDetailsPage(matchId: match.id, team1Name: match.team1, team2Name: match.team2, score: '${match.score1}-${match.score2}', status: match.status)));
                          },
                          child: Container(
                            width: 280,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primaryOrange.withOpacity(0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        if (isLive) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                                        if (isLive) const SizedBox(width: 6),
                                        Text(isLive ? 'مباشر' : match.status, style: TextStyle(fontSize: 12, color: isLive ? Colors.red : AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Text(match.league, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  ],
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildTeam(match.team1),
                                    Text(isLive || match.status == 'منتهية' ? '${match.score1} - ${match.score2}' : match.time, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    _buildTeam(match.team2),
                                  ],
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }
            return const SizedBox();
          },
        );
      },
    );
  }

  Widget _buildLiveMatchesSection() {
    return BlocBuilder<MatchesCubit, MatchesState>(
      builder: (context, state) {
        if (state is MatchesLoading || state is MatchesInitial) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is MatchesError) {
          return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
        } else if (state is MatchesLoaded) {
          final matches = state.matches.take(3).toList();
          if (matches.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('لا توجد مباريات حالياً.', style: TextStyle(color: AppColors.textSecondary)));
          
          return SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                bool isLive = match.status == 'مباشر';
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MatchDetailsPage(matchId: match.id, team1Name: match.team1, team2Name: match.team2, score: '${match.score1}-${match.score2}', status: match.status)));
                  },
                  child: Container(
                    width: 280,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isLive ? const Color(0xFF500000) : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isLive ? Colors.red.withOpacity(0.5) : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (isLive) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                                if (isLive) const SizedBox(width: 6),
                                Text(isLive ? 'مباشر' : match.status, style: TextStyle(fontSize: 12, color: isLive ? Colors.red : AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text(match.league, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTeam(match.team1),
                            Text(isLive || match.status == 'منتهية' ? '${match.score1} - ${match.score2}' : match.time, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isLive ? Colors.white : AppColors.primaryOrange)),
                            _buildTeam(match.team2),
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildTeam(String name) {
    return Column(
      children: [
        const CircleAvatar(radius: 16, backgroundColor: Colors.white24, child: Icon(Icons.shield, size: 16, color: Colors.white54)),
        const SizedBox(height: 4),
        SizedBox(width: 80, child: Text(name, style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis), textAlign: TextAlign.center)),
      ],
    );
  }

  Widget _buildNewsSection() {
    return BlocBuilder<NewsCubit, NewsState>(
      builder: (context, state) {
        if (state is NewsLoaded) {
          if (state.news.isEmpty) return const SizedBox();
          final news = state.news.first;
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NewsDetailsPage(news: news))),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 180,
              decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1B7A36), Color(0xFF0D3D1C)]),
                      image: news.imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(news.imageUrl), fit: BoxFit.cover) : null,
                    ),
                    child: news.imageUrl.isEmpty ? const Center(child: Icon(Icons.newspaper, size: 60, color: Colors.white24)) : null,
                  ),
                  Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, AppColors.background.withOpacity(0.9)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                  Positioned(
                    bottom: 16, left: 16, right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.primaryOrange, borderRadius: BorderRadius.circular(4)), child: Text(news.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                        const SizedBox(height: 8),
                        Text(news.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildStandingsSection() {
    return BlocBuilder<StandingsCubit, StandingsState>(
      builder: (context, state) {
        if (state is StandingsLoaded) {
          final teams = state.standings.take(3).toList();
          if (teams.isEmpty) return const SizedBox();
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Text('بطولة ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text(context.read<StandingsCubit>().currentLeague, style: const TextStyle(color: AppColors.primaryOrange, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                ...teams.asMap().entries.map((entry) {
                  int index = entry.key;
                  var team = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(color: index == 0 ? Colors.green.withOpacity(0.1) : null, border: index < 2 ? const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)) : null),
                    child: Row(
                      children: [
                        Text('${index + 1}', style: TextStyle(color: index == 0 ? AppColors.primaryOrange : AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        team.logoUrl.isNotEmpty ? Image.network(team.logoUrl, width: 20, height: 20, errorBuilder: (c,e,s) => const Icon(Icons.shield, size: 16, color: Colors.grey)) : const Icon(Icons.shield, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(child: Text(team.team, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Text('${team.points} ن', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}

class CountdownWidget extends StatefulWidget {
  final DateTime targetDate;
  const CountdownWidget({super.key, required this.targetDate});

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
  }

  void _updateRemaining() {
    setState(() {
      _remaining = widget.targetDate.difference(DateTime.now());
    });
    if (_remaining.inSeconds > 0) {
      Future.delayed(const Duration(seconds: 1), _updateRemaining);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.inSeconds <= 0) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryOrange, Color(0xFFC2410C)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primaryOrange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Text('العد التنازلي لانطلاق الموسم الرياضي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeCard('${_remaining.inDays}', 'يوم'),
              const Text(':', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              _buildTimeCard('${_remaining.inHours.remainder(24).toString().padLeft(2, '0')}', 'ساعة'),
              const Text(':', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              _buildTimeCard('${_remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}', 'دقيقة'),
              const Text(':', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              _buildTimeCard('${_remaining.inSeconds.remainder(60).toString().padLeft(2, '0')}', 'ثانية'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}