import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تفاصيل المباراة', style: TextStyle(fontSize: 18)),
        centerTitle: true,
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Match Header Scoreboard
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            color: AppColors.cardBackground,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const CircleAvatar(radius: 35, backgroundColor: Colors.white12, child: Icon(Icons.shield, size: 40, color: Colors.white)),
                    const SizedBox(height: 12),
                    Text(team1Name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                Column(
                  children: [
                    Text(score, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: isLive ? Colors.red : AppColors.primaryOrange)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: isLive ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: Text(status, style: TextStyle(color: isLive ? Colors.red : AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const CircleAvatar(radius: 35, backgroundColor: Colors.white12, child: Icon(Icons.shield, size: 40, color: Colors.white)),
                    const SizedBox(height: 12),
                    Text(team2Name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  const TabBar(
                    isScrollable: true,
                    indicatorColor: AppColors.primaryOrange,
                    labelColor: AppColors.primaryOrange,
                    unselectedLabelColor: AppColors.textSecondary,
                    tabs: [
                      Tab(text: 'الأحداث'),
                      Tab(text: 'الإحصائيات'),
                      Tab(text: 'التشكيلة'),
                      Tab(text: 'المواجهات'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTimelineTab(),
                        const Center(child: Text('الإحصائيات غير متوفرة بعد', style: TextStyle(color: AppColors.textSecondary))),
                        const Center(child: Text('التشكيلة غير متوفرة بعد', style: TextStyle(color: AppColors.textSecondary))),
                        const Center(child: Text('المواجهات المباشرة', style: TextStyle(color: AppColors.textSecondary))),
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

  Widget _buildTimelineTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .collection('events')
          .orderBy('minute', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return const Center(child: Text('لا توجد أحداث مسجلة لهذه المباراة.', style: TextStyle(color: AppColors.textSecondary)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final type = data['type'] ?? 'هدف'; // هدف, بطاقة صفراء, بطاقة حمراء
            final team = data['team'] ?? '';
            final minute = data['minute']?.toString() ?? '0';
            final player = data['player'] ?? '';

            IconData icon = Icons.sports_soccer;
            Color color = Colors.green;

            if (type == 'بطاقة صفراء') {
              icon = Icons.style;
              color = Colors.yellow;
            } else if (type == 'بطاقة حمراء') {
              icon = Icons.style;
              color = Colors.red;
            }

            return _buildEventItem("$minute'", type, team, player, icon, color);
          },
        );
      },
    );
  }

  Widget _buildEventItem(String time, String action, String team, String player, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(time, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                if (team.isNotEmpty) Text('$team - $player', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}