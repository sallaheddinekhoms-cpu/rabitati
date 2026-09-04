import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/club_logo_widget.dart';
import '../cubit/standings_cubit.dart';
import '../cubit/standings_state.dart';
import '../../data/models/team_standing_model.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';

class StandingsPage extends StatefulWidget {
  const StandingsPage({super.key});

  @override
  State<StandingsPage> createState() => _StandingsPageState();
}

class _StandingsPageState extends State<StandingsPage> {
  static const List<String> _allLeagues = [
    'جهوي أول',
    'جهوي ثاني فوج أ',
    'جهوي ثاني فوج ب',
    'فوج النخبة',
    'المستوى الأول فوج أ',
    'المستوى الأول فوج ب',
    'المستوى الجهوي فوج أ',
    'المستوى الجهوي فوج ب',
    'المستوى الجهوي فوج ج',
  ];

  List<String> _visibleLeagues = ['جهوي أول', 'جهوي ثاني فوج أ', 'جهوي ثاني فوج ب'];
  bool _loadingLeagues = true;

  @override
  void initState() {
    super.initState();
    _loadVisibleLeagues();
  }

  Future<void> _loadVisibleLeagues() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('leagues_visibility')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final visible = _allLeagues.where((l) => data[l] as bool? ?? false).toList();
        if (mounted) setState(() {
          _visibleLeagues = visible.isEmpty ? _allLeagues.take(3).toList() : visible;
          _loadingLeagues = false;
        });
      } else {
        if (mounted) setState(() {
          _visibleLeagues = _allLeagues.take(3).toList();
          _loadingLeagues = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLeagues = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StandingsCubit>();

    return Column(
      children: [
        // League Selector — pill style
        Container(
          color: context.appBackground,
          padding: const EdgeInsets.symmetric(vertical: 10),
          height: 60,
          child: _loadingLeagues
              ? Center(child: CircularProgressIndicator(color: context.appPrimary))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _visibleLeagues.length,
                  itemBuilder: (context, index) {
                    final league = _visibleLeagues[index];
                    return BlocBuilder<StandingsCubit, StandingsState>(
                      builder: (context, state) {
                        final isSelected = league == cubit.currentLeague;
                        return GestureDetector(
                          onTap: () { if (!isSelected) cubit.loadStandings(league); },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? context.appPrimary : context.appCardBackground,
                              borderRadius: BorderRadius.circular(24),
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
                            child: Center(
                              child: Text(
                                league,
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
                  },
                ),
        ),

        // Standings Table
        Expanded(
          child: BlocBuilder<StandingsCubit, StandingsState>(
            builder: (context, state) {
              if (state is StandingsLoading || state is StandingsInitial) {
                return Center(child: CircularProgressIndicator(color: context.appPrimary));
              } else if (state is StandingsError) {
                return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
              } else if (state is StandingsLoaded) {
                final docs = state.standings;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 64, color: context.appTextSecondary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('لا توجد أندية مسجلة في ${cubit.currentLeague} حالياً.', style: TextStyle(color: context.appTextSecondary)),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.appCardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.appBorder),
                        boxShadow: context.appCardShadow,
                      ),
                      child: Column(
                        children: [
                          _buildTableHeader(context),
                          ...docs.asMap().entries.map((entry) {
                            int index = entry.key;
                            TeamStandingModel team = entry.value;
                            return _buildTableRow(
                              context: context,
                              rank: index + 1,
                              team: team.team,
                              played: team.played,
                              gd: team.gd,
                              points: team.points,
                              isLast: index == docs.length - 1,
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: context.isDarkMode ? Colors.white.withOpacity(0.02) : const Color(0xFFEAF5EE).withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('#', style: TextStyle(color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text('النادي', style: TextStyle(color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.bold))),
          Expanded(child: Text('لعب', style: TextStyle(color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(child: Text('فارق', style: TextStyle(color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(child: Text('نقاط', style: TextStyle(color: context.appTextSecondary, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildTableRow({required BuildContext context, required int rank, required String team, required int played, required int gd, required int points, required bool isLast}) {
    Color? rankColor;
    if (rank <= 3) {
      rankColor = const Color(0xFF1B7A36).withOpacity(context.isDarkMode ? 0.12 : 0.05);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: rankColor,
        border: isLast ? null : Border(bottom: BorderSide(color: context.appBorder, width: 0.6)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: rank <= 3 ? context.appPrimary.withOpacity(0.12) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                rank.toString(),
                style: TextStyle(
                  color: rank <= 3 ? context.appPrimary : context.appTextSecondary,
                  fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const SizedBox(width: 4),
                TeamLogoWidget(teamName: team, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    team,
                    style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold, fontSize: 13.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: Text(played.toString(), style: TextStyle(color: context.appTextPrimary, fontSize: 13), textAlign: TextAlign.center)),
          Expanded(child: Text(gd > 0 ? '+$gd' : gd.toString(), style: TextStyle(color: gd > 0 ? const Color(0xFF1B7A36) : (gd < 0 ? Colors.red : context.appTextPrimary), fontSize: 13, fontWeight: gd != 0 ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center)),
          Expanded(child: Text(points.toString(), style: TextStyle(color: context.appPrimary, fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}
