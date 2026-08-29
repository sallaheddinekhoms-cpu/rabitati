import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lineup_setup_dialog.dart';
import 'pdf_generator.dart';

class DelegateDashboard extends StatelessWidget {
  final String email;
  const DelegateDashboard({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الوكيل', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('matches').where('delegateEmail', isEqualTo: email).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('لا توجد مباريات مسندة إليك حالياً.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final match = docs[index].data() as Map<String, dynamic>;
              final matchId = docs[index].id;
              
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${match['team1']} ضد ${match['team2']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                          Chip(label: Text(match['status'] ?? 'لم تبدأ')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('القسم: ${match['league']} | الجولة: ${match['round']}'),
                      Text('النتيجة: ${match['score1']} - ${match['score2']}', style: const TextStyle(fontSize: 18, color: Colors.blue)),
                      if (match['refereeMain'] != null)
                         Padding(
                           padding: const EdgeInsets.only(top: 8),
                           child: Text('الحكام: ${match['refereeMain']} (ساحة) | ${match['refereeAss1']} (مساعد 1) | ${match['refereeAss2']} (مساعد 2)', style: const TextStyle(color: Colors.grey)),
                         ),
                      const Divider(),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              _openRefereesDialog(context, matchId, match);
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('طاقم التحكيم'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => LineupSetupDialog(
                                  matchId: matchId,
                                  team1: match['team1'],
                                  team2: match['team2'],
                                ),
                              );
                            },
                            icon: const Icon(Icons.people),
                            label: const Text('إعداد التشكيلة'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _openMatchController(context, matchId, match),
                            icon: const Icon(Icons.sports),
                            label: const Text('إدارة أحداث المباراة'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _openReportEditor(context, matchId, match['report'] ?? '', match['matchSheetUrl'] ?? ''),
                            icon: const Icon(Icons.edit_document),
                            label: const Text('تقرير المباراة'),
                          ),
                          ElevatedButton.icon(
  onPressed: () => PdfGenerator.generateAndPrintMatchSheet(match, matchId),
  icon: const Icon(Icons.picture_as_pdf),
  label: const Text('ورقة المباراة PDF'),
  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openRefereesDialog(BuildContext context, String matchId, Map<String, dynamic> matchData) {
    final ref1Ctrl = TextEditingController(text: matchData['refereeMain']);
    final ref2Ctrl = TextEditingController(text: matchData['refereeAss1']);
    final ref3Ctrl = TextEditingController(text: matchData['refereeAss2']);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إدارة طاقم التحكيم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: ref1Ctrl, decoration: const InputDecoration(labelText: 'حكم الساحة')),
            const SizedBox(height: 8),
            TextField(controller: ref2Ctrl, decoration: const InputDecoration(labelText: 'المساعد الأول')),
            const SizedBox(height: 8),
            TextField(controller: ref3Ctrl, decoration: const InputDecoration(labelText: 'المساعد الثاني')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('matches').doc(matchId).update({
                'refereeMain': ref1Ctrl.text,
                'refereeAss1': ref2Ctrl.text,
                'refereeAss2': ref3Ctrl.text,
              });
              Navigator.pop(ctx);
            },
            child: const Text('حفظ الحكام'),
          )
        ],
      )
    );
  }

  void _openMatchController(BuildContext context, String matchId, Map<String, dynamic> matchData) {
    showDialog(
      context: context,
      builder: (ctx) => MatchControllerDialog(matchId: matchId, matchData: matchData),
    );
  }

  void _openReportEditor(BuildContext context, String matchId, String existingReport, String existingSheetUrl) {
    final TextEditingController reportCtrl = TextEditingController(text: existingReport);
    final TextEditingController sheetCtrl = TextEditingController(text: existingSheetUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تحرير تقرير المباراة'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: sheetCtrl,
                decoration: const InputDecoration(
                  labelText: 'رابط صورة ورقة المباراة (Google Drive مثلا)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reportCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'اكتب تقريرك هنا (الأجواء، الإصابات، المشاكل التنظيمية...)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('matches').doc(matchId).update({
                'report': reportCtrl.text,
                'matchSheetUrl': sheetCtrl.text,
                'status': 'منتهية',
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: const Text('حفظ وإنهاء المباراة'),
          )
        ],
      ),
    );
  }
}

class MatchControllerDialog extends StatefulWidget {
  final String matchId;
  final Map<String, dynamic> matchData;
  const MatchControllerDialog({super.key, required this.matchId, required this.matchData});

  @override
  State<MatchControllerDialog> createState() => _MatchControllerDialogState();
}

class _MatchControllerDialogState extends State<MatchControllerDialog> {
  final TextEditingController _minuteCtrl = TextEditingController();
  String _selectedTeam = '';
  String _selectedType = 'هدف';
  String? _selectedPlayerId;
  String? _selectedPlayerName;

  String? _subOutPlayerId;
  String? _subOutPlayerName;
  String? _subInPlayerId;
  String? _subInPlayerName;

  Timer? _timer;
  int _currentMinute = 0;

