import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/matches_cubit.dart';
import '../cubit/matches_state.dart';
import '../../data/models/match_model.dart';
import 'match_details_page.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final List<String> _dates = ['الأمس', 'اليوم', 'غداً'];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MatchesCubit>();

    return Column(
      children: [
        // Date Selector
        Container(
          height: 60,
          color: AppColors.cardBackground,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _dates.map((date) {
              return BlocBuilder<MatchesCubit, MatchesState>(
                builder: (context, state) {
                  final isSelected = date == cubit.currentDateTab;
                  return GestureDetector(
                    onTap: () {
                      if (!isSelected) cubit.loadMatches(date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryOrange.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppColors.primaryOrange : Colors.transparent),
                      ),
                      child: Text(
                        date,
                        style: TextStyle(
                          color: isSelected ? AppColors.primaryOrange : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
        
        // Matches List
        Expanded(
          child: BlocBuilder<MatchesCubit, MatchesState>(
            builder: (context, state) {
              if (state is MatchesLoading || state is MatchesInitial) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is MatchesError) {
                return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
              } else if (state is MatchesLoaded) {
                final docs = state.matches;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_soccer, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text('لا توجد مباريات مبرمجة حالياً.', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    return _buildMatchCard(
                      context: context,
                      matchId: data.id,
                      team1: data.team1,
                      team2: data.team2,
                      score: '${data.score1} - ${data.score2}',
                      time: data.time,
                      status: data.status,
                      league: data.league,
                    );
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard({
    required BuildContext context,
    required String matchId,
    required String team1,
    required String team2,
    required String score,
    required String time,
    required String status,
    required String league,
  }) {
    final isLive = status == 'مباشر';
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchDetailsPage(
              matchId: matchId,
              team1Name: team1,
              team2Name: team2,
              score: score,
              status: status,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(league, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                      child: const Text('مباشر', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  else
                    Text(status, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const CircleAvatar(radius: 24, backgroundColor: Colors.white12, child: Icon(Icons.shield, color: Colors.white54)),
                        const SizedBox(height: 8),
                        Text(team1, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        isLive || status == 'انتهت' ? score : time,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isLive ? Colors.red : AppColors.primaryOrange),
                      ),
                      if (isLive)
                        const Padding(padding: EdgeInsets.only(top: 4), child: Text('الشوط 2', style: TextStyle(color: Colors.red, fontSize: 12))),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const CircleAvatar(radius: 24, backgroundColor: Colors.white12, child: Icon(Icons.shield, color: Colors.white54)),
                        const SizedBox(height: 8),
                        Text(team2, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}