import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/club_logo_widget.dart';
import '../cubit/matches_cubit.dart';
import '../cubit/matches_state.dart';
import '../../data/models/match_model.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../widgets/live_chronometer_widget.dart';
import 'match_details_page.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final List<Map<String, dynamic>> _dateTabs = [
    {'title': 'اليوم', 'icon': Icons.bolt_rounded},
    {'title': 'الأمس', 'icon': Icons.history_rounded},
    {'title': 'غداً', 'icon': Icons.event_available_rounded},
    {'title': 'الأسبوع', 'icon': Icons.calendar_view_week_rounded},
  ];

  String _selectedLeague = 'الكل';

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MatchesCubit>();
    final favorites = context.watch<FavoritesCubit>().state;

    return Column(
      children: [
        // ── شريط التبويبات والتاريخ العصري ─────────────────────────────
        Container(
          color: context.appBackground,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: _dateTabs.map((tab) {
              final title = tab['title'] as String;
              final icon = tab['icon'] as IconData;

              return BlocBuilder<MatchesCubit, MatchesState>(
                builder: (context, state) {
                  final isSelected = title == cubit.currentDateTab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!isSelected) {
                          setState(() {
                            _selectedLeague = 'الكل';
                          });
                          cubit.loadMatches(title);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    const Color(0xFF1B5E20),
                                    const Color(0xFF2E7D32),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : context.appCardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4CAF50).withOpacity(0.6)
                                : context.appBorder.withOpacity(0.6),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF1B5E20).withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : context.appCardShadow,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              size: 14,
                              color: isSelected ? Colors.white : context.appTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              title,
                              style: TextStyle(
                                color: isSelected ? Colors.white : context.appTextSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),

        // ── قائمة المباريات مع تصفية الأقسام وتصميم Stadium Arena ─────
        Expanded(
          child: BlocBuilder<MatchesCubit, MatchesState>(
            builder: (context, state) {
              if (state is MatchesLoading || state is MatchesInitial) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: context.appPrimary),
                      const SizedBox(height: 12),
                      Text(
                        'جاري تحميل نتائج المباريات الرسمية...',
                        style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                );
              } else if (state is MatchesError) {
                return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
              } else if (state is MatchesLoaded) {
                final allDocs = state.matches;
                if (allDocs.isEmpty) {
                  return _buildEmptyState(context, cubit.currentDateTab);
                }

                // استخراج قائمة الأقسام الفريدة المتاحة
                final leaguesSet = <String>{'الكل'};
                for (var m in allDocs) {
                  final l = m.league.trim();
                  if (l.isNotEmpty) leaguesSet.add(l);
                }
                final leaguesList = leaguesSet.toList();

                // تطبيق فلتر القسم المختار
                final filteredDocs = _selectedLeague == 'الكل'
                    ? allDocs
                    : allDocs.where((m) => m.league.trim() == _selectedLeague).toList();

                // فصل المباريات المفضلة
                final favoriteMatches = filteredDocs
                    .where((m) => favorites.contains(m.team1) || favorites.contains(m.team2))
                    .toList();

                // تجميع باقي المباريات حسب القسم
                final nonFavMatches = filteredDocs
                    .where((m) => !favorites.contains(m.team1) && !favorites.contains(m.team2))
                    .toList();

                final Map<String, List<MatchModel>> groupedByLeague = {};
                for (var m in nonFavMatches) {
                  final lName = m.league.trim().isNotEmpty ? m.league.trim() : 'بطولات الرابطة';
                  groupedByLeague.putIfAbsent(lName, () => []).add(m);
                }

                return Column(
                  children: [
                    // شريط تصفية الأقسام السريع (إذا وجد أكثر من قسم)
                    if (leaguesList.length > 2)
                      Container(
                        height: 38,
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          itemCount: leaguesList.length,
                          itemBuilder: (context, i) {
                            final l = leaguesList[i];
                            final isSel = l == _selectedLeague;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: ChoiceChip(
                                label: Text(
                                  l,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                    color: isSel ? Colors.white : context.appTextPrimary,
                                  ),
                                ),
                                selected: isSel,
                                selectedColor: const Color(0xFF1B5E20),
                                backgroundColor: context.appCardBackground,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSel ? Colors.transparent : context.appBorder.withOpacity(0.5),
                                  ),
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    _selectedLeague = l;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),

                    // محتوى المباريات
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                        children: [
                          // 1. قسم مباريات الفرق المفضلة إن وجدت
                          if (favoriteMatches.isNotEmpty) ...[
                            _buildSectionHeader(
                              context,
                              title: 'مباريات فرقك المفضلة',
                              icon: Icons.star_rounded,
                              iconColor: Colors.amber,
                              badgeText: '${favoriteMatches.length}',
                            ),
                            ...favoriteMatches.map((m) => _StadiumArenaMatchCard(match: m, isFavorite: true)),
                            const SizedBox(height: 14),
                          ],

                          // 2. باقي المباريات مجمعة حسب الأقسام
                          ...groupedByLeague.entries.map((entry) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                  context,
                                  title: entry.key,
                                  icon: Icons.emoji_events_rounded,
                                  iconColor: const Color(0xFF2E7D32),
                                  badgeText: '${entry.value.length} مباريات',
                                ),
                                ...entry.value.map((m) => _StadiumArenaMatchCard(match: m, isFavorite: false)),
                                const SizedBox(height: 12),
                              ],
                            );
                          }),

                          if (filteredDocs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'لا توجد مباريات مطابقة للقسم المختار.',
                                  style: TextStyle(color: context.appTextSecondary, fontSize: 13),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
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

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required String badgeText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6, right: 2, left: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: context.isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 11,
                color: context.appTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String tab) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              ),
              child: Icon(Icons.sports_soccer, size: 44, color: context.appTextSecondary.withOpacity(0.4)),
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyTitle(tab),
              style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'الموسم الرياضي 2026-2027: ستظهر المباريات والنتائج فور انطلاق الجولات الرسمية.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appTextSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmptyTitle(String tab) {
    switch (tab) {
      case 'اليوم':
        return 'لا توجد مباريات اليوم';
      case 'الأمس':
        return 'لا توجد مباريات مسجلة بالأمس';
      case 'غداً':
        return 'لا توجد مباريات مبرمجة للغد';
      case 'الأسبوع':
        return 'لا توجد مباريات مبرمجة هذا الأسبوع';
      default:
        return 'لا توجد مباريات ($tab)';
    }
  }
}

// ─── بطاقة المباراة بتصميم "Stadium Arena" الفخم ────────────────────
class _StadiumArenaMatchCard extends StatelessWidget {
  final MatchModel match;
  final bool isFavorite;

  const _StadiumArenaMatchCard({
    required this.match,
    this.isFavorite = false,
  });

  bool get _isFinished => match.isFinished;

  bool get _isLive => match.isLive;

  int? get _score1Num => int.tryParse(match.score1);
  int? get _score2Num => int.tryParse(match.score2);

  bool get _team1Won =>
      _isFinished && _score1Num != null && _score2Num != null && _score1Num! > _score2Num!;
  bool get _team2Won =>
      _isFinished && _score1Num != null && _score2Num != null && _score2Num! > _score1Num!;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFavorite
              ? Colors.amber.shade400
              : (_isLive
                  ? Colors.redAccent.withOpacity(0.8)
                  : context.appBorder.withOpacity(0.7)),
          width: isFavorite || _isLive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isFavorite
                ? Colors.amber.withOpacity(0.12)
                : (_isLive
                    ? Colors.red.withOpacity(0.15)
                    : (isDark ? Colors.black.withOpacity(0.25) : const Color(0xFF1B5E20).withOpacity(0.06))),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // ── شريط رأس البطاقة: الحالة والجولة ──────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // حالة المباراة (مباشر / منتهية / توقيت)
                    _buildStatusPill(context),

                    // الجولة واسم الدوري المصغر
                    Row(
                      children: [
                        if (isFavorite) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade400, width: 0.8),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.star, color: Colors.amber, size: 11),
                                SizedBox(width: 3),
                                Text(
                                  'مفضل',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Text(
                          match.round.isNotEmpty ? match.round : 'لقاء رسمي',
                          style: TextStyle(
                            color: context.appTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── ساحة المواجهة (Stadium Arena Core) ────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // الفريق المستضيف (يمين في RTL)
                    Expanded(
                      flex: 4,
                      child: _TeamArenaColumn(
                        name: match.team1,
                        isWinner: _team1Won,
                        isLoser: _team2Won,
                      ),
                    ),

                    // كبسولة النتيجة الرقمية (Scoreboard LCD) في المنتصف
                    Expanded(
                      flex: 3,
                      child: _buildScoreboardCapsule(context),
                    ),

                    // الفريق الضيف (يسار في RTL)
                    Expanded(
                      flex: 4,
                      child: _TeamArenaColumn(
                        name: match.team2,
                        isWinner: _team2Won,
                        isLoser: _team1Won,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: context.appBorder.withOpacity(0.5), thickness: 0.7),
                const SizedBox(height: 8),

                // ── تذييل البطاقة: تفاصيل الملعب وأيقونة الانتقال ─────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: context.appTextSecondary.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          match.date.isNotEmpty ? match.date : 'الموسم 2026/2027',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.appTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'تفاصيل اللقاء',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF1B5E20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 10,
                          color: Color(0xFF1B5E20),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(BuildContext context) {
    return LiveChronometerWidget(
      match: match,
      compact: true,
    );
  }

  Widget _buildScoreboardCapsule(BuildContext context) {
    if (_isFinished || _isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isLive
                ? [const Color(0xFF2B0A0A), const Color(0xFF140505)]
                : [const Color(0xFF0C2417), const Color(0xFF06140D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isLive
                ? Colors.redAccent.withOpacity(0.4)
                : const Color(0xFF4CAF50).withOpacity(0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  match.score1,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: _team1Won
                        ? const Color(0xFF4ADE80)
                        : (_isLive ? Colors.redAccent : Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
                Text(
                  match.score2,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: _team2Won
                        ? const Color(0xFF4ADE80)
                        : (_isLive ? Colors.redAccent : Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              _isLive ? 'مباشر' : 'النتيجة',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: _isLive ? Colors.redAccent.shade100 : Colors.white54,
              ),
            ),
          ],
        ),
      );
    }

    // Scheduled Match (VS Capsule)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1B5E20).withOpacity(0.25)),
          ),
          child: Text(
            match.time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'VS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: context.appTextSecondary.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _TeamArenaColumn extends StatelessWidget {
  final String name;
  final bool isWinner;
  final bool isLoser;

  const _TeamArenaColumn({
    required this.name,
    this.isWinner = false,
    this.isLoser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // حاوية الشعار ثلاثية الأبعاد
        Container(
          width: 54,
          height: 54,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.isDarkMode
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.shade100,
            border: Border.all(
              color: isWinner
                  ? const Color(0xFF4ADE80)
                  : (context.isDarkMode ? Colors.white12 : Colors.grey.shade300),
              width: isWinner ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isWinner
                    ? const Color(0xFF4ADE80).withOpacity(0.25)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TeamLogoWidget(
            teamName: name,
            logoUrl: '',
            size: 46,
          ),
        ),
        const SizedBox(height: 8),

        // اسم الفريق مع إبراز الفائز
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isWinner)
              const Padding(
                padding: EdgeInsets.only(left: 3),
                child: Icon(Icons.check_circle, size: 12, color: Color(0xFF2E7D32)),
              ),
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.2,
                  fontWeight: isWinner ? FontWeight.w900 : FontWeight.bold,
                  color: isLoser
                      ? context.appTextSecondary.withOpacity(0.8)
                      : (isWinner ? (context.isDarkMode ? Colors.white : const Color(0xFF1B5E20)) : context.appTextPrimary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