  @override
  void initState() {
    super.initState();
    _selectedTeam = widget.matchData['team1'];
    _startClockIfMatchStarted();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startClockIfMatchStarted() {
    if (widget.matchData['startTime'] != null) {
      DateTime startTime = (widget.matchData['startTime'] as Timestamp).toDate();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _currentMinute = DateTime.now().difference(startTime).inMinutes;
          });
        }
      });
    }
  }

  void _startMatch() async {
    await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
      'startTime': FieldValue.serverTimestamp(),
      'status': 'مباشر',
    });
    setState(() {
      widget.matchData['startTime'] = Timestamp.now();
    });
    _startClockIfMatchStarted();
  }

  void _addEvent() async {
    String minuteToSave = _minuteCtrl.text.isEmpty ? _currentMinute.toString() : _minuteCtrl.text;

    if (_selectedType == 'تبديل') {
      if (_subOutPlayerId == null || _subInPlayerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار اللاعبين')));
        return;
      }
      
      await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').add({
        'type': 'تبديل',
        'team': _selectedTeam,
        'playerOut': _subOutPlayerName,
        'playerOutId': _subOutPlayerId,
        'playerIn': _subInPlayerName,
        'playerInId': _subInPlayerId,
        'minute': minuteToSave,
        'timestamp': FieldValue.serverTimestamp(),
      });

      List<dynamic> currentLineup = _selectedTeam == widget.matchData['team1'] 
          ? (widget.matchData['team1Lineup'] ?? [])
          : (widget.matchData['team2Lineup'] ?? []);
          
      for (var p in currentLineup) {
        if (p['id'] == _subOutPlayerId) p['status'] = 'sub';
        if (p['id'] == _subInPlayerId) p['status'] = 'starter';
      }

      await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
        _selectedTeam == widget.matchData['team1'] ? 'team1Lineup' : 'team2Lineup': currentLineup,
      });

      _subOutPlayerId = null;
      _subInPlayerId = null;
    } else {
      if (_selectedPlayerName == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار اللاعب')));
        return;
      }
      
      await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').add({
        'type': _selectedType,
        'team': _selectedTeam,
        'player': _selectedPlayerName,
        'playerId': _selectedPlayerId,
        'minute': minuteToSave,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (_selectedType == 'هدف') {
        bool isHome = _selectedTeam == widget.matchData['team1'];
        await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
          isHome ? 'score1' : 'score2': FieldValue.increment(1),
        });
        setState(() {
          if (isHome) {
            widget.matchData['score1'] = (widget.matchData['score1'] ?? 0) + 1;
          } else {
            widget.matchData['score2'] = (widget.matchData['score2'] ?? 0) + 1;
          }
        });
      }
      _selectedPlayerId = null;
      _selectedPlayerName = null;
    }

    _minuteCtrl.clear();
    setState(() {});
  }

  void _deleteEvent(String eventId, Map<String, dynamic> eventData) async {
    await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').doc(eventId).delete();
    
    // Undo logic
    if (eventData['type'] == 'هدف') {
      bool isHome = eventData['team'] == widget.matchData['team1'];
      await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
        isHome ? 'score1' : 'score2': FieldValue.increment(-1),
      });
      setState(() {
          if (isHome) {
            widget.matchData['score1'] = (widget.matchData['score1'] ?? 1) - 1;
          } else {
            widget.matchData['score2'] = (widget.matchData['score2'] ?? 1) - 1;
          }
      });
    } else if (eventData['type'] == 'تبديل') {
      List<dynamic> currentLineup = eventData['team'] == widget.matchData['team1'] 
          ? (widget.matchData['team1Lineup'] ?? [])
          : (widget.matchData['team2Lineup'] ?? []);
          
      for (var p in currentLineup) {
        if (p['id'] == eventData['playerOutId']) p['status'] = 'starter'; // undo out
        if (p['id'] == eventData['playerInId']) p['status'] = 'sub'; // undo in
      }

      await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
        eventData['team'] == widget.matchData['team1'] ? 'team1Lineup' : 'team2Lineup': currentLineup,
      });
      setState(() {});
    }
  }

  Widget _buildStadiumScoreboard(Map<String, dynamic> matchData, int minute) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.grey.shade900, Colors.black]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
      ),
      child: Column(
        children: [
          if (matchData['status'] == 'مباشر')
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 16),
                const SizedBox(width: 8),
                Text('مباشر - د $minute', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            )
          else 
            Text(matchData['status'] ?? 'لم تبدأ', style: const TextStyle(color: Colors.grey, fontSize: 18)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: Text(matchData['team1'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade800)),
                child: Text('${matchData['score1']} - ${matchData['score2']}', style: const TextStyle(color: Colors.yellowAccent, fontSize: 48, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ),
              Expanded(child: Text(matchData['team2'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> lineup = _selectedTeam == widget.matchData['team1'] 
        ? (widget.matchData['team1Lineup'] ?? [])
        : (widget.matchData['team2Lineup'] ?? []);

    List<dynamic> onFieldPlayers = lineup.where((p) => p['status'] == 'starter').toList();
    List<dynamic> benchedPlayers = lineup.where((p) => p['status'] == 'sub').toList();
    
    bool isMobile = MediaQuery.of(context).size.width < 800;

    Widget leftTimeline = Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      height: isMobile ? 300 : null,
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(12), color: Colors.grey.shade100, width: double.infinity, child: const Text('شريط الأحداث', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final events = snapshot.data!.docs;
                if (events.isEmpty) return const Center(child: Text('لا توجد أحداث بعد'));
                
                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    var evt = events[index].data() as Map<String, dynamic>;
                    String icon = '⚽';
                    if (evt['type'] == 'بطاقة صفراء') icon = '🟨';
                    if (evt['type'] == 'بطاقة حمراء') icon = '🟥';
                    if (evt['type'] == 'تبديل') icon = '🔄';

                    return ListTile(
                      leading: Text('د${evt['minute']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      title: Text('$icon ${evt['team']}'),
                      subtitle: Text(evt['type'] == 'تبديل' ? 'خروج: ${evt['playerOut']} \nدخول: ${evt['playerIn']}' : '${evt['player']} - ${evt['type']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () => _deleteEvent(events[index].id, evt),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );

    Widget rightForm = Column(
      children: [
        if (lineup.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.red.shade100,
            child: const Text('⚠️ لم يتم إعداد التشكيلة لهذا الفريق.', style: TextStyle(color: Colors.red)),
          ),
        Row(
          children: [
            Expanded(child: RadioListTile<String>(title: Text(widget.matchData['team1']), value: widget.matchData['team1'], groupValue: _selectedTeam, onChanged: (v) => setState(() { _selectedTeam = v!; _selectedPlayerId = null; _selectedPlayerName = null; }))),
            Expanded(child: RadioListTile<String>(title: Text(widget.matchData['team2']), value: widget.matchData['team2'], groupValue: _selectedTeam, onChanged: (v) => setState(() { _selectedTeam = v!; _selectedPlayerId = null; _selectedPlayerName = null; }))),
          ],
        ),
        DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          items: ['هدف', 'بطاقة صفراء', 'بطاقة حمراء', 'تبديل'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _selectedType = v!),
        ),
        const SizedBox(height: 16),
        if (_selectedType != 'تبديل')
          DropdownButtonFormField<String>(
            value: _selectedPlayerId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'اللاعب (المتواجدون في الملعب)', border: OutlineInputBorder()),
            items: onFieldPlayers.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text('${p['number']} - ${p['name']}', overflow: TextOverflow.ellipsis))).toList(),
            onChanged: lineup.isEmpty ? null : (val) {
              setState(() {
                _selectedPlayerId = val;
                _selectedPlayerName = onFieldPlayers.firstWhere((p) => p['id'] == val)['name'];
              });
            },
          ),
        if (_selectedType == 'تبديل')
          Column(
            children: [
              DropdownButtonFormField<String>(
                value: _subOutPlayerId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'اللاعب الخارج ⬇️', border: OutlineInputBorder(), fillColor: Colors.redAccent),
                items: onFieldPlayers.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text('${p['number']} - ${p['name']}'))).toList(),
                onChanged: lineup.isEmpty ? null : (val) {
                  setState(() {
                    _subOutPlayerId = val;
                    _subOutPlayerName = onFieldPlayers.firstWhere((p) => p['id'] == val)['name'];
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _subInPlayerId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'اللاعب الداخل ⬆️', border: OutlineInputBorder(), fillColor: Colors.greenAccent),
                items: benchedPlayers.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text('${p['number']} - ${p['name']}'))).toList(),
                onChanged: lineup.isEmpty ? null : (val) {
                  setState(() {
                    _subInPlayerId = val;
                    _subInPlayerName = benchedPlayers.firstWhere((p) => p['id'] == val)['name'];
                  });
                },
              ),
            ],
          ),
        const SizedBox(height: 16),
        TextField(controller: _minuteCtrl, decoration: InputDecoration(labelText: 'الدقيقة (فارغ = د $_currentMinute)', border: const OutlineInputBorder()), keyboardType: TextInputType.number),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: lineup.isEmpty ? null : _addEvent, 
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blue), 
          child: const Text('إضافة الحدث', style: TextStyle(color: Colors.white, fontSize: 16))
        ),
      ],
    );

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(child: Text('إدارة الأحداث', style: TextStyle(fontSize: 18))),
          if (widget.matchData['startTime'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
              child: Text('$_currentMinute:00', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            )
          else
            ElevatedButton(onPressed: _startMatch, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('انطلاق!', style: TextStyle(color: Colors.white))),
        ],
      ),
      content: SizedBox(
        width: isMobile ? double.maxFinite : 900,
        height: isMobile ? null : 600,
        child: isMobile
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    _buildStadiumScoreboard(widget.matchData, _currentMinute),
                    rightForm,
                    const SizedBox(height: 24),
                    leftTimeline,
                  ],
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: Column(children: [_buildStadiumScoreboard(widget.matchData, _currentMinute), Expanded(child: leftTimeline)])),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: SingleChildScrollView(child: rightForm)),
                ],
              ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
    );
  }
}