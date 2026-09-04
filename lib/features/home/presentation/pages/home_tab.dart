import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/club_logo_widget.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../news/presentation/cubit/news_cubit.dart';
import '../../../news/presentation/cubit/news_state.dart';
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: context.appPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'أبرز المباريات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appTextPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildFavoriteMatchesSection(context),
          _buildLiveMatchesSection(context),
          
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: context.appPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'أحدث الأخبار',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appTextPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildNewsSection(context),
          
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: context.appPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'الترتيب العام',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appTextPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildStandingsSection(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFavoriteMatchesSection(BuildContext context) {
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text('مباريات فرقك المفضلة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appTextPrimary)),
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
                              color: context.appCardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.appPrimary.withOpacity(0.5)),
                              boxShadow: context.appCardShadow,
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
                                        Text(isLive ? 'مباشر' : match.status, style: TextStyle(fontSize: 12, color: isLive ? Colors.red : context.appTextSecondary, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Text(match.league, style: TextStyle(fontSize: 10, color: context.appTextSecondary)),
                                  ],
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildTeam(context, match.team1),
                                    Text(isLive || match.status == 'منتهية' ? '${match.score1} - ${match.score2}' : match.time, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.appTextPrimary)),
                                    _buildTeam(context, match.team2),
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

  Widget _buildLiveMatchesSection(BuildContext context) {
    return BlocBuilder<MatchesCubit, MatchesState>(
      builder: (context, state) {
        if (state is MatchesLoading || state is MatchesInitial) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is MatchesError) {
          return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
        } else if (state is MatchesLoaded) {
          final matches = state.matches.take(3).toList();
          if (matches.isEmpty) return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('لا توجد مباريات حالياً.', style: TextStyle(color: context.appTextSecondary)));
          
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
                      color: isLive ? (context.isDarkMode ? const Color(0xFF500000) : const Color(0xFFFFECEC)) : context.appCardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isLive ? Colors.red.withOpacity(0.5) : context.appBorder),
                      boxShadow: context.appCardShadow,
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
                                Text(isLive ? 'مباشر' : match.status, style: TextStyle(fontSize: 12, color: isLive ? Colors.red : context.appTextSecondary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text(match.league, style: TextStyle(fontSize: 10, color: context.appTextSecondary)),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTeam(context, match.team1),
                            Text(isLive || match.status == 'منتهية' ? '${match.score1} - ${match.score2}' : match.time, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isLive ? (context.isDarkMode ? Colors.white : Colors.red) : context.appPrimary)),
                            _buildTeam(context, match.team2),
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

  Widget _buildTeam(BuildContext context, String name) {
    return Column(
      children: [
        TeamLogoWidget(teamName: name, size: 36),
        const SizedBox(height: 6),
        SizedBox(
          width: 80,
          child: Text(
            name,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis, color: context.appTextPrimary),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildNewsSection(BuildContext context) {
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
              decoration: BoxDecoration(
                color: context.appCardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appBorder),
                boxShadow: context.appCardShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1B7A36), Color(0xFF0D3D1C)]),
                      image: news.imageUrl.isNotEmpty && getAppImageProvider(news.imageUrl) != null
                          ? DecorationImage(image: getAppImageProvider(news.imageUrl)!, fit: BoxFit.cover)
                          : null,
                    ),
                    child: news.imageUrl.isEmpty || getAppImageProvider(news.imageUrl) == null
                        ? const Center(child: Icon(Icons.newspaper, size: 60, color: Colors.white24))
                        : null,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, (context.isDarkMode ? AppColors.darkBackground : Colors.black87).withOpacity(0.9)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16, left: 16, right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: context.appPrimary, borderRadius: BorderRadius.circular(4)),
                          child: Text(news.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
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

  Widget _buildStandingsSection(BuildContext context) {
    return const _HomeStandingsSection();
  }
}

class _HomeStandingsSection extends StatefulWidget {
  const _HomeStandingsSection();

  @override
  State<_HomeStandingsSection> createState() => _HomeStandingsSectionState();
}

class _HomeStandingsSectionState extends State<_HomeStandingsSection> {
  static const List<String> _leagues = [
    'جهوي أول',
    'جهوي ثاني فوج أ',
    'جهوي ثاني فوج ب',
  ];

  String _selectedLeague = 'جهوي أول';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        children: [
          // ── أزرار التبديل بين الأقسام الثلاثة ────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFF7FAF8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: context.appBorder, width: 0.6)),
            ),
            child: Row(
              children: _leagues.map((league) {
                final isSelected = _selectedLeague == league;
                String shortLabel = league;
                if (league == 'جهوي ثاني فوج أ') shortLabel = 'جهوي 2 (أ)';
                if (league == 'جهوي ثاني فوج ب') shortLabel = 'جهوي 2 (ب)';

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!isSelected) {
                        setState(() => _selectedLeague = league);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? context.appPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: context.appPrimary.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        shortLabel,
                        style: TextStyle(
                          color: isSelected ? Colors.white : context.appTextSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── عرض الثلاثة الأوائل للقسم المختار ────────────────
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('standings')
                .where('league', isEqualTo: _selectedLeague)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('لا توجد بيانات ترتيب حالياً.', style: TextStyle(color: context.appTextSecondary)),
                );
              }

              final matchingDocs = snapshot.data!.docs;

              if (matchingDocs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text('لا توجد أندية مسجلة في $_selectedLeague حالياً.', style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                  ),
                );
              }

              // فرز الفرق حسب النقاط تنازلياً
              matchingDocs.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;
                final pA = dataA['points'] is int ? dataA['points'] as int : int.tryParse(dataA['points']?.toString() ?? '0') ?? 0;
                final pB = dataB['points'] is int ? dataB['points'] as int : int.tryParse(dataB['points']?.toString() ?? '0') ?? 0;
                return pB.compareTo(pA);
              });

              final top3 = matchingDocs.take(3).toList();

              return Column(
                children: top3.asMap().entries.map((entry) {
                  int index = entry.key;
                  final data = entry.value.data() as Map<String, dynamic>;
                  final teamName = (data['team'] ?? '').toString();
                  final logoUrl = (data['logoUrl'] ?? '').toString();
                  final points = data['points'] ?? 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: index == 0 ? context.appPrimary.withOpacity(context.isDarkMode ? 0.12 : 0.06) : null,
                      border: index < top3.length - 1
                          ? Border(bottom: BorderSide(color: context.appBorder, width: 0.5))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == 0
                                ? Colors.amber.shade600
                                : (index == 1 ? Colors.grey.shade400 : Colors.brown.shade400),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 14),
                        TeamLogoWidget(teamName: teamName, logoUrl: logoUrl, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            teamName,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.appTextPrimary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.isDarkMode ? Colors.white12 : const Color(0xFFEAF5EE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$points ن',
                            style: TextStyle(fontWeight: FontWeight.bold, color: context.appPrimary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
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
    final isDark = context.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [AppColors.primaryOrange, Color(0xFFC2410C)]
              : const [Color(0xFF1B7A36), Color(0xFF2EB85C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.primaryOrange : const Color(0xFF1B7A36)).withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          const Text('العد التنازلي لانطلاق الموسم الرياضي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 14),
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
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
