import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
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
  final List<String> _leagues = [
    'جهوي أول',     'جهوي ثاني فوج أ',     'جهوي ثاني فوج ب',     'فوج النخبة',     'المستوى الأول فوج أ',     'المستوى الأول فوج ب',     'المستوى الجهوي فوج أ',     'المستوى الجهوي فوج ب',     'المستوى الجهوي فوج ج',
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StandingsCubit>();

    return Column(
      children: [
        // League Selector
        Container(
          color: AppColors.cardBackground,
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _leagues.length,
            itemBuilder: (context, index) {
              final league = _leagues[index];
              return BlocBuilder<StandingsCubit, StandingsState>(
                builder: (context, state) {
                  final isSelected = league == cubit.currentLeague;
                  return GestureDetector(
                    onTap: () {
                      if (!isSelected) cubit.loadStandings(league);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: isSelected ? AppColors.primaryOrange : Colors.transparent, width: 3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          league,
                          style: TextStyle(
                            color: isSelected ? AppColors.primaryOrange : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
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
                return const Center(child: CircularProgressIndicator());
              } else if (state is StandingsError) {
                return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
              } else if (state is StandingsLoaded) {
                final docs = state.standings;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('لا توجد أندية مسجلة في ${cubit.currentLeague} حالياً.', style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Column(
                        children: [
                          _buildTableHeader(),
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

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: const [
          SizedBox(width: 30, child: Text('#', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text('النادي', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(child: Text('لعب', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(child: Text('فارق', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(child: Text('نقاط', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildTableRow({required BuildContext context, required int rank, required String team, required int played, required int gd, required int points, required bool isLast}) {
    Color? rankColor;
    if (rank <= 3) rankColor = Colors.green.withOpacity(0.1);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: rankColor, border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text(rank.toString(), style: TextStyle(color: rank <= 3 ? AppColors.primaryOrange : AppColors.textSecondary, fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center)),
                    Expanded(flex: 3, child: Row(children: [
            const SizedBox(width: 8), 
            Expanded(child: Text(team, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis))
          ])),
          Expanded(child: Text(played.toString(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13), textAlign: TextAlign.center)),
          Expanded(child: Text(gd > 0 ? '+$gd' : gd.toString(), style: TextStyle(color: gd > 0 ? Colors.green : (gd < 0 ? Colors.red : AppColors.textPrimary), fontSize: 13), textAlign: TextAlign.center)),
          Expanded(child: Text(points.toString(), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}