import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/club_logo_widget.dart';

class ClubProfilePage extends StatelessWidget {
  final String clubName;
  final String league;

  const ClubProfilePage({super.key, required this.clubName, required this.league});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.cardBackground,
          title: Text(clubName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          bottom: const TabBar(
            indicatorColor: AppColors.primaryOrange,
            labelColor: AppColors.primaryOrange,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'البطاقة الفنية'),
              Tab(text: 'اللاعبون'),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('standings').where('league', isEqualTo: league).where('team', isEqualTo: clubName).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (snapshot.data!.docs.isEmpty) return const Center(child: Text('النادي غير موجود'));
            
            final clubData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            final logoUrl = clubData['logoUrl'] ?? '';
            final foundation = clubData['foundation'] ?? 'غير متوفر';
            final president = clubData['president'] ?? 'غير متوفر';
            final coaches = clubData['coaches'] ?? 'غير متوفر';
            
            return TabBarView(
              children: [
                // Info Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        child: ClubLogoWidget(logoUrl: logoUrl, size: 80, fallbackColor: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Text(clubName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text(league, style: const TextStyle(color: AppColors.primaryOrange)),
                      const SizedBox(height: 32),
                      _buildInfoCard('سنة التأسيس', foundation, Icons.calendar_today),
                      _buildInfoCard('الرئيس الحالي', president, Icons.person),
                      _buildInfoCard('الطاقم الفني', coaches, Icons.sports),
                    ],
                  ),
                ),
                // Players Tab
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('players').where('clubName', isEqualTo: clubName).snapshots(),
                  builder: (context, pSnapshot) {
                    if (!pSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final players = pSnapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                    players.sort((a, b) => (b['goals'] ?? 0).compareTo(a['goals'] ?? 0));
                    
                    if (players.isEmpty) return const Center(child: Text('لا توجد قائمة لاعبين', style: TextStyle(color: AppColors.textSecondary)));
                    
                    return ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final p = players[index];
                        return Card(
                          color: AppColors.cardBackground,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryOrange,
                              child: Text('${p['number'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(p['name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                            subtitle: Text('المركز: ${p['position'] ?? ''}', style: const TextStyle(color: AppColors.textSecondary)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.sports_soccer, color: Colors.white, size: 16),
                                Text('${p['goals'] ?? 0}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryOrange),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
