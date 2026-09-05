import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/theme_extensions.dart';
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
        backgroundColor: context.appBackground,
        appBar: AppBar(
          backgroundColor: context.appCardBackground,
          elevation: 0.5,
          title: Text(clubName, style: TextStyle(fontWeight: FontWeight.bold, color: context.appPrimary)),
          iconTheme: IconThemeData(color: context.appPrimary),
          bottom: TabBar(
            indicatorColor: context.appPrimary,
            labelColor: context.appPrimary,
            unselectedLabelColor: context.appTextSecondary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'البطاقة الفنية'),
              Tab(text: 'اللاعبون'),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('standings').where('league', isEqualTo: league).where('team', isEqualTo: clubName).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: context.appPrimary));
            if (snapshot.data!.docs.isEmpty) return Center(child: Text('النادي غير موجود', style: TextStyle(color: context.appTextSecondary)));
            
            final clubData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            final logoUrl = clubData['logoUrl'] ?? '';
            final foundation = clubData['foundation'] ?? 'غير متوفر';
            final stadium = clubData['stadium'] ?? clubData['president'] ?? 'غير متوفر';
            final colors = clubData['colors'] ?? clubData['coaches'] ?? 'غير متوفر';
            
            return TabBarView(
              children: [
                // Info Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: context.appPrimary.withOpacity(0.3), width: 2),
                        ),
                        child: TeamLogoWidget(
                          teamName: clubName,
                          logoUrl: logoUrl,
                          size: 100,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(clubName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appTextPrimary)),
                      const SizedBox(height: 4),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.appPrimary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(league, style: TextStyle(color: context.appPrimary, fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                      const SizedBox(height: 28),
                      _buildInfoCard(context, 'سنة التأسيس', foundation, Icons.calendar_today),
                      _buildInfoCard(context, 'الملعب', stadium, Icons.stadium),
                      _buildInfoCard(context, 'الألوان', colors, Icons.palette),
                    ],
                  ),
                ),
                // Players Tab
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('players').where('clubName', isEqualTo: clubName).snapshots(),
                  builder: (context, pSnapshot) {
                    if (!pSnapshot.hasData) return Center(child: CircularProgressIndicator(color: context.appPrimary));
                    final players = pSnapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
                    players.sort((a, b) => (b['goals'] ?? 0).compareTo(a['goals'] ?? 0));
                    
                    if (players.isEmpty) return Center(child: Text('لا توجد قائمة لاعبين', style: TextStyle(color: context.appTextSecondary)));
                    
                    return ListView.builder(
                      itemCount: players.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, index) {
                        final p = players[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.appCardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.appBorder),
                            boxShadow: context.appCardShadow,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: context.appPrimary,
                              child: Text('${p['number'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(p['name'] ?? '', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
                            subtitle: Text('المركز: ${p['position'] ?? ''}', style: TextStyle(color: context.appTextSecondary)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sports_soccer, color: context.appPrimary, size: 16),
                                Text('${p['goals'] ?? 0}', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
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

  Widget _buildInfoCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.appPrimary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.appPrimary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: context.appTextPrimary, fontSize: 15.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
