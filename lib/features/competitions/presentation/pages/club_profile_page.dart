import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/club_logo_widget.dart';

class ClubProfilePage extends StatelessWidget {
  final String clubName;
  final String league;

  const ClubProfilePage({super.key, required this.clubName, required this.league});

  Future<Map<String, dynamic>> _loadData() async {
    final clubs = await ApiClient().getClubs();
    final club = clubs.firstWhere(
      (c) => (c['name'] ?? '').toString().trim().toLowerCase() == clubName.trim().toLowerCase(),
      orElse: () => {
        'name': clubName,
        'logo_url': '',
        'foundation': 'غير متوفر',
        'stadium': 'غير متوفر',
        'colors': 'غير متوفر',
      },
    );

    final clubId = club['id']?.toString() ?? clubName;
    final players = await ApiClient().getClubPlayers(clubId);

    return {
      'club': club,
      'players': players,
    };
  }

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
        body: FutureBuilder<Map<String, dynamic>>(
          future: _loadData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: context.appPrimary));
            }

            final data = snapshot.data ?? {};
            final clubData = (data['club'] as Map<String, dynamic>?) ?? {};
            final List players = (data['players'] as List?) ?? [];

            final logoUrl = clubData['logo_url'] ?? clubData['logoUrl'] ?? '';
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
                players.isEmpty
                    ? Center(child: Text('لا توجد قائمة لاعبين حالياً', style: TextStyle(color: context.appTextSecondary)))
                    : ListView.builder(
                        itemCount: players.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final p = players[index] as Map<String, dynamic>;
                          final number = p['jersey_number'] ?? p['number'] ?? '';
                          final name = p['name'] ?? '';
                          final position = p['position'] ?? 'لاعب';
                          final license = p['license_number'] ?? p['license'];
                          final birthDate = p['birth_date'] ?? p['birthDate'];
                          final goals = p['goals'] ?? 0;

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
                                child: Text('$number', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(name, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'المركز: $position${license != null ? ' | الإجازة: $license' : ''}',
                                    style: TextStyle(color: context.appTextSecondary, fontSize: 13),
                                  ),
                                  if (birthDate != null)
                                    Text(
                                      'الميلاد: $birthDate',
                                      style: TextStyle(color: context.appTextSecondary.withOpacity(0.8), fontSize: 11),
                                    ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sports_soccer, color: context.appPrimary, size: 16),
                                  Text('$goals', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            );
          },
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
