import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../data/repositories/standings_repository.dart';
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
  ];

  late String _selectedLeague;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLeague = _leagues.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getLeagueId(String league) {
    if (league.contains('فوج ب') || league.endsWith('ب')) return '3';
    if (league.contains('فوج أ') || league.endsWith('أ')) return '2';
    return '1';
  }

  Future<List<Map<String, dynamic>>> _fetchClubs(String league) async {
    final leagueId = _getLeagueId(league);
    try {
      final clubs = await ApiClient().getClubs(leagueId: leagueId);
      if (clubs.isNotEmpty) {
        return clubs.map((c) => {
          'id': c['id']?.toString() ?? '',
          'team': (c['name'] ?? c['short_name'] ?? '').toString().trim(),
          'logoUrl': (c['logo_url'] ?? c['logo'] ?? '').toString().trim(),
          'stadium': (c['stadium'] ?? '').toString().trim(),
          'city': (c['city'] ?? '').toString().trim(),
          'league': league,
        }).toList();
      }
    } catch (_) {}

    // Fallback to Standings
    try {
      final standings = await StandingsRepository().getStandingsForLeague(league);
      return standings.map((s) => {
        'id': s.id,
        'team': s.team.trim(),
        'logoUrl': s.logoUrl.trim(),
        'stadium': '',
        'city': '',
        'league': league,
      }).toList();
    } catch (_) {}

    return [];
  }

  Widget _buildClubLogo(String logoUrl, double size) {
    final cleanLogo = logoUrl.trim();
    if (cleanLogo.isEmpty) {
      return Icon(Icons.shield, size: size, color: Colors.grey.shade400);
    }

    if (cleanLogo.startsWith('data:image')) {
      try {
        final commaIndex = cleanLogo.indexOf(',');
        final base64String = commaIndex != -1 ? cleanLogo.substring(commaIndex + 1) : cleanLogo;
        return Image.memory(
          base64Decode(base64String),
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.shield, size: size, color: Colors.grey.shade400),
        );
      } catch (_) {
        return Icon(Icons.shield, size: size, color: Colors.grey.shade400);
      }
    }

    return Image.network(
      cleanLogo,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.shield, size: size, color: Colors.grey.shade400),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: canPop
          ? AppBar(
              backgroundColor: context.appCardBackground,
              elevation: 0.5,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'استكشاف الأندية',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── الترويسة، حقل البحث وأزرار الأقسام ────────────────
              Container(
                padding: const EdgeInsets.all(16),
                color: context.appCardBackground,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!canPop) ...[
                      Text(
                        'استكشاف الأندية',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: context.appTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'استكشف الأقسام والأندية المعتمدة التابعة للرابطة (48 نادياً معتمداً)',
                        style: TextStyle(fontSize: 13, color: context.appTextSecondary),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // حقل البحث
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن اسم النادي...',
                        hintStyle: TextStyle(fontSize: 13, color: context.appTextSecondary),
                        prefixIcon: Icon(Icons.search, color: context.appPrimary, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: context.appBackground,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.appBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.appBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.appPrimary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // أزرار الأقسام
                    Row(
                      children: _leagues.map((league) {
                        final isSelected = league == _selectedLeague;
                        String label = league;
                        if (league == 'جهوي ثاني فوج أ') label = 'جهوي 2 (فوج أ)';
                        if (league == 'جهوي ثاني فوج ب') label = 'جهوي 2 (فوج ب)';

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? context.appPrimary : context.appBackground,
                                foregroundColor: isSelected ? Colors.white : context.appTextPrimary,
                                elevation: isSelected ? 2 : 0,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected ? context.appPrimary : context.appBorder,
                                    width: 1,
                                  ),
                                ),
                              ),
                              onPressed: () => setState(() => _selectedLeague = league),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 0.8),

              // ── قائمة الأندية حسب القسم المختار ─────────────────────
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  key: ValueKey(_selectedLeague),
                  future: _fetchClubs(_selectedLeague),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: context.appPrimary));
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('حدث خطأ أثناء تحميل قائمة الأندية'));
                    }

                    final clubs = snapshot.data ?? [];
                    if (clubs.isEmpty) {
                      return Center(
                        child: Text(
                          'لا توجد أندية مسجلة في $_selectedLeague بعد.',
                          style: TextStyle(color: context.appTextSecondary),
                        ),
                      );
                    }

                    final query = _searchQuery.toLowerCase();
                    final docs = clubs.where((c) {
                      if (query.isEmpty) return true;
                      return (c['team'] as String).toLowerCase().contains(query);
                    }).toList();

                    docs.sort((a, b) => (a['team'] as String).compareTo(b['team'] as String));

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'لم يتم العثور على أي نادٍ يطابق "$_searchQuery"',
                          style: TextStyle(color: context.appTextSecondary, fontSize: 14),
                        ),
                      );
                    }

                    return BlocBuilder<FavoritesCubit, List<String>>(
                      builder: (context, favorites) {
                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: docs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final club = docs[index];
                            final teamName = club['team'] as String;
                            final logoUrl = club['logoUrl'] as String;
                            final stadium = (club['stadium'] as String?) ?? '';
                            final isFavorite = favorites.contains(teamName);

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ClubProfilePage(
                                      clubName: teamName,
                                      league: _selectedLeague,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: context.appCardBackground,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isFavorite ? Colors.amber.shade600 : context.appBorder,
                                    width: isFavorite ? 1.6 : 1.0,
                                  ),
                                  boxShadow: isFavorite
                                      ? [
                                          BoxShadow(
                                            color: Colors.amber.withOpacity(0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          )
                                        ]
                                      : context.appCardShadow,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.transparent,
                                        child: _buildClubLogo(logoUrl, 40),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              teamName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: context.appTextPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              stadium.isNotEmpty ? '$_selectedLeague • $stadium' : _selectedLeague,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: context.appTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isFavorite ? Icons.star : Icons.star_border,
                                          color: isFavorite ? Colors.amber.shade600 : context.appTextSecondary,
                                          size: 26,
                                        ),
                                        tooltip: isFavorite ? 'إلغاء التفضيل' : 'إضافة للمفضلة',
                                        onPressed: () {
                                          context.read<FavoritesCubit>().toggleFavorite(teamName);
                                        },
                                      ),
                                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
