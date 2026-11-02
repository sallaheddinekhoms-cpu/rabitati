import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/club_logo_widget.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../news/presentation/cubit/news_cubit.dart';
import '../../../news/presentation/cubit/news_state.dart';
import '../../../match_details/data/models/match_model.dart';
import '../../../match_details/presentation/cubit/matches_cubit.dart';
import '../../../match_details/presentation/cubit/matches_state.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../news/presentation/pages/news_page.dart';
import '../../../news/presentation/pages/news_details_page.dart';
import '../../../match_details/presentation/pages/match_details_page.dart';
import '../../../match_details/presentation/pages/results_page.dart';
import '../../../competitions/data/repositories/standings_repository.dart';
import '../../../competitions/data/models/team_standing_model.dart';
import '../../../competitions/presentation/pages/explore_page.dart';
import '../../../administration/presentation/pages/press_portal_page.dart';
import '../../../administration/presentation/pages/regulations_page.dart';
import '../../../match_details/presentation/widgets/live_chronometer_widget.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // ── ترويسة الواجهة الفخمة والموسم الرياضي ───────────────────
          _buildActiveSeasonBanner(context),
          
          const SizedBox(height: 18),
          // ── أزرار الوصول السريع بتصميم زجاجي راقٍ ───────────────────
          _buildQuickActions(context),

          const SizedBox(height: 22),
          // ── ساحة المباريات (أبرز المباريات والمباشر) ────────────────
          _buildSectionHeader(
            context,
            title: 'أبرز المباريات',
            subtitle: 'متابعة حية مع التوقيت المباشر',
            actionTitle: 'جدول المباريات',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResultsPage()),
            ),
          ),
          const SizedBox(height: 12),
          _buildFavoriteMatchesSection(context),
          _buildLiveMatchesSection(context),
          
          const SizedBox(height: 24),
          // ── المركز الإعلامي وأحدث الأخبار ──────────────────────────
          _buildSectionHeader(
            context,
            title: 'المركز الإعلامي',
            subtitle: 'الأخبار الرسمية والبيانات الحصرية',
            actionTitle: 'كافة الأخبار',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewsPage()),
            ),
          ),
          const SizedBox(height: 14),
          _buildNewsSection(context),
          
          const SizedBox(height: 26),
          // ── منصة الترتيب العام للأقسام ─────────────────────────────
          _buildSectionHeader(
            context,
            title: 'منصة الترتيب العام',
            subtitle: 'صدارة المنافسات الرسمية',
            actionTitle: 'عرض الكل',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExplorePage()),
            ),
          ),
          const SizedBox(height: 14),
          _buildStandingsSection(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── بطاقة ترويسة الموسم الرياضي الملكية الفخمة ───────────────────
  Widget _buildActiveSeasonBanner(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0F2B1D), Color(0xFF081810), Color(0xFF040D09)]
              : const [Color(0xFF0D5E29), Color(0xFF147A38), Color(0xFF0B4620)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0D5E29)).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // الخلفية الزخرفية للكرة والعناصر الفخمة
          Positioned(
            left: -25,
            top: -25,
            child: Icon(
              Icons.sports_soccer,
              size: 150,
              color: Colors.white.withOpacity(0.04),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4AF37).withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الشريط العلوي: شارة التغطية الرسمية + شارة الموسم الذهبية
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF4ADE80),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'الموسم الرياضي جاري • مرحلة الذهاب',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        '2026 / 2027',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // العنوان الفخم
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFF4ADE80)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الرابطة الجهوية لكرة القدم البليدة',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18.5,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Ligue Régionale de Football de Blida • التطبيق الرسمي',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // وسوم الإحصائيات الفخمة
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildBannerTag(Icons.verified, '48 نادياً معتمداً', isGold: true),
                    _buildBannerTag(Icons.calendar_month, 'برمجة أسبوعية دقيقة'),
                    _buildBannerTag(Icons.live_tv, 'متابعة حية فورية'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerTag(IconData icon, String label, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isGold
            ? const Color(0xFFD4AF37).withOpacity(0.18)
            : Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isGold
              ? const Color(0xFFD4AF37).withOpacity(0.5)
              : Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isGold ? const Color(0xFFFDE047) : Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: isGold ? const Color(0xFFFEF08A) : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── أزرار الوصول السريع الفاخرة ذات اللمسات الزجاجية ───────────
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'title': 'البرمجة والنتائج',
        'subtitle': 'المباريات الرسمية',
        'icon': Icons.sports_soccer_rounded,
        'gradient': const [Color(0xFF1B7A36), Color(0xFF0F5A24)],
        'accent': const Color(0xFF4ADE80),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultsPage())),
      },
      {
        'title': 'بوابة الصحافة',
        'subtitle': 'طلب اعتماد إعلامي',
        'icon': Icons.badge_outlined,
        'gradient': const [Color(0xFFE8681A), Color(0xFFC2410C)],
        'accent': const Color(0xFFFDBA74),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PressPortalPage())),
      },
      {
        'title': 'استكشاف الأندية',
        'subtitle': '48 نادياً معتمداً',
        'icon': Icons.shield_outlined,
        'gradient': const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        'accent': const Color(0xFF93C5FD),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorePage())),
      },
      {
        'title': 'النشرات والقرارات',
        'subtitle': 'اللوائح والمحاضر',
        'icon': Icons.description_outlined,
        'gradient': const [Color(0xFF9333EA), Color(0xFF7E22CE)],
        'accent': const Color(0xFFD8B4FE),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegulationsPage())),
      },
    ];

    return SizedBox(
      height: 98,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: actions.length,
        itemBuilder: (context, i) {
          final a = actions[i];
          final gradient = a['gradient'] as List<Color>;
          final accent = a['accent'] as Color;

          return GestureDetector(
            onTap: a['onTap'] as VoidCallback,
            child: Container(
              width: 154,
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.appCardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.appBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(context.isDarkMode ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.first.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(a['icon'] as IconData, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          a['title'] as String,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: context.appTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          a['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: context.appTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? actionTitle,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B7A36), Color(0xFFD4AF37)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w900,
                      color: context.appTextPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.appTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (actionTitle != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: context.appPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      actionTitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: context.appPrimary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_forward_ios, size: 10, color: context.appPrimary),
                  ],
                ),
              ),
            ),
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
              final favMatches = matchState.matches
                  .where((m) => favorites.contains(m.team1) || favorites.contains(m.team2))
                  .toList();
              if (favMatches.isEmpty) return const SizedBox();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'مباريات فرقك المفضلة',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: context.appTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 158,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: favMatches.length,
                      itemBuilder: (context, index) {
                        return _buildPrestigiousMatchCard(context, favMatches[index], isFavorite: true);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
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
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        } else if (state is MatchesError) {
          return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
        } else if (state is MatchesLoaded) {
          final matches = state.matches.take(6).toList();
          if (matches.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.appCardBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.appBorder),
                ),
                child: Column(
                  children: [
                    Icon(Icons.sports_soccer, size: 36, color: context.appTextSecondary.withOpacity(0.5)),
                    const SizedBox(height: 8),
                    Text(
                      'لا توجد مباريات مبرمجة حالياً',
                      style: TextStyle(color: context.appTextSecondary, fontSize: 13.5, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          
          return SizedBox(
            height: 158,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                return _buildPrestigiousMatchCard(context, matches[index]);
              },
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  // ── بطاقة المباراة الفخمة مع الكرونومتر المباشر ───────────────
  Widget _buildPrestigiousMatchCard(BuildContext context, MatchModel match, {bool isFavorite = false}) {
    final isDark = context.isDarkMode;
    final isLive = match.isLive;
    final isFinished = match.isFinished;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchDetailsPage(
              matchId: match.id,
              team1Name: match.team1,
              team2Name: match.team2,
              score: '${match.score1}-${match.score2}',
              status: match.status,
            ),
          ),
        );
      },
      child: Container(
        width: 295,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLive
                ? (isDark
                    ? const [Color(0xFF260D0D), Color(0xFF160606)]
                    : const [Color(0xFFFFF4F4), Color(0xFFFFECEC)])
                : (isDark
                    ? const [Color(0xFF18241D), Color(0xFF101914)]
                    : const [Colors.white, Color(0xFFF9FBFA)]),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLive
                ? const Color(0xFFEF4444).withOpacity(0.65)
                : (isFavorite
                    ? const Color(0xFFD4AF37).withOpacity(0.6)
                    : (isDark ? Colors.white.withOpacity(0.09) : const Color(0xFFE2E8F0))),
            width: isLive ? 1.5 : (isFavorite ? 1.3 : 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: isLive
                  ? const Color(0xFFEF4444).withOpacity(0.18)
                  : (isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04)),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: -12,
              bottom: -12,
              child: Icon(
                Icons.sports_soccer,
                size: 75,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.025),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // الشريط العلوي: اسم القسم + العداد الزمني المباشر (Chronomètre)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white12 : Colors.black.withOpacity(0.05)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          match.league.isNotEmpty ? match.league : 'الرابطة الجهوية',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: context.appTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildChronometerPill(context, match, isLive, isFinished),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // الساحة المركزية للمباراة: الفريقين والنتيجة
                  Row(
                    children: [
                      // الفريق الأول
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TeamLogoWidget(teamName: match.team1, size: 38),
                            const SizedBox(height: 5),
                            Text(
                              match.team1,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: context.appTextPrimary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // شاشة النتيجة الرقمية
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF09120C) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isLive
                                ? const Color(0xFFEF4444).withOpacity(0.4)
                                : (isDark ? Colors.white12 : Colors.black.withOpacity(0.06)),
                          ),
                        ),
                        child: isLive || isFinished
                            ? Text(
                                '${match.score1}  -  ${match.score2}',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: isLive
                                      ? const Color(0xFFEF4444)
                                      : context.appTextPrimary,
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    match.time.isNotEmpty ? match.time : '--:--',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: context.appPrimary,
                                    ),
                                  ),
                                  if (match.date.isNotEmpty)
                                    Text(
                                      match.date,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: context.appTextSecondary,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      // الفريق الثاني
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TeamLogoWidget(teamName: match.team2, size: 38),
                            const SizedBox(height: 5),
                            Text(
                              match.team2,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: context.appTextPrimary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // الشريط السفلي: الجولة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 11, color: context.appTextSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          match.round.isNotEmpty ? 'الجولة: ${match.round}' : 'مباراة رسمية',
                          style: TextStyle(fontSize: 10, color: context.appTextSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── مؤشر الكرونومتر المباشر (Chronomètre) ─────────────────────
  Widget _buildChronometerPill(BuildContext context, MatchModel match, bool isLive, bool isFinished) {
    return LiveChronometerWidget(
      match: match,
      compact: true,
    );
  }

  // ── قسم أحدث الأخبار التفاعلي الفاخر (Magazine Layout) ────────
  Widget _buildNewsSection(BuildContext context) {
    return BlocBuilder<NewsCubit, NewsState>(
      builder: (context, state) {
        if (state is NewsLoading) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
        }
        if (state is NewsLoaded) {
          if (state.news.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('لا توجد أخبار منشورة حالياً.', style: TextStyle(color: context.appTextSecondary)),
            );
          }

          final featuredNews = state.news.first;
          final otherNews = state.news.skip(1).take(5).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. الخبر البارز الرئيسي الملكي
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailsPage(news: featuredNews))),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 215,
                  decoration: BoxDecoration(
                    color: context.appCardBackground,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: context.appBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(context.isDarkMode ? 0.35 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (featuredNews.imageUrl.isNotEmpty)
                        AppImage(
                          imageUrl: featuredNews.imageUrl,
                          fit: BoxFit.cover,
                          fallback: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [Color(0xFF0F3D1C), Color(0xFF071C0D)]),
                            ),
                            child: const Center(child: Icon(Icons.newspaper, size: 64, color: Colors.white24)),
                          ),
                        )
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF0F3D1C), Color(0xFF071C0D)]),
                          ),
                          child: const Center(child: Icon(Icons.newspaper, size: 64, color: Colors.white24)),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.2),
                              (context.isDarkMode ? AppColors.darkBackground : Colors.black87).withOpacity(0.95),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF1B7A36), Color(0xFF15652C)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Text(
                                    featuredNews.category,
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (featuredNews.timestamp != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 11, color: Colors.white70),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${featuredNews.timestamp!.year}/${featuredNews.timestamp!.month.toString().padLeft(2, '0')}/${featuredNews.timestamp!.day.toString().padLeft(2, '0')}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              featuredNews.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: const [
                                Text(
                                  'اضغط للمطالعة الكاملة للخبر',
                                  style: TextStyle(
                                    color: Color(0xFF86EFAC),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF86EFAC)),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),

              // 2. قائمة الأخبار الأخرى الأحدث بتصميم مميز
              if (otherNews.isNotEmpty) ...[
                const SizedBox(height: 14),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: otherNews.length,
                    itemBuilder: (context, idx) {
                      final item = otherNews[idx];
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailsPage(news: item))),
                        child: Container(
                          width: 260,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.appCardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.appBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(context.isDarkMode ? 0.2 : 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 80,
                                  height: double.infinity,
                                  color: context.appPrimary.withOpacity(0.08),
                                  child: item.imageUrl.isNotEmpty
                                      ? AppImage(
                                          imageUrl: item.imageUrl,
                                          fit: BoxFit.cover,
                                          fallback: const Icon(Icons.newspaper, color: Colors.grey),
                                        )
                                      : const Icon(Icons.newspaper, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: context.appPrimary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.category,
                                        style: TextStyle(color: context.appPrimary, fontSize: 9.5, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: context.appTextPrimary,
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── أزرار التبديل الفاخرة بين الأقسام الثلاثة ─────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: context.isDarkMode ? Colors.white.withOpacity(0.03) : const Color(0xFFF7FAF8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
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
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF1B7A36), Color(0xFF135A27)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF1B7A36).withOpacity(0.35),
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

          // ── عرض الثلاثة الأوائل للقسم المختار بنمط منصة التتويج ──────────
          StreamBuilder<List<TeamStandingModel>>(
            stream: StandingsRepository().getStandingsStream(_selectedLeague),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(28.0),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }

              final standings = snapshot.data ?? [];
              if (standings.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text('لا توجد بيانات مسجلة في $_selectedLeague حالياً.', style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                  ),
                );
              }

              final top3 = standings.take(3).toList();

              return Column(
                children: top3.asMap().entries.map((entry) {
                  int index = entry.key;
                  final item = entry.value;
                  final teamName = item.team;
                  final logoUrl = item.logoUrl;
                  final points = item.points;

                  Color rankColor;
                  if (index == 0) {
                    rankColor = const Color(0xFFD4AF37); // Gold
                  } else if (index == 1) {
                    rankColor = const Color(0xFF94A3B8); // Silver
                  } else {
                    rankColor = const Color(0xFFCD7F32); // Bronze
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                    decoration: BoxDecoration(
                      color: index == 0 ? context.appPrimary.withOpacity(context.isDarkMode ? 0.12 : 0.05) : null,
                      border: index < top3.length - 1
                          ? Border(bottom: BorderSide(color: context.appBorder, width: 0.5))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: rankColor,
                            boxShadow: [
                              BoxShadow(
                                color: rankColor.withOpacity(0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 14),
                        TeamLogoWidget(teamName: teamName, logoUrl: logoUrl, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            teamName,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: context.appTextPrimary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: index == 0
                                ? LinearGradient(
                                    colors: [
                                      context.appPrimary.withOpacity(0.2),
                                      context.appPrimary.withOpacity(0.1),
                                    ],
                                  )
                                : null,
                            color: index != 0
                                ? (context.isDarkMode ? Colors.white10 : const Color(0xFFF1F5F9))
                                : null,
                            borderRadius: BorderRadius.circular(10),
                            border: index == 0
                                ? Border.all(color: context.appPrimary.withOpacity(0.3))
                                : null,
                          ),
                          child: Text(
                            '$points ن',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: index == 0 ? context.appPrimary : context.appTextPrimary,
                              fontSize: 13,
                            ),
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
