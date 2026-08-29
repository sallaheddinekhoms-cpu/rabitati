import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  // Lists to hold all players for each team
  List<Map<String, dynamic>> team1Players = [];
  List<Map<String, dynamic>> team2Players = [];
  
  // Selection maps: player ID -> 'starter', 'sub', or null (unselected)
  Map<String, String> team1Selection = {};
  Map<String, String> team2Selection = {};
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlayersAndLineup();
  }

  Future<void> _loadPlayersAndLineup() async {
    setState(() => _isLoading = true);

    try {
      // Fetch players for Team 1
      final t1Snapshot = await FirebaseFirestore.instance.collection('players').where('clubName', isEqualTo: widget.team1).get();
      team1Players = t1Snapshot.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
      
      // Fetch players for Team 2
      final t2Snapshot = await FirebaseFirestore.instance.collection('players').where('clubName', isEqualTo: widget.team2).get();
      team2Players = t2Snapshot.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();

      // Check if a lineup is already saved in the match doc
      final matchDoc = await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).get();
      final matchData = matchDoc.data();
      if (matchData != null) {
        if (matchData['team1Lineup'] != null) {
          for (var p in matchData['team1Lineup']) {
            team1Selection[p['id']] = p['status'];
          }
        }
        if (matchData['team2Lineup'] != null) {
          for (var p in matchData['team2Lineup']) {
            team2Selection[p['id']] = p['status'];
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading lineups: $e");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveLineup() async {
    // Validate that 11 starters are selected
    int t1Starters = team1Selection.values.where((v) => v == 'starter').length;
    int t2Starters = team2Selection.values.where((v) => v == 'starter').length;

    if (t1Starters != 11 || t2Starters != 11) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('يجب اختيار 11 لاعباً أساسياً لكل فريق! (الفريق الأول: $t1Starters، الفريق الثاني: $t2Starters)'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Build lineup lists
    List<Map<String, dynamic>> t1Lineup = [];
    for (var p in team1Players) {
      if (team1Selection[p['id']] != null) {
        t1Lineup.add({
          'id': p['id'],
          'name': p['name'],
          'number': p['number'],
          'status': team1Selection[p['id']],
        });
      }
    }

    List<Map<String, dynamic>> t2Lineup = [];
    for (var p in team2Players) {
      if (team2Selection[p['id']] != null) {
        t2Lineup.add({
          'id': p['id'],
          'name': p['name'],
          'number': p['number'],
          'status': team2Selection[p['id']],
        });
      }
    }

    await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
      'team1Lineup': t1Lineup,
      'team2Lineup': t2Lineup,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التشكيلة بنجاح!')));
      Navigator.pop(context);
    }
  }

  Widget _buildTeamTab(String teamName, List<Map<String, dynamic>> players, Map<String, String> selection) {
    if (players.isEmpty) {
      return Center(child: Text('لا يوجد لاعبين مسجلين في فريق $teamName'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'الأساسيون: ${selection.values.where((v) => v == 'starter').length}/11 | الاحتياط: ${selection.values.where((v) => v == 'sub').length}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final p = players[index];
              final String pId = p['id'];
              final status = selection[pId];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: status == 'starter' ? Colors.green.withOpacity(0.2) : (status == 'sub' ? Colors.orange.withOpacity(0.2) : null),
                child: ListTile(
                  leading: CircleAvatar(child: Text(p['number']?.toString() ?? '')),
                  title: Text(p['name'] ?? ''),
                  subtitle: Text('المركز: ${p['position'] ?? ''}'),
                  trailing: DropdownButton<String?>(
                    value: status,
                    hint: const Text('غير مستدعى'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('غير مستدعى')),
                      DropdownMenuItem(value: 'starter', child: Text('أساسي')),
                      DropdownMenuItem(value: 'sub', child: Text('احتياط')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        if (val == null) {
                          selection.remove(pId);
                        } else {
                          selection[pId] = val;
                        }
                      });
                    },
                  ),
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
    return AlertDialog(
      title: const Text('إعداد التشكيلة'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width < 600 ? double.maxFinite : 600,
        height: MediaQuery.of(context).size.width < 600 ? MediaQuery.of(context).size.height * 0.8 : 600,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: widget.team1),
                      Tab(text: widget.team2),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTeamTab(widget.team1, team1Players, team1Selection),
                        _buildTeamTab(widget.team2, team2Players, team2Selection),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: _isLoading ? null : _saveLineup,
          child: const Text('حفظ التشكيلة', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}