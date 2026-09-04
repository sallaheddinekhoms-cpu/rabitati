import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../cubit/favorites_cubit.dart';

class SelectFavoriteTeamPage extends StatefulWidget {
  const SelectFavoriteTeamPage({super.key});

  @override
  State<SelectFavoriteTeamPage> createState() => _SelectFavoriteTeamPageState();
}

class _SelectFavoriteTeamPageState extends State<SelectFavoriteTeamPage> {
  // الأقسام مطابقة 100% للوحة التحكم
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

  // ودجت الشعار مطابق تماماً للوحة التحكم بدون تفلسف
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
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appCardBackground,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.star, color: Colors.amber, size: 22),
            SizedBox(width: 8),
            Text(
              'تحديد الفريق المفضل',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Column(
            children: [
              // ── الترويسة، حقل البحث واختيار القسم ────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: context.appCardBackground,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // حقل البحث المباشر
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن اسم النادي...',
                        hintStyle: TextStyle(fontSize: 13, color: context.appTextSecondary),
                        prefixIcon: Icon(Icons.search, color: context.appPrimary, size: 22),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

                    // أزرار الأقسام (نفس لوحة التحكم)
                    Row(
                      children: _leagues.map((league) {
                        final isSelected = league == _selectedLeague;
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
                                league,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 12.5,
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

              // ── جلب أندية القسم مباشرة من قاعدة البيانات ─────────────
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  // استعلام مباشر مطابق 100% للوحة التحكم
                  stream: FirebaseFirestore.instance
                      .collection('standings')
                      .where('league', isEqualTo: _selectedLeague)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: context.appPrimary));
                    }

                    if (snapshot.hasError) {
                      return const Center(child: Text('حدث خطأ أثناء تحميل الأندية'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'لا توجد أندية مسجلة في $_selectedLeague بعد.',
                          style: TextStyle(color: context.appTextSecondary),
                        ),
                      );
                    }

                    // تجميع الأندية بدون تكرار لنفس القسم
                    final Map<String, Map<String, dynamic>> uniqueClubs = {};
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final team = (data['team'] ?? '').toString().trim();
                      final logoUrl = (data['logoUrl'] ?? '').toString().trim();
                      if (team.isEmpty) continue;

                      final key = team.toLowerCase();
                      if (!uniqueClubs.containsKey(key)) {
                        uniqueClubs[key] = {
                          'team': team,
                          'logoUrl': logoUrl,
                          'league': _selectedLeague,
                        };
                      } else {
                        // إذا وجدنا نسخة بها شعار، نعتمد الشعار
                        if ((uniqueClubs[key]!['logoUrl'] as String).isEmpty && logoUrl.isNotEmpty) {
                          uniqueClubs[key]!['logoUrl'] = logoUrl;
                        }
                      }
                    }

                    // تصفية البحث إن وُجد
                    final query = _searchQuery.toLowerCase();
                    final clubsList = uniqueClubs.values.where((c) {
                      if (query.isEmpty) return true;
                      return (c['team'] as String).toLowerCase().contains(query);
                    }).toList();

                    // ترتيب أبجدي أنيق
                    clubsList.sort((a, b) => (a['team'] as String).compareTo(b['team'] as String));

                    if (clubsList.isEmpty) {
                      return Center(
                        child: Text(
                          'لم يتم العثور على أي نادٍ يطابق "$_searchQuery"',
                          style: TextStyle(color: context.appTextSecondary),
                        ),
                      );
                    }

                    return BlocBuilder<FavoritesCubit, List<String>>(
                      builder: (context, favorites) {
                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: clubsList.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = clubsList[index];
                            final teamName = item['team'] as String;
                            final logoUrl = item['logoUrl'] as String;
                            final isFav = favorites.contains(teamName);

                            return Container(
                              decoration: BoxDecoration(
                                color: context.appCardBackground,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isFav ? Colors.amber.shade600 : context.appBorder,
                                  width: isFav ? 1.8 : 1.0,
                                ),
                                boxShadow: isFav
                                    ? [
                                        BoxShadow(
                                          color: Colors.amber.withValues(alpha: 0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : context.appCardShadow,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  child: _buildClubLogo(logoUrl, 42),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        teamName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isFav ? context.appPrimary : context.appTextPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isFav)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'مفضل ⭐',
                                          style: TextStyle(
                                            color: Colors.amber.shade900,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  _selectedLeague,
                                  style: TextStyle(fontSize: 12, color: context.appTextSecondary),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    isFav ? Icons.star : Icons.star_border,
                                    color: isFav ? Colors.amber.shade600 : context.appTextSecondary,
                                    size: 28,
                                  ),
                                  tooltip: isFav ? 'إلغاء التفضيل' : 'تعيين كمفضل',
                                  onPressed: () {
                                    context.read<FavoritesCubit>().toggleFavorite(teamName);
                                  },
                                ),
                                onTap: () {
                                  context.read<FavoritesCubit>().toggleFavorite(teamName);
                                },
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
