import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/network/api_client.dart';

class LineupSetupDialog extends StatefulWidget {
  final String matchId;
  final String team1;
  final String team2;

  const LineupSetupDialog({
    super.key,
    required this.matchId,
    required this.team1,
    required this.team2,
  });

  @override
  State<LineupSetupDialog> createState() => _LineupSetupDialogState();
}

class _LineupSetupDialogState extends State<LineupSetupDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> team1Players = [];
  List<Map<String, dynamic>> team2Players = [];
  
  Map<String, String> team1Selection = {};
  Map<String, String> team2Selection = {};
  
  String _team1SearchQuery = '';
  String _team2SearchQuery = '';
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlayersAndLineup();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayersAndLineup() async {
    setState(() => _isLoading = true);

    try {
      // 1. محاولة جلب اللاعبين من فايربيز إن توفر
      try {
        final t1Snapshot = await FirebaseFirestore.instance
            .collection('players')
            .where('clubName', isEqualTo: widget.team1)
            .get();
        team1Players = t1Snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        
        final t2Snapshot = await FirebaseFirestore.instance
            .collection('players')
            .where('clubName', isEqualTo: widget.team2)
            .get();
        team2Players = t2Snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      } catch (fe) {
        debugPrint("Firestore players fetch error or quota: $fe");
      }

      // 2. إذا كانت القوائم فارغة، نحاول جلبها من خادم REST API
      if (team1Players.isEmpty || team2Players.isEmpty) {
        try {
          final clubs = await ApiClient().getClubs();
          final c1 = clubs.firstWhere(
            (c) => c['name'] == widget.team1 || (c['short_name'] != null && c['short_name'] == widget.team1),
            orElse: () => {},
          );
          final c2 = clubs.firstWhere(
            (c) => c['name'] == widget.team2 || (c['short_name'] != null && c['short_name'] == widget.team2),
            orElse: () => {},
          );

          if (team1Players.isEmpty && c1['id'] != null) {
            final p1 = await ApiClient().getClubPlayers(c1['id'].toString());
            team1Players = p1.map((p) => {
              'id': p['id']?.toString() ?? '',
              'name': p['name'] ?? '',
              'number': p['number'] ?? '',
              'position': p['position'] ?? '',
              'license': p['license'] ?? '',
            }).toList();
          }

          if (team2Players.isEmpty && c2['id'] != null) {
            final p2 = await ApiClient().getClubPlayers(c2['id'].toString());
            team2Players = p2.map((p) => {
              'id': p['id']?.toString() ?? '',
              'name': p['name'] ?? '',
              'number': p['number'] ?? '',
              'position': p['position'] ?? '',
              'license': p['license'] ?? '',
            }).toList();
          }
        } catch (ae) {
          debugPrint("API players fetch fallback error: $ae");
        }
      }

      // 3. فحص التشكيلة المحفوظة سابقاً
      try {
        final matchDoc = await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).get();
        final matchData = matchDoc.data();
        if (matchData != null) {
          if (matchData['team1Lineup'] != null) {
            for (var p in matchData['team1Lineup']) {
              team1Selection[p['id'].toString()] = p['status']?.toString() ?? 'starter';
            }
          }
          if (matchData['team2Lineup'] != null) {
            for (var p in matchData['team2Lineup']) {
              team2Selection[p['id'].toString()] = p['status']?.toString() ?? 'starter';
            }
          }
        }
      } catch (me) {
        debugPrint("Match lineup doc fetch error: $me");
      }

      // 4. إذا كانت القوائم فارغة، ننشئ تلقائياً قائمة أرقام اللاعبين (1 إلى 18) حتى لا يتعطل المحافظ
      if (team1Players.isEmpty) {
        const prefix = 't1';
        team1Players = List.generate(18, (i) {
          final num = i + 1;
          return {
            'id': '${prefix}_$num',
            'name': num == 1 ? 'رقم 1 (حارس)' : 'رقم $num',
            'number': '$num',
            'position': num == 1 ? 'GK' : (num <= 11 ? 'FLD' : 'SUB'),
            'license': '',
          };
        });
        if (team1Selection.isEmpty) {
          for (int i = 1; i <= 18; i++) {
            team1Selection['${prefix}_$i'] = i <= 11 ? 'starter' : 'sub';
          }
        }
      }

      if (team2Players.isEmpty) {
        const prefix = 't2';
        team2Players = List.generate(18, (i) {
          final num = i + 1;
          return {
            'id': '${prefix}_$num',
            'name': num == 1 ? 'رقم 1 (حارس)' : 'رقم $num',
            'number': '$num',
            'position': num == 1 ? 'GK' : (num <= 11 ? 'FLD' : 'SUB'),
            'license': '',
          };
        });
        if (team2Selection.isEmpty) {
          for (int i = 1; i <= 18; i++) {
            team2Selection['${prefix}_$i'] = i <= 11 ? 'starter' : 'sub';
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading lineups: $e");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _generateQuickNumbers(bool isTeam1) {
    final prefix = isTeam1 ? 't1' : 't2';
    final List<Map<String, dynamic>> gen = List.generate(18, (i) {
      final num = i + 1;
      return {
        'id': '${prefix}_$num',
        'name': num == 1 ? 'رقم 1 (حارس)' : 'رقم $num',
        'number': '$num',
        'position': num == 1 ? 'GK' : (num <= 11 ? 'FLD' : 'SUB'),
        'license': '',
      };
    });

    setState(() {
      if (isTeam1) {
        team1Players = gen;
        team1Selection.clear();
        for (int i = 1; i <= 18; i++) {
          team1Selection['${prefix}_$i'] = i <= 11 ? 'starter' : 'sub';
        }
      } else {
        team2Players = gen;
        team2Selection.clear();
        for (int i = 1; i <= 18; i++) {
          team2Selection['${prefix}_$i'] = i <= 11 ? 'starter' : 'sub';
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ تم إعداد قائمة أرقام اللاعبين (1 إلى 18) لـ ${isTeam1 ? widget.team1 : widget.team2} بنجاح!'),
        backgroundColor: const Color(0xFF0F766E),
      ),
    );
  }

  Future<void> _saveLineup() async {
    int t1Starters = team1Selection.values.where((v) => v == 'starter').length;
    int t2Starters = team2Selection.values.where((v) => v == 'starter').length;

    if (t1Starters != 11 || t2Starters != 11) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text('تنبيه بخصوص التشكيلة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'عدد اللاعبين الأساسيين:\n• ${widget.team1}: $t1Starters / 11\n• ${widget.team2}: $t2Starters / 11\n\nهل ترغب بحفظ التشكيلة بهذه الحالة؟',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('متابعة التعديل')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حفظ على أي حال', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isSaving = true);

    List<Map<String, dynamic>> t1Lineup = [];
    for (var p in team1Players) {
      final s = team1Selection[p['id'].toString()];
      if (s != null) {
        t1Lineup.add({
          'id': p['id'],
          'name': p['name'],
          'number': p['number'],
          'position': p['position'],
          'status': s,
        });
      }
    }

    List<Map<String, dynamic>> t2Lineup = [];
    for (var p in team2Players) {
      final s = team2Selection[p['id'].toString()];
      if (s != null) {
        t2Lineup.add({
          'id': p['id'],
          'name': p['name'],
          'number': p['number'],
          'position': p['position'],
          'status': s,
        });
      }
    }

    try {
      // 1. Sync with Laravel REST API
      try {
        await ApiClient().updateMatchLineup(widget.matchId, t1Lineup, t2Lineup);
      } catch (ae) {
        debugPrint("API updateMatchLineup error: $ae");
      }

      // 2. Sync with Firebase Firestore
      try {
        await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
          'team1Lineup': t1Lineup,
          'team2Lineup': t2Lineup,
        });
      } catch (fe) {
        debugPrint("Firestore update lineup error: $fe");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ تم حفظ واعتماد التشكيلة الرسمية للمباراة بنجاح!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء حفظ التشكيلة: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTeamTab(
    String teamName,
    List<Map<String, dynamic>> players,
    Map<String, String> selection,
    String searchQuery,
    ValueChanged<String> onSearchChanged,
    bool isTeam1,
  ) {
    if (players.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'لا توجد قائمة لاعبين مسجلة لفريق $teamName حالياً.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'يمكن إدخال اللاعبين وتحديثهم من لوحة التحكم في الموقع.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        ),
      );
    }

    final int startersCount = selection.values.where((v) => v == 'starter').length;
    final int subsCount = selection.values.where((v) => v == 'sub').length;

    // Filter players by search query
    final filteredPlayers = players.where((p) {
      if (searchQuery.trim().isEmpty) return true;
      final q = searchQuery.trim().toLowerCase();
      final name = (p['name'] ?? '').toString().toLowerCase();
      final numStr = (p['number'] ?? '').toString();
      return name.contains(q) || numStr.contains(q);
    }).toList();

    return Column(
      children: [
        // ── شريط إحصائيات التشكيلة والبحث ──────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: Colors.grey.shade50,
          child: Column(
            children: [
              Row(
                children: [
                  // عداد الأساسيين
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: startersCount == 11 ? Colors.green.shade50 : (startersCount > 11 ? Colors.red.shade50 : Colors.blue.shade50),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: startersCount == 11 ? Colors.green.shade300 : (startersCount > 11 ? Colors.red.shade300 : Colors.blue.shade300),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            startersCount == 11 ? Icons.check_circle : (startersCount > 11 ? Icons.error : Icons.groups),
                            color: startersCount == 11 ? Colors.green.shade700 : (startersCount > 11 ? Colors.red.shade700 : Colors.blue.shade700),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'الأساسيون: $startersCount / 11',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: startersCount == 11 ? Colors.green.shade900 : (startersCount > 11 ? Colors.red.shade900 : Colors.blue.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // عداد البدلاء
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swap_horiz, color: Colors.orange.shade700, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'الاحتياط: $subsCount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _generateQuickNumbers(isTeam1),
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: const Text('⚡ تعبئة أرقام القمصان القياسية (1 إلى 18) لهذا الفريق', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // حقل البحث السريع بالاسم أو الرقم
              SizedBox(
                height: 38,
                child: TextField(
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'بحث عن لاعب بالاسم أو الرقم...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── قائمة اللاعبين بتصميم عريض ومريح ──────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            itemCount: filteredPlayers.length,
            itemBuilder: (context, index) {
              final p = filteredPlayers[index];
              final String pId = p['id'].toString();
              final String? status = selection[pId];

              final bool isStarter = status == 'starter';
              final bool isSub = status == 'sub';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isStarter 
                      ? Colors.green.shade50 
                      : (isSub ? Colors.orange.shade50 : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isStarter 
                        ? Colors.green.shade400 
                        : (isSub ? Colors.orange.shade400 : Colors.grey.shade200),
                    width: (isStarter || isSub) ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // السطر الأول: رقم اللاعب + الاسم بالعرض الكامل + شارة الحالة
                    Row(
                      children: [
                        // دائرة رقم القميص
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isStarter 
                                ? Colors.green.shade700 
                                : (isSub ? Colors.orange.shade700 : Colors.blueGrey.shade100),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            p['number']?.toString().isNotEmpty == true ? p['number'].toString() : '•',
                            style: TextStyle(
                              color: (isStarter || isSub) ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // اسم اللاعب عريض وبدون أي تقطيع
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['name']?.toString() ?? 'لاعب غير مسمى',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isStarter ? Colors.green.shade900 : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if ((p['position'] != null && p['position'].toString().isNotEmpty) ||
                                  (p['license'] != null && p['license'].toString().isNotEmpty))
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '${p['position'] ?? ''} ${p['license'] != null ? '• إجازة: ${p['license']}' : ''}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // شارة الحالة
                        if (isStarter)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('أساسي 🟢', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        else if (isSub)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('احتياط 🟡', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // السطر الثاني: أزرار التحديد المباشرة السريعة (3 أزرار أفقية سهلة اللمس)
                    Row(
                      children: [
                        // زر أساسي
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selection[pId] = 'starter';
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isStarter ? Colors.green.shade700 : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isStarter ? Colors.green.shade700 : Colors.grey.shade300,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'أساسي (11)',
                                  style: TextStyle(
                                    color: isStarter ? Colors.white : Colors.black87,
                                    fontWeight: isStarter ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // زر احتياط
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selection[pId] = 'sub';
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSub ? Colors.orange.shade700 : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSub ? Colors.orange.shade700 : Colors.grey.shade300,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'احتياط',
                                  style: TextStyle(
                                    color: isSub ? Colors.white : Colors.black87,
                                    fontWeight: isSub ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // زر غير مستدعى
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selection.remove(pId);
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: (!isStarter && !isSub) ? Colors.blueGrey.shade100 : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (!isStarter && !isSub) ? Colors.blueGrey.shade400 : Colors.grey.shade300,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'غير مستدعى',
                                  style: TextStyle(
                                    color: (!isStarter && !isSub) ? Colors.blueGrey.shade900 : Colors.grey.shade600,
                                    fontWeight: (!isStarter && !isSub) ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 700;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 30,
          vertical: isMobile ? 12 : 25,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: isMobile ? double.infinity : 750,
          height: isMobile ? size.height * 0.92 : 720,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('جاري تحميل قوائم لاعبي الفريقين...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // ── شريط العنوان العلوي ────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F261B), Color(0xFF1B5E20)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people_alt, color: Colors.white, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'إعداد التشكيلة الرسمية للمباراة',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${widget.team1} ضد ${widget.team2}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // ── شريط التبويب بين الفريقين ────────────────────
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF1B5E20),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: const Color(0xFF1B5E20),
                        indicatorWeight: 3,
                        tabs: [
                          Tab(text: widget.team1),
                          Tab(text: widget.team2),
                        ],
                      ),
                    ),

                    // ── صفحات التشكيلة للفريقين ─────────────────────
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTeamTab(
                            widget.team1,
                            team1Players,
                            team1Selection,
                            _team1SearchQuery,
                            (q) => setState(() => _team1SearchQuery = q),
                            true,
                          ),
                          _buildTeamTab(
                            widget.team2,
                            team2Players,
                            team2Selection,
                            _team2SearchQuery,
                            (q) => setState(() => _team2SearchQuery = q),
                            false,
                          ),
                        ],
                      ),
                    ),

                    // ── شريط أزرار الحفظ والإغلاق السفلي ─────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _saveLineup,
                              icon: _isSaving
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.check_circle, color: Colors.white),
                              label: Text(
                                _isSaving ? 'جاري الحفظ...' : 'حفظ واعتماد التشكيلة',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('إلغاء'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}