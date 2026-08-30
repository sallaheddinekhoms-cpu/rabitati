import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/club_logo_widget.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import 'club_profile_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final List<String> _leagues = [
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
  
  String _selectedLeague = 'جهوي أول';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          color: AppColors.cardBackground,
          child: Column(
            children: [
              const Text(
                'الرابطة الجهوية لكرة القدم البليدة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'استكشف الأقسام والأندية التابعة للرابطة',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        
        // League Selector
        Container(
          height: 50,
          color: AppColors.background,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _leagues.length,
            itemBuilder: (context, index) {
              final league = _leagues[index];
              final isSelected = league == _selectedLeague;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedLeague = league);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryOrange : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppColors.primaryOrange : AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      league,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Clubs List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('standings').where('league', isEqualTo: _selectedLeague).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('لا توجد أندية مسجلة في هذا القسم بعد.', style: TextStyle(color: AppColors.textSecondary)));
              }
              
              final docs = snapshot.data!.docs;
              docs.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;
                String teamA = dataA['team'] ?? '';
                String teamB = dataB['team'] ?? '';
                return teamA.compareTo(teamB);
              });
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final team = data['team'] ?? '';
                  final logoUrl = data['logoUrl'] ?? '';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: ClubLogoWidget(logoUrl: logoUrl, size: 40),
                      ),
                      title: Text(team, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BlocBuilder<FavoritesCubit, List<String>>(
                            builder: (ctx, favorites) {
                              final isFav = favorites.contains(team);
                              return IconButton(
                                icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? AppColors.primaryOrange : AppColors.textSecondary),
                                onPressed: () {
                                  ctx.read<FavoritesCubit>().toggleFavorite(team);
                                },
                              );
                            },
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ClubProfilePage(clubName: team, league: _selectedLeague)));
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
