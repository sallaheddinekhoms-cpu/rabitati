import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/club_logo_widget.dart';
import '../cubit/matches_cubit.dart';
import '../cubit/matches_state.dart';
import '../../data/models/match_model.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import 'match_details_page.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});
  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final List<String> _dates = ['اليوم', 'الأمس', 'غداً', 'الأسبوع'];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MatchesCubit>();
    final favorites = context.watch<FavoritesCubit>().state;

    return Column(
      children: [
        // ── شريط التبويبات والتاريخ ─────────────────────────────
        Container(
          color: context.appBackground,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: _dates.map((date) {
              return BlocBuilder<MatchesCubit, MatchesState>(
                builder: (context, state) {
                  final isSelected = date == cubit.currentDateTab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () { if (!isSelected) cubit.loadMatches(date); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? context.appPrimary : context.appCardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? context.appPrimary : context.appBorder,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: context.appPrimary.withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : context.appCardShadow,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          date,
                          style: TextStyle(
                            color: isSelected ? Colors.white : context.appTextSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),

        // ── قائمة المباريات ───────────────────────────────────
        Expanded(
          child: BlocBuilder<MatchesCubit, MatchesState>(
            builder: (context, state) {
              if (state is MatchesLoading || state is MatchesInitial) {
                return Center(child: CircularProgressIndicator(color: context.appPrimary));
              } else if (state is MatchesError) {
                return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
              } else if (state is MatchesLoaded) {
                final docs = state.matches;
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_soccer, size: 64, color: context.appTextSecondary.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            _getEmptyTitle(cubit.currentDateTab),
                            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'الموسم الرياضي 2026-2027 لم ينطلق بعد، ستظهر المباريات تلقائياً فور برمجتها.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.appTextSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // فرز المباريات: مباريات الفرق المفضلة في الأعلى
                final favoriteMatches = docs.where((m) => favorites.contains(m.team1) || favorites.contains(m.team2)).toList();
                final otherMatches = docs.where((m) => !favorites.contains(m.team1) && !favorites.contains(m.team2)).toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    if (favoriteMatches.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'مباريات فرقك المفضلة (${favoriteMatches.length})',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary),
                            ),
                          ],
                        ),
                      ),
                      ...favoriteMatches.map((m) => _MatchCard(match: m, isFavorite: true)),
                      if (otherMatches.isNotEmpty) const SizedBox(height: 12),
                    ],

                    if (otherMatches.isNotEmpty && favoriteMatches.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.sports_soccer, color: context.appTextSecondary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'باقي المباريات (${otherMatches.length})',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      ...otherMatches.map((m) => _MatchCard(match: m, isFavorite: false)),
                    ] else if (favoriteMatches.isEmpty) ...[
                      ...docs.map((m) => _MatchCard(match: m, isFavorite: false)),
                    ],
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  String _getEmptyTitle(String tab) {
    switch (tab) {
      case 'اليوم':
        return 'لا توجد مباريات اليوم';
      case 'الأمس':
        return 'لا توجد مباريات الأمس';
      case 'غداً':
        return 'لا توجد مباريات الغد';
      case 'الأسبوع':
        return 'لا توجد مباريات هذا الأسبوع';
      default:
        return 'لا توجد مباريات ($tab)';
    }
  }
}

// ─── بطاقة المباراة ───────────────────────────────────────────
class _MatchCard extends StatelessWidget {
  final MatchModel match;
  final bool isFavorite;
  const _MatchCard({required this.match, this.isFavorite = false});

  bool get _isFinished => match.status == 'انتهت' || match.status == 'نتيجة';
  bool get _isLive     => match.status == 'مباشر';

  Color _statusColor(BuildContext context) {
    if (_isLive)     return Colors.red;
    if (_isFinished) return context.appTextSecondary;
    return const Color(0xFF1B7A36);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MatchDetailsPage(
            matchId: match.id,
            team1Name: match.team1,
            team2Name: match.team2,
            score: '${match.score1} - ${match.score2}',
            status: match.status,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.appCardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFavorite
                ? Colors.amber.shade400
                : (_isLive ? Colors.red.withOpacity(0.5) : context.appBorder),
            width: isFavorite ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isFavorite
                  ? Colors.amber.withOpacity(0.15)
                  : (_isLive
                      ? Colors.red.withOpacity(0.12)
                      : (context.isDarkMode ? Colors.black.withOpacity(0.2) : const Color(0xFF1B7A36).withOpacity(0.06))),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── رأس البطاقة ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // حالة المباراة + شارة المفضلة — يسار
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor(context).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isLive)
                              Container(
                                width: 6, height: 6,
                                margin: const EdgeInsets.only(left: 4),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              ),
                            Text(
                              match.status,
                              style: TextStyle(
                                color: _statusColor(context),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isFavorite) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade400, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.star, color: Colors.amber, size: 12),
                              SizedBox(width: 3),
                              Text('فريق مفضل', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  // الجولة / الدوري — يمين
                  Text(
                    match.league.isNotEmpty ? match.league : match.round,
                    style: TextStyle(color: context.appTextSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: context.appBorder, thickness: 0.6),

            // ── جسم البطاقة ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // الفريق الأيمن
                  Expanded(child: _TeamColumn(name: match.team1, logoUrl: '')),

                  // الوقت أو النتيجة
                  SizedBox(
                    width: 100,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isFinished || _isLive) ...[
                          Text(
                            '${match.score1}  :  ${match.score2}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _isLive ? Colors.red : context.appTextPrimary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(match.time, style: TextStyle(fontSize: 11, color: context.appTextSecondary)),
                        ] else ...[
                          Text(
                            match.time,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: context.appPrimary,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                        if (match.date.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today, size: 10, color: context.appTextSecondary),
                              const SizedBox(width: 3),
                              Text(match.date, style: TextStyle(fontSize: 10, color: context.appTextSecondary, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // الفريق الأيسر
                  Expanded(child: _TeamColumn(name: match.team2, logoUrl: '')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final String name;
  final String logoUrl;
  const _TeamColumn({required this.name, required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamLogoWidget(
          teamName: name,
          logoUrl: logoUrl,
          size: 48,
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appTextPrimary),
        ),
      ],
    );
  }
}
