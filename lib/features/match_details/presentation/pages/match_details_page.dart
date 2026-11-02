import 'package:flutter/material.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/club_logo_widget.dart';
import '../../data/models/match_model.dart';
import '../../data/repositories/matches_repository.dart';
import '../widgets/live_chronometer_widget.dart';

class MatchDetailsPage extends StatelessWidget {
  final String matchId;
  final String team1Name;
  final String team2Name;
  final String score;
  final String status;

  const MatchDetailsPage({
    super.key,
    required this.matchId,
    required this.team1Name,
    required this.team2Name,
    required this.score,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text('تفاصيل المباراة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appPrimary)),
        centerTitle: true,
        backgroundColor: context.appCardBackground,
        elevation: 0.5,
        iconTheme: IconThemeData(color: context.appPrimary),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: MatchesRepository().getMatchDetailsStream(matchId),
        builder: (context, snap) {
          final data = snap.data ?? {};

          final liveStatus = (data['status'] ?? status).toString();
          final isLive = liveStatus == 'مباشر' || liveStatus == 'الشوط الأول' || liveStatus == 'استراحة بين الشوطين' || liveStatus == 'الشوط الثاني';
          final currentScore = data.containsKey('score1') && data.containsKey('score2')
              ? '${data['score1']} - ${data['score2']}'
              : score;

          final date = (data['date'] ?? '').toString();
          final time = (data['time'] ?? '').toString();
          final league = (data['league'] ?? '').toString();
          final round = (data['round'] ?? '').toString();
          final referee = (data['refereeMain'] ?? '').toString();

          final added1 = (data['addedTime1'] as num?)?.toInt() ?? 0;
          final added2 = (data['addedTime2'] as num?)?.toInt() ?? 0;
          final int currentAddedTime = liveStatus == 'الشوط الثاني' ? added2 : (liveStatus == 'الشوط الأول' ? added1 : 0);
          final List events = (data['events'] as List?) ?? [];

          return Column(
            children: [
              // Match Header Scoreboard
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: context.appCardBackground,
                  border: Border(bottom: BorderSide(color: context.appBorder)),
                  boxShadow: context.appCardShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          TeamLogoWidget(
                            teamName: team1Name,
                            logoUrl: data['logo1'] ?? '',
                            size: 64,
                          ),
                          const SizedBox(height: 8),
                          Text(team1Name, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Builder(
                          builder: (context) {
                            final matchObj = MatchModel.fromJson(data);
                            return LiveChronometerWidget(
                              match: matchObj,
                              compact: false,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentScore,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: context.appTextPrimary),
                        ),
                        if (currentAddedTime > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+$currentAddedTime د وقت بدل ضائع',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          '$date $time',
                          style: TextStyle(color: context.appTextSecondary, fontSize: 11),
                        ),
                        if (league.isNotEmpty || round.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              [league, round].where((s) => s.isNotEmpty).join(' - '),
                              style: TextStyle(color: context.appTextSecondary, fontSize: 10),
                            ),
                          ),
                        if (referee.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'الحكم: $referee',
                              style: TextStyle(color: context.appTextSecondary, fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          TeamLogoWidget(
                            teamName: team2Name,
                            logoUrl: data['logo2'] ?? '',
                            size: 64,
                          ),
                          const SizedBox(height: 8),
                          Text(team2Name, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Match info & Tabs
              Expanded(
                child: DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.center,
                        indicatorColor: context.appPrimary,
                        labelColor: context.appPrimary,
                        unselectedLabelColor: context.appTextSecondary,
                        tabs: const [
                          Tab(text: 'أحداث المباراة'),
                          Tab(text: 'الإحصائيات'),
                          Tab(text: 'التشكيلة'),
                          Tab(text: 'المواجهات السابقة'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildTimelineTab(context, events),
                            Center(child: Text('الإحصائيات غير متوفرة بعد', style: TextStyle(color: context.appTextSecondary))),
                            Center(child: Text('التشكيلة غير متوفرة بعد', style: TextStyle(color: context.appTextSecondary))),
                            Center(child: Text('المواجهات المباشرة', style: TextStyle(color: context.appTextSecondary))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimelineTab(BuildContext context, List events) {
    if (events.isEmpty) {
      return Center(child: Text('لا توجد أحداث مسجلة لهذه المباراة.', style: TextStyle(color: context.appTextSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final data = events[index] as Map<String, dynamic>;
        final type = data['type'] ?? 'هدف';
        final team = data['team'] ?? '';
        final minute = data['minute']?.toString() ?? '0';

        IconData icon = Icons.sports_soccer;
        Color color = const Color(0xFF1B7A36);
        String detailText = '';

        if (type == 'بطاقة صفراء') {
          icon = Icons.style;
          color = Colors.amber.shade700;
          detailText = data['player'] ?? '';
        } else if (type == 'بطاقة حمراء') {
          icon = Icons.style;
          color = Colors.red;
          detailText = data['player'] ?? '';
        } else if (type == 'تبديل') {
          icon = Icons.swap_horiz;
          color = Colors.blue;
          detailText = 'خروج: ${data['playerOut'] ?? ''} ⬇️ / دخول: ${data['playerIn'] ?? ''} ⬆️';
        } else {
          detailText = data['player'] ?? '';
        }

        return _buildEventItem(context, "د$minute", type, team, detailText, icon, color);
      },
    );
  }

  Widget _buildEventItem(BuildContext context, String time, String action, String team, String playerDetail, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(time, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: context.appTextPrimary)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: TextStyle(fontWeight: FontWeight.bold, color: context.appTextPrimary)),
                if (team.isNotEmpty) Text('$team - $playerDetail', style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
