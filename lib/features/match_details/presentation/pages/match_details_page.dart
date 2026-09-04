import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/club_logo_widget.dart';

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
    final isLive = status == 'مباشر';
    
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text('تفاصيل المباراة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appPrimary)),
        centerTitle: true,
        backgroundColor: context.appCardBackground,
        elevation: 0.5,
        iconTheme: IconThemeData(color: context.appPrimary),
      ),
      body: Column(
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
                        size: 64,
                      ),
                      const SizedBox(height: 10),
                      Text(team1Name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appTextPrimary), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Column(
                    children: [
                      Text(score, style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: isLive ? Colors.red : context.appPrimary)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLive ? Colors.red.withOpacity(0.15) : (context.isDarkMode ? Colors.grey.withOpacity(0.2) : const Color(0xFF1B7A36).withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(status, style: TextStyle(color: isLive ? Colors.red : context.appPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      TeamLogoWidget(
                        teamName: team2Name,
                        size: 64,
                      ),
                      const SizedBox(height: 10),
                      Text(team2Name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appTextPrimary), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── شريط تفاصيل المباراة ومحافظ اللقاء ─────────────────
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('matches').doc(matchId).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || !snap.data!.exists) return const SizedBox();
              final data = snap.data!.data() as Map<String, dynamic>;
              final date = (data['date'] ?? '').toString();
              final time = (data['time'] ?? '').toString();
              final delegate = (data['delegateName'] ?? data['delegateEmail'] ?? '').toString();
              final league = (data['league'] ?? '').toString();
              final round = (data['round'] ?? '').toString();
              final referee = (data['refereeMain'] ?? '').toString();

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: context.appCardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.appBorder),
                  boxShadow: context.appCardShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$league | $round', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.appPrimary)),
                        if (date.isNotEmpty || time.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 12, color: context.appTextSecondary),
                              const SizedBox(width: 4),
                              Text('$date  $time', style: TextStyle(fontSize: 12, color: context.appTextSecondary, fontWeight: FontWeight.w500)),
                            ],
                          ),
                      ],
                    ),
                    if (delegate.isNotEmpty || referee.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Divider(height: 1, color: context.appBorder),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (delegate.isNotEmpty) ...[
                            Icon(Icons.person_pin, size: 14, color: Colors.teal.shade700),
                            const SizedBox(width: 6),
                            Text('محافظ المباراة: ', style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
                            Text(delegate, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
                          ],
                          if (referee.isNotEmpty) ...[
                            const Spacer(),
                            Icon(Icons.sports, size: 14, color: context.appTextSecondary),
                            const SizedBox(width: 4),
                            Text('الحكم: $referee', style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    indicatorColor: context.appPrimary,
                    labelColor: context.appPrimary,
                    unselectedLabelColor: context.appTextSecondary,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'الأحداث'),
                      Tab(text: 'الإحصائيات'),
                      Tab(text: 'التشكيلة'),
                      Tab(text: 'المواجهات'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTimelineTab(context),
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
      ),
    );
  }

  Widget _buildTimelineTab(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .collection('events')
          .orderBy('minute', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: context.appPrimary));
        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return Center(child: Text('لا توجد أحداث مسجلة لهذه المباراة.', style: TextStyle(color: context.appTextSecondary)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final type = data['type'] ?? 'هدف';
            final team = data['team'] ?? '';
            final minute = data['minute']?.toString() ?? '0';
            final player = data['player'] ?? '';

            IconData icon = Icons.sports_soccer;
            Color color = const Color(0xFF1B7A36);

            if (type == 'بطاقة صفراء') {
              icon = Icons.style;
              color = Colors.amber.shade700;
            } else if (type == 'بطاقة حمراء') {
              icon = Icons.style;
              color = Colors.red;
            }

            return _buildEventItem(context, "$minute'", type, team, player, icon, color);
          },
        );
      },
    );
  }

  Widget _buildEventItem(BuildContext context, String time, String action, String team, String player, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(time, style: TextStyle(fontWeight: FontWeight.bold, color: context.appTextPrimary))),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: TextStyle(fontWeight: FontWeight.bold, color: context.appTextPrimary)),
                if (team.isNotEmpty) Text('$team - $player', style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
