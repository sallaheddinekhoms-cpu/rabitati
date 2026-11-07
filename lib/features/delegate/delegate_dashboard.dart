import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/network/api_client.dart';
import 'lineup_setup_dialog.dart';
import 'pdf_generator.dart';
import 'delegate_report_dialog.dart';
import 'delegate_report_pdf.dart';
import 'mission_order_pdf.dart';
import 'widgets/jersey_player_picker.dart';

class DelegateDashboard extends StatefulWidget {
  final String email;
  const DelegateDashboard({super.key, required this.email});

  @override
  State<DelegateDashboard> createState() => _DelegateDashboardState();
}

class _DelegateDashboardState extends State<DelegateDashboard> {
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  Timer? _pollingTimer;
  int _selectedTab = 0; // 0: المقابلة الحالية / النشطة, 1: سجل المباريات Historique

  bool _isMatchFinished(Map<String, dynamic> match) {
    final statusStr = (match['status'] ?? '').toString().trim().toLowerCase();
    final stageStr = (match['match_stage'] ?? '').toString().trim().toLowerCase();
    return statusStr == 'منتهية' ||
        statusStr == 'finished' ||
        statusStr == 'ملغاة' ||
        statusStr == 'cancelled' ||
        stageStr == 'نهاية المباراة' ||
        stageStr == 'منتهية';
  }

  List<Map<String, dynamic>> get _activeMatches =>
      _matches.where((m) => !_isMatchFinished(m)).toList();

  List<Map<String, dynamic>> get _historyMatches =>
      _matches.where((m) => _isMatchFinished(m)).toList();

  @override
  void initState() {
    super.initState();
    _loadMatches();
    _pollingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) _loadMatches(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMatches({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // 1. Fetch from Laravel REST API
      final apiMatches = await ApiClient().getDelegateMatches(email: widget.email);
      if (apiMatches.isNotEmpty) {
        if (mounted) {
          setState(() {
            _matches = apiMatches;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    // 2. Fallback to Firestore if REST API returned 0 or failed
    try {
      final snap = await FirebaseFirestore.instance.collection('matches').get();
      final normalizedEmail = widget.email.trim().toLowerCase();
      final docs = snap.docs.where((doc) {
        final m = doc.data();
        final dEmail = (m['delegateEmail'] ?? '').toString().trim().toLowerCase();
        final dId = (m['delegateId'] ?? '').toString().trim().toLowerCase();
        return dEmail == normalizedEmail || dId == normalizedEmail;
      }).map((doc) {
        final m = doc.data();
        m['id'] = doc.id;
        return m;
      }).toList();

      if (docs.isNotEmpty && mounted) {
        setState(() {
          _matches = docs;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await ApiClient().clearToken();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('بوابة محافظي ومندوبي المباريات', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              Text('الرابطة الجهوية لكرة القدم البليدة - LRF Blida', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
          backgroundColor: const Color(0xFF0F261B),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'تحديث المباريات',
              onPressed: () => _loadMatches(),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'تسجيل الخروج',
              onPressed: _logout,
            )
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => _loadMatches(),
          child: _isLoading && _matches.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B7A36)))
              : _matches.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد مباريات مسندة إلى حسابك حالياً.',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'حسابك: ${widget.email}\nعند تعيينك في أي لقاء في لوحة التحكم ستظهر تفاصيله وأدوات إدارته هنا فوراً.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _loadMatches(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('إعادة فحص التعيينات الآن'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        _buildTopHeader(),
                        Expanded(
                          child: _buildCurrentTabList(),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  // ── شريط رأس لوحة المحافظين وقائمة التبديل (المباراة الحالية vs السجل) ──
  Widget _buildTopHeader() {
    final activeCount = _activeMatches.length;
    final historyCount = _historyMatches.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F261B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // شريط معلومات المحافظ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.email,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'محافظ معتمد • لوحة التحكم والمتابعة الميدانية',
                        style: TextStyle(color: Colors.white70, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: Color(0xFF4ADE80), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${_matches.length} مسندة',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // مفتاح التبديل بين المقابلة الحالية وسجل المباريات (Historique)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                // زر: المقابلة الحالية
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 0),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? const Color(0xFF16A34A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedTab == 0
                            ? [BoxShadow(color: const Color(0xFF16A34A).withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_soccer, size: 16, color: _selectedTab == 0 ? Colors.white : Colors.white60),
                          const SizedBox(width: 6),
                          Text(
                            'المقابلة الحالية ($activeCount)',
                            style: TextStyle(
                              color: _selectedTab == 0 ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // زر: سجل المباريات (Historique)
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 1),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? const Color(0xFF1E3A8A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedTab == 1
                            ? [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_edu, size: 16, color: _selectedTab == 1 ? Colors.white : Colors.white60),
                          const SizedBox(width: 6),
                          Text(
                            'السجل Historique ($historyCount)',
                            style: TextStyle(
                              color: _selectedTab == 1 ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── قائمة المباريات للتبويب المختار ──
  Widget _buildCurrentTabList() {
    final list = _selectedTab == 0 ? _activeMatches : _historyMatches;

    if (list.isEmpty) {
      if (_selectedTab == 0) {
        return Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.task_alt, size: 54, color: Color(0xFF16A34A)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد مقابلة معينة قيد الانتظار حالياً',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F261B)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'تم استكمال وأرشفة كافة مبارياتك السابقة بنجاح، ويمكنك مراجعتها واستخراج تقاريرها من قسم السجل.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Colors.blueGrey),
                ),
                if (_historyMatches.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedTab = 1),
                    icon: const Icon(Icons.history_edu, size: 18),
                    label: Text('عرض سجل المباريات السابقة (${_historyMatches.length}) 📜'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      } else {
        return Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.history, size: 54, color: Colors.blue.shade700),
                ),
                const SizedBox(height: 16),
                const Text(
                  'سجل الأرشيف فارغ حالياً',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F261B)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'ستنتقل المباريات تلقائياً إلى هذا السجل بعد إدارتها وإنهائها واعتماد التقرير.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
        );
      }
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _buildMatchCard(context, list[index], isHistoryTab: _selectedTab == 1);
      },
    );
  }

  // ── بطاقة المباراة الاحترافية ──
  Widget _buildMatchCard(BuildContext context, Map<String, dynamic> match, {required bool isHistoryTab}) {
    final matchId = (match['id'] ?? '').toString();
    final statusStr = (match['status'] ?? 'لم تبدأ').toString();
    final stageStr = (match['match_stage'] ?? '').toString();
    final bool isLive = statusStr == 'جارية' || statusStr.contains('الشوط') || statusStr == 'live';
    final bool isFinished = _isMatchFinished(match);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLive
              ? Colors.red.shade400
              : (isHistoryTab ? Colors.blueGrey.shade100 : Colors.grey.shade200),
          width: isLive ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive ? Colors.red.withOpacity(0.08) : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── رأس البطاقة: البطولة، الجولة، شارة الحالة ────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isLive
                  ? Colors.red.shade50
                  : (isHistoryTab ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isHistoryTab ? Icons.archive : Icons.emoji_events,
                      size: 16,
                      color: isHistoryTab ? const Color(0xFF1E3A8A) : const Color(0xFF1B5E20),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${match['league'] ?? 'بطولة جهوية'} • ${match['round'] ?? 'لقاء رسمي'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F261B)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLive
                        ? Colors.red.shade600
                        : (isFinished ? const Color(0xFF10B981) : Colors.amber.shade700),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLive) ...[
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        isLive ? '🔴 مباشر الآن' : (isFinished ? '✅ منتهية ومؤرشفة' : '⏱️ لم تبدأ بعد'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── وسط البطاقة: أسماء الفريقين والنتيجة والملعب ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    // الفريق المضيف
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 1.5),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: ClipOval(
                              child: match['logo1'] != null && match['logo1'].toString().isNotEmpty
                                  ? Image.network(
                                      match['logo1'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.shield, color: Color(0xFF1B5E20), size: 26),
                                    )
                                  : const Icon(Icons.shield, color: Color(0xFF1B5E20), size: 26),
                            ),
                          ),
                          Text(
                            match['team1'] ?? 'المضيف',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    // مربع النتيجة الرقمي
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 6, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (isFinished || isLive || (match['score1'] != '-' && match['score1'] != null && match['score1'].toString().isNotEmpty))
                                ? '${match['score1'] ?? 0} - ${match['score2'] ?? 0}'
                                : (match['time'] ?? 'VS'),
                            style: TextStyle(
                              color: isLive ? Colors.redAccent : (isFinished ? const Color(0xFF4ADE80) : Colors.yellowAccent),
                              fontWeight: FontWeight.bold,
                              fontSize: (isFinished || isLive || (match['score1'] != '-' && match['score1'] != null && match['score1'].toString().isNotEmpty)) ? 22 : 16,
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (isLive && stageStr.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                stageStr,
                                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            )
                          else if (!isFinished && !isLive && (match['score1'] == '-' || match['score1'] == null || match['score1'].toString().isEmpty))
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text('VS', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),

                    // الفريق الضيف
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 1.5),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: ClipOval(
                              child: match['logo2'] != null && match['logo2'].toString().isNotEmpty
                                  ? Image.network(
                                      match['logo2'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.shield, color: Color(0xFF0F766E), size: 26),
                                    )
                                  : const Icon(Icons.shield, color: Color(0xFF0F766E), size: 26),
                            ),
                          ),
                          Text(
                            match['team2'] ?? 'الضيف',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // الملعب والتوقيت
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stadium, size: 14, color: Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Text(
                        match['stadium'] ?? 'الملعب البلدي',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                      ),
                      if (match['date'] != null) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text(
                          match['date'].toString(),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── شارة المحافظ وحالة التقرير ─────────────────
          if ((match['delegateName'] != null && match['delegateName'].toString().isNotEmpty) || match['reportSubmitted'] == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              child: Row(
                children: [
                  if (match['delegateName'] != null && match['delegateName'].toString().isNotEmpty)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.badge, size: 14, color: Color(0xFF0F766E)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'المحافظ: ${match['delegateName']}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (match['reportSubmitted'] == true) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 13, color: Colors.green),
                          SizedBox(width: 4),
                          Text('تم رفع التقرير', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // ── طاقم التحكيم ───────────────────────────────
          if (match['refereeMain'] != null && match['refereeMain'].toString().isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'التحكيم: ${match['refereeMain']} (ساحة) | ${match['refereeAss1'] ?? ''} | ${match['refereeAss2'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // ── أزرار العمليات (مخصصة للمباراة الحالية vs السجل) ─────
          if (!isHistoryTab) ...[
            // زر البداية المباشرة (إذا لم تنطلق)
            if (!isLive && !isFinished)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
                child: ElevatedButton.icon(
                  onPressed: () => _startMatchDirectlyFromCard(context, matchId, match),
                  icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 22),
                  label: const Text(
                    'صافرة بداية المقابلة مباشرة (0 - 0) 🏁',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

            // أزرار الميدان والبث والتشكيلة
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: ElevatedButton.icon(
                      onPressed: () => _openMatchController(context, matchId, match),
                      icon: const Icon(Icons.bolt, size: 18),
                      label: const Text('إدارة البث والأحداث', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => LineupSetupDialog(
                            matchId: matchId,
                            team1: match['team1'] ?? '',
                            team2: match['team2'] ?? '',
                          ),
                        );
                      },
                      icon: const Icon(Icons.groups, size: 18),
                      label: const Text('إعداد التشكيلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // أزرار الوثائق والتقارير
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openReportEditor(context, matchId, match),
                    icon: const Icon(Icons.assignment, size: 16),
                    label: Text(match['reportSubmitted'] == true ? 'تعديل التقرير' : 'تقرير اللقاء', style: const TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1B5E20),
                      side: const BorderSide(color: Color(0xFF1B5E20)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => MissionOrderPdfGenerator.generateAndPrint(match, matchId),
                    icon: const Icon(Icons.description, size: 16),
                    label: const Text('أمر بمهمة PDF', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E3A8A),
                      side: const BorderSide(color: Color(0xFF1E3A8A)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => PdfGenerator.generateAndPrintMatchSheet(match, matchId),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('ورقة اللقاء PDF', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueGrey.shade700,
                      side: BorderSide(color: Colors.blueGrey.shade400),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openRefereesDialog(context, matchId, match),
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('الحكام', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple.shade700,
                      side: BorderSide(color: Colors.purple.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  if (match['reportSubmitted'] == true || match['delegateReport'] != null)
                    OutlinedButton.icon(
                      onPressed: () => DelegateReportPdfGenerator.generateAndPrint(
                        match,
                        (match['delegateReport'] as Map<String, dynamic>?) ?? {},
                        matchId,
                      ),
                      icon: const Icon(Icons.verified, size: 16, color: Colors.green),
                      label: const Text('تقرير معتمد PDF', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _openAccreditedJournalistsDialog(context, matchId, match),
                    icon: const Icon(Icons.badge, size: 16),
                    label: const Text('الصحفيون', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      side: const BorderSide(color: Color(0xFF0F766E)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // ── أزرار مخصصة لسجل المقابلات (Historique) ─────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => PdfGenerator.generateAndPrintMatchSheet(match, matchId),
                      icon: const Icon(Icons.picture_as_pdf, size: 17),
                      label: const Text('ورقة اللقاء الرسمية PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (match['reportSubmitted'] == true || match['delegateReport'] != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => DelegateReportPdfGenerator.generateAndPrint(
                          match,
                          (match['delegateReport'] as Map<String, dynamic>?) ?? {},
                          matchId,
                        ),
                        icon: const Icon(Icons.verified, size: 17),
                        label: const Text('تقرير المحافظ PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openReportEditor(context, matchId, match),
                    icon: const Icon(Icons.assignment, size: 15),
                    label: const Text('مراجعة وتعديل التقرير', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      side: const BorderSide(color: Color(0xFF0F766E)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => MissionOrderPdfGenerator.generateAndPrint(match, matchId),
                    icon: const Icon(Icons.description, size: 15),
                    label: const Text('أمر بمهمة PDF', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueGrey.shade700,
                      side: BorderSide(color: Colors.blueGrey.shade400),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openRefereesDialog(context, matchId, match),
                    icon: const Icon(Icons.sports, size: 15),
                    label: const Text('طاقم التحكيم', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple.shade700,
                      side: BorderSide(color: Colors.purple.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openAccreditedJournalistsDialog(context, matchId, match),
                    icon: const Icon(Icons.badge, size: 15),
                    label: const Text('الصحفيون', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal.shade700,
                      side: BorderSide(color: Colors.teal.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }


    void _openAccreditedJournalistsDialog(BuildContext context, String matchId, Map<String, dynamic> matchData) {
    List<Map<String, dynamic>> apiJournalists = [];
    if (matchData['accredited_journalists'] is List) {
      apiJournalists = (matchData['accredited_journalists'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.badge, color: Color(0xFF0F766E)),
            SizedBox(width: 8),
            Text('الصحفيون المعتمدون للمباراة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${matchData['team1']} ضد ${matchData['team2']} (${matchData['league'] ?? ''})',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 340,
                child: apiJournalists.isNotEmpty
                    ? _buildJournalistsListView(apiJournalists)
                    : FutureBuilder<List<Map<String, dynamic>>>(
                        future: ApiClient().getMatchAccreditations(matchId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final list = snapshot.data ?? [];
                          if (list.isNotEmpty) {
                            return _buildJournalistsListView(list);
                          }
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('media_accreditations')
                                .where('matchId', isEqualTo: matchId)
                                .where('status', isEqualTo: 'approved')
                                .snapshots(),
                            builder: (context, fireSnap) {
                              if (fireSnap.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final docs = fireSnap.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.person_off, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('لم يتم اعتماد أي صحفي لهذه المباراة بعد.', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                );
                              }
                              final fireList = docs.map((d) => Map<String, dynamic>.from(d.data() as Map)).toList();
                              return _buildJournalistsListView(fireList);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  Widget _buildJournalistsListView(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.person_off, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('لم يتم اعتماد أي صحفي لهذه المباراة بعد.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final data = list[index];
        final name = (data['journalistName'] ?? data['journalist_name'] ?? '').toString();
        final outlet = (data['mediaOutlet'] ?? data['media_outlet'] ?? '').toString();
        final type = (data['mediaType'] ?? data['media_type'] ?? '').toString();
        final card = (data['pressCardNumber'] ?? data['press_card_number'] ?? '').toString();
        final phone = (data['phone'] ?? '').toString();
        final photo = (data['photoUrl'] ?? data['photoBase64'] ?? data['photo_path'] ?? '').toString();

        Widget avatar = const CircleAvatar(
          backgroundColor: Color(0xFF0F766E),
          child: Icon(Icons.person, color: Colors.white),
        );

        if (photo.isNotEmpty) {
          try {
            if (photo.startsWith('data:image')) {
              final raw = photo.split(',').last;
              avatar = CircleAvatar(
                backgroundImage: MemoryImage(base64Decode(raw)),
              );
            } else if (photo.startsWith('http')) {
              avatar = CircleAvatar(
                backgroundImage: NetworkImage(photo),
              );
            } else if (photo.startsWith('/9j/') || photo.length > 100) {
              avatar = CircleAvatar(
                backgroundImage: MemoryImage(base64Decode(photo)),
              );
            }
          } catch (_) {}
        }

        return ListTile(
          leading: avatar,
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$outlet - $type', style: const TextStyle(fontSize: 12)),
              if (card.isNotEmpty || phone.isNotEmpty)
                Text('بطاقة الصحافة: $card | هاتف: $phone', style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: const Text('معتمد ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        );
      },
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
            onPressed: () async {
              try {
                await ApiClient().updateMatchStatus(matchId, {
                  'referee_main': ref1Ctrl.text.trim(),
                  'referee_ass1': ref2Ctrl.text.trim(),
                  'referee_ass2': ref3Ctrl.text.trim(),
                });
              } catch (_) {}
              try {
                FirebaseFirestore.instance.collection('matches').doc(matchId).update({
                  'refereeMain': ref1Ctrl.text.trim(),
                  'refereeAss1': ref2Ctrl.text.trim(),
                  'refereeAss2': ref3Ctrl.text.trim(),
                });
              } catch (_) {}
              if (ctx.mounted) Navigator.pop(ctx);
              _loadMatches(silent: true);
            },
            child: const Text('حفظ الحكام'),
          )
        ],
      )
    );
  }

  Future<void> _startMatchDirectlyFromCard(BuildContext context, String matchId, Map<String, dynamic> matchData) async {
    final t1 = matchData['team1'] ?? 'المستضيف';
    final t2 = matchData['team2'] ?? 'الضيف';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.sports, color: Color(0xFF1B5E20), size: 26),
            SizedBox(width: 10),
            Text('صافرة بداية المقابلة 🏁', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل تريد إطلاق صافرة بداية الشوط الأول لمباراة:\n$t1 ضد $t2؟',
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('• يبدأ العداد المباشر (Chronomètre) فوراً.', style: TextStyle(fontSize: 12, color: Color(0xFF166534))),
                  SizedBox(height: 3),
                  Text('• تثبيت النتيجة المبدئية (0 - 0) في التطبيق والموقع الرسمي.', style: TextStyle(fontSize: 12, color: Color(0xFF166534))),
                  SizedBox(height: 3),
                  Text('• فتح لوحة إدارة الأحداث والبث مباشرة لمتابعة اللقاء.', style: TextStyle(fontSize: 12, color: Color(0xFF166534))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            label: const Text('تأكيد صافرة البداية (0 - 0)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Execute start with guaranteed auth & immediate Firestore persistence
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (_) {}
    }

    try {
      await FirebaseFirestore.instance.collection('matches').doc(matchId).set({
        'matchStage': 'first_half',
        'status': 'الشوط الأول',
        'score1': 0,
        'score2': 0,
        'firstHalfStartTime': FieldValue.serverTimestamp(),
        'startTime': FieldValue.serverTimestamp(),
        'addedTime1': 0,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore startMatch error: $e');
    }

    unawaited(ApiClient().updateMatchStatus(matchId, {
      'status': 'live',
      'match_stage': 'first_half',
      'home_score': 0,
      'away_score': 0,
      'added_time1': 0,
      'first_half_start_at': DateTime.now().toIso8601String(),
    }).timeout(const Duration(seconds: 3)).catchError((_) => false));

    matchData['matchStage'] = 'first_half';
    matchData['status'] = 'الشوط الأول';
    matchData['score1'] = '0';
    matchData['score2'] = '0';
    matchData['firstHalfStartTime'] = DateTime.now().toIso8601String();
    _loadMatches(silent: true);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🏁 انطلقت المباراة بنجاح! النتيجة الآن (0 - 0) والمباراة في الشوط الأول.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      _openMatchController(context, matchId, matchData);
    }
  }

  void _openMatchController(BuildContext context, String matchId, Map<String, dynamic> matchData) {
    showDialog(
      context: context,
      builder: (ctx) => MatchControllerDialog(matchId: matchId, matchData: matchData),
    );
  }

  void _openReportEditor(BuildContext context, String matchId, Map<String, dynamic> matchData) {
    showDialog(
      context: context,
      builder: (ctx) => DelegateReportDialog(matchId: matchId, matchData: matchData),
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
  final TextEditingController _manualPlayerCtrl = TextEditingController();
  final TextEditingController _manualSubOutCtrl = TextEditingController();
  final TextEditingController _manualSubInCtrl = TextEditingController();
  late Map<String, dynamic> _localData;
  String _selectedTeam = '';
  String _selectedType = 'هدف';
  String? _selectedPlayerId;
  String? _selectedPlayerName;

  String? _subOutPlayerId;
  String? _subOutPlayerName;
  String? _subInPlayerId;
  String? _subInPlayerName;

  List<Map<String, dynamic>> _team1DbPlayers = [];
  List<Map<String, dynamic>> _team2DbPlayers = [];
  bool _isLoadingDbPlayers = false;
  bool _isSubmittingEvent = false;
  DateTime? _lastSubmitTime;
  String? _lastEventSignature;

  Timer? _liveTicker;

  @override
  void initState() {
    super.initState();
    _localData = Map<String, dynamic>.from(widget.matchData);
    _selectedTeam = widget.matchData['team1'] ?? '';
    _loadSquadPlayersFromDatabase();
    // Periodic ticker to keep the displayed minutes & seconds updated every second
    _liveTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadSquadPlayersFromDatabase() async {
    if (mounted) setState(() => _isLoadingDbPlayers = true);
    final t1Name = (widget.matchData['team1'] ?? '').toString().trim();
    final t2Name = (widget.matchData['team2'] ?? '').toString().trim();

    try {
      final clubs = await ApiClient().getClubs();
      final c1 = clubs.firstWhere(
        (c) => (c['name'] ?? '').toString().trim() == t1Name || (c['short_name'] ?? '').toString().trim() == t1Name,
        orElse: () => {},
      );
      final c2 = clubs.firstWhere(
        (c) => (c['name'] ?? '').toString().trim() == t2Name || (c['short_name'] ?? '').toString().trim() == t2Name,
        orElse: () => {},
      );

      if (c1['id'] != null) {
        final p1 = await ApiClient().getClubPlayers(c1['id'].toString());
        _team1DbPlayers = p1.map((p) => Map<String, dynamic>.from(p)).toList();
      }
      if (c2['id'] != null) {
        final p2 = await ApiClient().getClubPlayers(c2['id'].toString());
        _team2DbPlayers = p2.map((p) => Map<String, dynamic>.from(p)).toList();
      }
    } catch (_) {}

    // Fallback to Firestore if API had no players
    if (_team1DbPlayers.isEmpty || _team2DbPlayers.isEmpty) {
      try {
        if (_team1DbPlayers.isEmpty && t1Name.isNotEmpty) {
          final snap1 = await FirebaseFirestore.instance.collection('players').where('clubName', isEqualTo: t1Name).get();
          _team1DbPlayers = snap1.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        }
        if (_team2DbPlayers.isEmpty && t2Name.isNotEmpty) {
          final snap2 = await FirebaseFirestore.instance.collection('players').where('clubName', isEqualTo: t2Name).get();
          _team2DbPlayers = snap2.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _isLoadingDbPlayers = false);
  }

  @override
  void dispose() {
    _liveTicker?.cancel();
    _minuteCtrl.dispose();
    _manualPlayerCtrl.dispose();
    _manualSubOutCtrl.dispose();
    _manualSubInCtrl.dispose();
    super.dispose();
  }

  int _computeCurrentMinute(Map<String, dynamic> data) {
    final stage = _resolveStage(data);
    if (stage == 'first_half') {
      dynamic st = data['firstHalfStartTime'] ?? data['startTime'] ?? data['first_half_start_at'];
      DateTime? dt;
      if (st is Timestamp) dt = st.toDate();
      else if (st is String) dt = DateTime.tryParse(st);
      else if (st is DateTime) dt = st;

      if (dt != null) {
        int diff = DateTime.now().difference(dt).inMinutes + 1;
        return diff < 1 ? 1 : diff;
      }
      final timingStr = (data['timing_display'] ?? data['timing_text'] ?? '').toString();
      final m = RegExp(r'(\d+)').firstMatch(timingStr);
      if (m != null) return int.tryParse(m.group(1)!) ?? 1;
      return 1;
    } else if (stage == 'half_time') {
      return 45;
    } else if (stage == 'second_half') {
      dynamic st2 = data['secondHalfStartTime'] ?? data['second_half_start_at'];
      DateTime? dt2;
      if (st2 is Timestamp) dt2 = st2.toDate();
      else if (st2 is String) dt2 = DateTime.tryParse(st2);
      else if (st2 is DateTime) dt2 = st2;

      if (dt2 != null) {
        int diff = 45 + DateTime.now().difference(dt2).inMinutes + 1;
        return diff < 46 ? 46 : diff;
      }
      final timingStr = (data['timing_display'] ?? data['timing_text'] ?? '').toString();
      final m = RegExp(r'(\d+)').firstMatch(timingStr);
      if (m != null) return int.tryParse(m.group(1)!) ?? 46;
      return 46;
    } else if (stage == 'finished') {
      return 90;
    }
    return 0;
  }

  String _resolveStage(Map<String, dynamic> data) {
    if (data['matchStage'] != null && data['matchStage'].toString().isNotEmpty) {
      return data['matchStage'];
    }
    final status = data['status'] ?? '';
    if (status == 'الشوط الأول' || status == 'مباشر') return 'first_half';
    if (status == 'استراحة بين الشوطين' || status == 'استراحة') return 'half_time';
    if (status == 'الشوط الثاني') return 'second_half';
    if (status == 'منتهية' || status == 'انتهت') return 'finished';
    return 'not_started';
  }

  int _computeElapsedSeconds(Map<String, dynamic> data) {
    final stage = _resolveStage(data);
    if (stage == 'first_half') {
      dynamic st = data['firstHalfStartTime'] ?? data['startTime'] ?? data['first_half_start_at'] ?? data['half1_start_time'];
      DateTime? dt;
      if (st is Timestamp) dt = st.toDate();
      else if (st is String) dt = DateTime.tryParse(st);
      else if (st is DateTime) dt = st;

      if (dt != null) {
        final diff = DateTime.now().difference(dt).inSeconds;
        return diff < 0 ? 0 : diff;
      }
      return 0;
    } else if (stage == 'second_half') {
      dynamic st2 = data['secondHalfStartTime'] ?? data['second_half_start_at'] ?? data['half2_start_time'];
      DateTime? dt2;
      if (st2 is Timestamp) dt2 = st2.toDate();
      else if (st2 is String) dt2 = DateTime.tryParse(st2);
      else if (st2 is DateTime) dt2 = st2;

      if (dt2 != null) {
        final diff = DateTime.now().difference(dt2).inSeconds;
        return 2700 + (diff < 0 ? 0 : diff);
      }
      return 2700;
    }
    return 0;
  }

  String _formatDisplayMinute(Map<String, dynamic> data) {
    final stage = _resolveStage(data);
    if (stage == 'not_started') return 'لم تبدأ بعد';
    if (stage == 'half_time') return 'استراحة 45:00';
    if (stage == 'finished') return 'منتهية • FT';

    final totalSec = _computeElapsedSeconds(data);
    if (stage == 'first_half') {
      if (totalSec <= 2700) {
        final m = (totalSec ~/ 60).toString().padLeft(2, '0');
        final s = (totalSec % 60).toString().padLeft(2, '0');
        return '$m:$s';
      } else {
        final extra = totalSec - 2700;
        final em = (extra ~/ 60).toString().padLeft(2, '0');
        final es = (extra % 60).toString().padLeft(2, '0');
        return '45:00 +$em:$es';
      }
    }

    if (stage == 'second_half') {
      if (totalSec <= 5400) {
        final m = (totalSec ~/ 60).toString().padLeft(2, '0');
        final s = (totalSec % 60).toString().padLeft(2, '0');
        return '$m:$s';
      } else {
        final extra = totalSec - 5400;
        final em = (extra ~/ 60).toString().padLeft(2, '0');
        final es = (extra % 60).toString().padLeft(2, '0');
        return '90:00 +$em:$es';
      }
    }
    return '';
  }

  String _getDefaultEventMinute(Map<String, dynamic> data) {
    final stage = _resolveStage(data);
    int m = _computeCurrentMinute(data);
    if (stage == 'first_half' && m > 45) return "45+${m - 45}";
    if (stage == 'second_half' && m > 90) return "90+${m - 90}";
    if (stage == 'half_time') return "45";
    return m > 0 ? m.toString() : "1";
  }

  // ── الصافرات والأطوار ─────────────────────────────────────────────
  Future<void> _startFirstHalf() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.sports, color: Color(0xFF1B5E20)),
            SizedBox(width: 8),
            Text('صافرة بداية المباراة 🏁', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text(
          'هل أطلق حكم اللقاء صافرة بداية الشوط الأول رسمياً؟\n\n'
          '• سيبدأ عداد المباراة من الدقيقة الأولى.\n'
          '• سيتم تثبيت النتيجة المبدئية (0 - 0) فوراً في التطبيق والموقع الرسمي.\n'
          '• سيتحول طور المباراة إلى "مباشر" لدى جميع المتابعين.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.play_arrow),
            label: const Text('تأكيد الانطلاق (0 - 0)'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _localData['matchStage'] = 'first_half';
      _localData['status'] = 'الشوط الأول';
      _localData['score1'] = '0';
      _localData['score2'] = '0';
      _localData['addedTime1'] = 0;
      _localData['firstHalfStartTime'] = DateTime.now().toIso8601String();
    });

    if (FirebaseAuth.instance.currentUser == null) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
      } catch (_) {}
    }

    widget.matchData.addAll(_localData);

    try {
      await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).set({
        'matchStage': 'first_half',
        'status': 'الشوط الأول',
        'score1': 0,
        'score2': 0,
        'firstHalfStartTime': FieldValue.serverTimestamp(),
        'startTime': FieldValue.serverTimestamp(),
        'addedTime1': 0,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore _startFirstHalf error: $e');
    }

    unawaited(ApiClient().updateMatchStatus(widget.matchId, {
      'status': 'live',
      'match_stage': 'first_half',
      'home_score': 0,
      'away_score': 0,
      'added_time1': 0,
      'first_half_start_at': DateTime.now().toIso8601String(),
    }).timeout(const Duration(seconds: 3)).catchError((_) => false));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🏁 انطلقت المباراة! تم تسجيل صافرة بداية الشوط الأول بنتيجة (0 - 0).'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _endFirstHalf() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('صافرة نهاية الشوط الأول ⏸️'),
        content: const Text('هل أطلق حكم اللقاء صافرة نهاية الشوط الأول؟\nسيتم تثبيت العداد وتغيير الحالة إلى "استراحة بين الشوطين".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
            child: const Text('نهاية الشوط الأول ⏸️'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _localData['matchStage'] = 'half_time';
        _localData['status'] = 'استراحة بين الشوطين';
      });

      if (FirebaseAuth.instance.currentUser == null) {
        try {
          await FirebaseAuth.instance.signInAnonymously();
        } catch (_) {}
      }

      widget.matchData.addAll(_localData);

      try {
        await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).set({
          'matchStage': 'half_time',
          'status': 'استراحة بين الشوطين',
          'firstHalfEndTime': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore _endFirstHalf error: $e');
      }

      unawaited(ApiClient().updateMatchStatus(widget.matchId, {
        'status': 'live',
        'match_stage': 'half_time',
      }).timeout(const Duration(seconds: 3)).catchError((_) => false));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⏸️ تم إطلاق صافرة نهاية الشوط الأول.'), backgroundColor: Colors.amber),
        );
      }
    }
  }

  Future<void> _startSecondHalf() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('صافرة بداية الشوط الثاني ▶️'),
        content: const Text('هل أطلق حكم اللقاء صافرة بداية الشوط الثاني؟\nسيبدأ العداد من الدقيقة 45 فصاعداً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('انطلاق الشوط الثاني ▶️'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _localData['matchStage'] = 'second_half';
        _localData['status'] = 'الشوط الثاني';
        _localData['addedTime2'] = 0;
        _localData['secondHalfStartTime'] = DateTime.now().toIso8601String();
      });

      if (FirebaseAuth.instance.currentUser == null) {
        try {
          await FirebaseAuth.instance.signInAnonymously();
        } catch (_) {}
      }

      widget.matchData.addAll(_localData);

      try {
        await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).set({
          'matchStage': 'second_half',
          'status': 'الشوط الثاني',
          'secondHalfStartTime': FieldValue.serverTimestamp(),
          'addedTime2': 0,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore _startSecondHalf error: $e');
      }

      unawaited(ApiClient().updateMatchStatus(widget.matchId, {
        'status': 'live',
        'match_stage': 'second_half',
        'added_time2': 0,
        'second_half_start_at': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 3)).catchError((_) => false));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('▶️ انطلق الشوط الثاني!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _endMatch() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('صافرة نهاية المباراة 🏁'),
        content: const Text('هل أطلق حكم اللقاء صافرة نهاية المباراة الرسمية؟\nسيتم تثبيت النتيجة النهائية وتغيير الحالة إلى "منتهية".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            child: const Text('إنهاء المباراة رسمياً 🏁'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _localData['matchStage'] = 'finished';
        _localData['status'] = 'منتهية';
      });

      if (FirebaseAuth.instance.currentUser == null) {
        try {
          await FirebaseAuth.instance.signInAnonymously();
        } catch (_) {}
      }

      widget.matchData.addAll(_localData);

      try {
        await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).set({
          'matchStage': 'finished',
          'status': 'منتهية',
          'matchEndTime': FieldValue.serverTimestamp(),
          'endTime': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore _endMatch error: $e');
      }

      unawaited(ApiClient().updateMatchStatus(widget.matchId, {
        'status': 'finished',
        'match_stage': 'finished',
      }).timeout(const Duration(seconds: 3)).catchError((_) => false));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🏁 تم إطلاق الصافرة النهائية ونهاية المباراة.'), backgroundColor: Colors.blueGrey),
        );

        final fillNow = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('تقرير محافظ اللقاء الرسمي 📝'),
            content: const Text('انتهت المباراة بنجاح! هل تريد ملء وتأكيد تقرير محافظ اللقاء وتوليد ملف الـ PDF الرسمي الآن؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('لاحقاً')),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(c, true),
                icon: const Icon(Icons.assignment_turned_in),
                label: const Text('ملء التقرير الآن'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
              ),
            ],
          ),
        );

        if (fillNow == true && mounted) {
          showDialog(
            context: context,
            builder: (c) => DelegateReportDialog(matchId: widget.matchId, matchData: _localData),
          );
        }
      }
    }
  }

  Future<void> _showAddedTimeDialog(String stage, int currentAddedTime) async {
    final textCtrl = TextEditingController(text: currentAddedTime > 0 ? currentAddedTime.toString() : '');
    final bool isSecondHalf = stage == 'second_half';
    final String halfLabel = isSecondHalf ? 'الشوط الثاني' : 'الشوط الأول';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.timer, color: Colors.blue),
            const SizedBox(width: 8),
            Text('تحديد الوقت بدل الضائع ($halfLabel)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اختر عدد الدقائق الإضافية التي أعلنها الحكم:', style: TextStyle(fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [1, 2, 3, 4, 5, 6, 7, 8].map((min) {
                final bool isSelected = currentAddedTime == min;
                return ChoiceChip(
                  label: Text('+$min د', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                  selected: isSelected,
                  selectedColor: Colors.blue,
                  onSelected: (_) {
                    _saveAddedTime(isSecondHalf, min);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'أو أدخل عدد الدقائق يدوياً',
                border: OutlineInputBorder(),
                suffixText: 'دقيقة',
              ),
            ),
          ],
        ),
        actions: [
          if (currentAddedTime > 0)
            TextButton(
              onPressed: () {
                _saveAddedTime(isSecondHalf, 0);
                Navigator.pop(ctx);
              },
              child: const Text('إلغاء الوقت الإضافي', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          ElevatedButton(
            onPressed: () {
              int? val = int.tryParse(textCtrl.text.trim());
              if (val != null && val >= 0) {
                _saveAddedTime(isSecondHalf, val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAddedTime(bool isSecondHalf, int minutes) async {
    setState(() {
      _localData[isSecondHalf ? 'addedTime2' : 'addedTime1'] = minutes;
    });

    try {
      await ApiClient().updateMatchStatus(widget.matchId, {
        isSecondHalf ? 'added_time2' : 'added_time1': minutes,
      });
    } catch (_) {}

    try {
      await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
        isSecondHalf ? 'addedTime2' : 'addedTime1': minutes,
      });
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(minutes > 0 ? '⏱️ تم تحديد الوقت بدل الضائع: +$minutes دقائق.' : '⏱️ تم مسح الوقت بدل الضائع.'),
          backgroundColor: Colors.indigo,
        ),
      );
    }
  }

  Future<void> _changeStageManually(String currentStage) async {
    final stages = [
      {'key': 'not_started', 'label': 'لم تبدأ (قبل صافرة البداية)', 'status': 'لم تبدأ'},
      {'key': 'first_half', 'label': 'الشوط الأول (مباشر 🟢)', 'status': 'الشوط الأول'},
      {'key': 'half_time', 'label': 'استراحة بين الشوطين (45\' ⏸️)', 'status': 'استراحة بين الشوطين'},
      {'key': 'second_half', 'label': 'الشوط الثاني (مباشر 🟢)', 'status': 'الشوط الثاني'},
      {'key': 'finished', 'label': 'منتهية (نهاية اللقاء الرسمية 🏁)', 'status': 'منتهية'},
    ];

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.tune, color: Color(0xFF1B5E20)),
            SizedBox(width: 8),
            Text('تعديل طور المباراة يدوياً ⚙️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: stages.map((st) {
            final isCurrent = currentStage == st['key'];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFF1B5E20).withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isCurrent ? const Color(0xFF1B5E20) : Colors.grey.shade300),
              ),
              child: ListTile(
                dense: true,
                title: Text(st['label']!, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600, color: isCurrent ? const Color(0xFF1B5E20) : Colors.black87)),
                trailing: isCurrent ? const Icon(Icons.check_circle, color: Color(0xFF1B5E20)) : null,
                onTap: () async {
                  final isNowLive = st['key'] == 'first_half' || st['key'] == 'second_half' || st['key'] == 'half_time';
                  final isNowFinished = st['key'] == 'finished';

                  setState(() {
                    _localData['matchStage'] = st['key'];
                    _localData['status'] = st['status'];
                    if (isNowLive || isNowFinished) {
                      if (_localData['score1'] == null || _localData['score1'] == '-') _localData['score1'] = '0';
                      if (_localData['score2'] == null || _localData['score2'] == '-') _localData['score2'] = '0';
                    }
                  });

                  final homeScoreInt = int.tryParse((_localData['score1'] ?? '0').toString()) ?? 0;
                  final awayScoreInt = int.tryParse((_localData['score2'] ?? '0').toString()) ?? 0;

                  try {
                    await ApiClient().updateMatchStatus(widget.matchId, {
                      'match_stage': st['key'],
                      'status': isNowFinished ? 'finished' : (st['key'] == 'not_started' ? 'scheduled' : 'live'),
                      if (isNowLive || isNowFinished) 'home_score': homeScoreInt,
                      if (isNowLive || isNowFinished) 'away_score': awayScoreInt,
                    });
                  } catch (_) {}

                  try {
                    Map<String, dynamic> fUpdate = {
                      'matchStage': st['key'],
                      'status': st['status'],
                    };
                    if (isNowLive || isNowFinished) {
                      fUpdate['score1'] = homeScoreInt;
                      fUpdate['score2'] = awayScoreInt;
                    }
                    await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update(fUpdate);
                  } catch (_) {}

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('⚙️ تم تحويل طور المباراة إلى: ${st['label']}'), backgroundColor: const Color(0xFF1B5E20)),
                    );
                  }
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ],
      ),
    );
  }

  Future<void> _showQuickScoreEditDialog(Map<String, dynamic> matchData) async {
    int s1 = int.tryParse((matchData['score1'] ?? '0').toString()) ?? 0;
    int s2 = int.tryParse((matchData['score2'] ?? '0').toString()) ?? 0;
    final team1Name = matchData['team1'] ?? 'المستضيف';
    final team2Name = matchData['team2'] ?? 'الضيف';

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.sports_soccer, color: Color(0xFF1B5E20)),
                  SizedBox(width: 8),
                  Text('تعديل النتيجة السريع ⚽', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('يمكنك ضبط أو تصحيح نتيجة المباراة مباشرة:', style: TextStyle(fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Team 1
                        Expanded(
                          child: Column(
                            children: [
                              Text(team1Name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 28),
                                    onPressed: s1 > 0 ? () => setDlgState(() => s1--) : null,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                                    child: Text('$s1', style: const TextStyle(color: Colors.yellowAccent, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.greenAccent, size: 28),
                                    onPressed: () => setDlgState(() => s1++),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('-', style: TextStyle(color: Colors.white54, fontSize: 28, fontWeight: FontWeight.bold)),
                        ),
                        // Team 2
                        Expanded(
                          child: Column(
                            children: [
                              Text(team2Name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 28),
                                    onPressed: s2 > 0 ? () => setDlgState(() => s2--) : null,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                                    child: Text('$s2', style: const TextStyle(color: Colors.yellowAccent, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.greenAccent, size: 28),
                                    onPressed: () => setDlgState(() => s2++),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _localData['score1'] = s1.toString();
                      _localData['score2'] = s2.toString();
                    });
                    try {
                      await ApiClient().updateMatchStatus(widget.matchId, {
                        'home_score': s1,
                        'away_score': s2,
                      });
                    } catch (_) {}
                    try {
                      await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
                        'score1': s1,
                        'score2': s2,
                      });
                    } catch (_) {}
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('⚽ تم تحديث النتيجة إلى ($s1 - $s2) بنجاح'), backgroundColor: const Color(0xFF1B5E20)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
                  child: const Text('تأكيد وحفظ النتيجة'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _quickAddGoal(String teamName, bool isHome, Map<String, dynamic> currentMatchData) async {
    int cur1 = int.tryParse((currentMatchData['score1'] ?? '0').toString()) ?? 0;
    int cur2 = int.tryParse((currentMatchData['score2'] ?? '0').toString()) ?? 0;
    if (isHome) cur1++; else cur2++;

    String minStr = _getDefaultEventMinute(currentMatchData);

    setState(() {
      _localData['score1'] = cur1.toString();
      _localData['score2'] = cur2.toString();
    });

    try {
      await ApiClient().addMatchEvent(widget.matchId, {
        'minute': minStr,
        'type': 'goal',
        'team': teamName,
        'player': 'هدف لصالح $teamName',
        'detail': 'تسجيل هدف',
        'home_score': cur1,
        'away_score': cur2,
      });
    } catch (_) {}

    try {
      await ApiClient().updateMatchStatus(widget.matchId, {
        'home_score': cur1,
        'away_score': cur2,
      });
    } catch (_) {}

    try {
      await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').add({
        'type': 'هدف',
        'team': teamName,
        'player': 'هدف لصالح $teamName',
        'minute': minStr,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
        'score1': cur1,
        'score2': cur2,
      });
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⚽ هدف! تم تحديث النتيجة إلى ($cur1 - $cur2) لصالح $teamName'),
        backgroundColor: Colors.green.shade800,
      ));
    }
  }

  void _generateQuickLineupForTeam(Map<String, dynamic> currentMatchData, String teamField) async {
    final prefix = teamField == 'team1Lineup' ? 't1' : 't2';
    List<Map<String, dynamic>> defaultList = [];
    for (int i = 1; i <= 18; i++) {
      bool isStarter = i <= 11;
      defaultList.add({
        'id': '${prefix}_$i',
        'number': '$i',
        'name': i == 1 ? 'رقم 1 (حارس)' : 'رقم $i',
        'position': i == 1 ? 'GK' : (isStarter ? 'FLD' : 'SUB'),
        'status': isStarter ? 'starter' : 'sub',
      });
    }

    setState(() {
      _localData[teamField] = defaultList;
    });

    try {
      await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
        teamField: defaultList,
      });
    } catch (_) {}

    try {
      final t1 = teamField == 'team1Lineup' ? defaultList : (_localData['team1Lineup'] ?? []);
      final t2 = teamField == 'team2Lineup' ? defaultList : (_localData['team2Lineup'] ?? []);
      await ApiClient().updateMatchLineup(widget.matchId, t1, t2);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('⚡ تم توليد أرقام قمصان اللاعبين (1 إلى 18) لهذا الفريق بنجاح'),
        backgroundColor: Color(0xFF0F766E),
      ));
    }
  }

  // ── تسجيل الأحداث مع منع التكرار والحماية من الضغط المتعدد ──────────
  void _addEvent(Map<String, dynamic> currentMatchData) async {
    if (_isSubmittingEvent) return;

    String minuteToSave = _minuteCtrl.text.trim().isEmpty 
        ? _getDefaultEventMinute(currentMatchData) 
        : _minuteCtrl.text.trim();

    final now = DateTime.now();
    final signature = '$_selectedType|$_selectedTeam|${_selectedType == 'تبديل' ? '$_subOutPlayerId->$_subInPlayerId' : '$_selectedPlayerId|${_manualPlayerCtrl.text.trim()}'}|$minuteToSave';
    if (_lastEventSignature == signature && _lastSubmitTime != null && now.difference(_lastSubmitTime!).inSeconds < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('⚠️ تم تسجيل هذا الحدث بالفعل قبل لحظات، يرجى تجنب التكرار.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ));
      return;
    }

    if (_selectedType == 'تبديل') {
      final outName = (_subOutPlayerName != null && _subOutPlayerName!.isNotEmpty)
          ? _subOutPlayerName!
          : _manualSubOutCtrl.text.trim();
      final inName = (_subInPlayerName != null && _subInPlayerName!.isNotEmpty)
          ? _subInPlayerName!
          : _manualSubInCtrl.text.trim();

      if (outName.isEmpty || inName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار أو كتابة اللاعب الخارج واللاعب الداخل')));
        return;
      }

      setState(() => _isSubmittingEvent = true);
      _lastEventSignature = signature;
      _lastSubmitTime = now;

      try {
        try {
          await ApiClient().addMatchEvent(widget.matchId, {
            'minute': minuteToSave,
            'type': 'sub',
            'team': _selectedTeam,
            'player': '$inName (بدلاً من $outName)',
            'detail': 'تبديل رسمي',
          }).timeout(const Duration(seconds: 4));
        } catch (_) {}

        try {
          await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').add({
            'type': 'تبديل',
            'team': _selectedTeam,
            'playerOut': outName,
            'playerOutId': _subOutPlayerId ?? '',
            'playerIn': inName,
            'playerInId': _subInPlayerId ?? '',
            'minute': minuteToSave,
            'timestamp': FieldValue.serverTimestamp(),
          });
        } catch (_) {}

        List<dynamic> currentLineup = _selectedTeam == currentMatchData['team1'] 
            ? List.from(currentMatchData['team1Lineup'] ?? [])
            : List.from(currentMatchData['team2Lineup'] ?? []);
            
        for (var p in currentLineup) {
          if (_subOutPlayerId != null && p['id'].toString() == _subOutPlayerId) p['status'] = 'sub';
          if (_subInPlayerId != null && p['id'].toString() == _subInPlayerId) p['status'] = 'starter';
        }

        try {
          await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
            _selectedTeam == currentMatchData['team1'] ? 'team1Lineup' : 'team2Lineup': currentLineup,
          });
        } catch (_) {}

        if (mounted) {
          setState(() {
            _localData[_selectedTeam == currentMatchData['team1'] ? 'team1Lineup' : 'team2Lineup'] = currentLineup;
            _subOutPlayerId = null;
            _subOutPlayerName = null;
            _subInPlayerId = null;
            _subInPlayerName = null;
            _manualSubOutCtrl.clear();
            _manualSubInCtrl.clear();
            _minuteCtrl.clear();
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('🔄 تم توثيق التبديل في الدقيقة $minuteToSave بنجاح'),
            backgroundColor: Colors.teal,
            duration: const Duration(seconds: 2),
          ));
        }
      } finally {
        if (mounted) setState(() => _isSubmittingEvent = false);
      }
    } else {
      final playerName = (_selectedPlayerName != null && _selectedPlayerName!.isNotEmpty)
          ? _selectedPlayerName!
          : _manualPlayerCtrl.text.trim();

      if (playerName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار اللاعب من القائمة أو كتابة اسمه/رقمه')));
        return;
      }

      setState(() => _isSubmittingEvent = true);
      _lastEventSignature = signature;
      _lastSubmitTime = now;

      String apiEventType = 'goal';
      if (_selectedType == 'بطاقة صفراء') apiEventType = 'yellow_card';
      if (_selectedType == 'بطاقة حمراء') apiEventType = 'red_card';

      try {
        try {
          await ApiClient().addMatchEvent(widget.matchId, {
            'minute': minuteToSave,
            'type': apiEventType,
            'team': _selectedTeam,
            'player': playerName,
            'detail': _selectedType,
          }).timeout(const Duration(seconds: 4));
        } catch (_) {}
        
        try {
          await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').add({
            'type': _selectedType,
            'team': _selectedTeam,
            'player': playerName,
            'playerId': _selectedPlayerId ?? '',
            'minute': minuteToSave,
            'timestamp': FieldValue.serverTimestamp(),
          });
        } catch (_) {}

        if (_selectedType == 'هدف') {
          bool isHome = _selectedTeam == currentMatchData['team1'];
          int cur1 = int.tryParse((currentMatchData['score1'] ?? '0').toString()) ?? 0;
          int cur2 = int.tryParse((currentMatchData['score2'] ?? '0').toString()) ?? 0;
          if (isHome) cur1++; else cur2++;

          setState(() {
            _localData['score1'] = cur1.toString();
            _localData['score2'] = cur2.toString();
          });

          try {
            await ApiClient().updateMatchStatus(widget.matchId, {
              'home_score': cur1,
              'away_score': cur2,
            }).timeout(const Duration(seconds: 4));
          } catch (_) {}

          try {
            await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
              isHome ? 'score1' : 'score2': FieldValue.increment(1),
            });
          } catch (_) {}
        }

        if (mounted) {
          setState(() {
            _selectedPlayerId = null;
            _selectedPlayerName = null;
            _manualPlayerCtrl.clear();
            _minuteCtrl.clear();
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ تم تسجيل $_selectedType في الدقيقة $minuteToSave بنجاح'),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 2),
          ));
        }
      } finally {
        if (mounted) setState(() => _isSubmittingEvent = false);
      }
    }

    _minuteCtrl.clear();
  }

  void _deleteEvent(String eventId, Map<String, dynamic> eventData, Map<String, dynamic> currentMatchData) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحدث'),
        content: const Text('هل أنت متأكد من حذف هذا الحدث؟ سيتم التراجع عن أثره تلقائياً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').doc(eventId).delete();
    
    // Undo logic
    if (eventData['type'] == 'هدف') {
      bool isHome = eventData['team'] == currentMatchData['team1'];
      int cur1 = int.tryParse((currentMatchData['score1'] ?? '0').toString()) ?? 0;
      int cur2 = int.tryParse((currentMatchData['score2'] ?? '0').toString()) ?? 0;
      if (isHome) {
        if (cur1 > 0) cur1--;
      } else {
        if (cur2 > 0) cur2--;
      }

      setState(() {
        _localData['score1'] = cur1.toString();
        _localData['score2'] = cur2.toString();
      });

      try {
        await ApiClient().updateMatchStatus(widget.matchId, {
          'home_score': cur1,
          'away_score': cur2,
        });
      } catch (_) {}

      try {
        await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
          'score1': cur1,
          'score2': cur2,
        });
      } catch (_) {}
    } else if (eventData['type'] == 'تبديل') {
      List<dynamic> currentLineup = eventData['team'] == currentMatchData['team1'] 
          ? List.from(currentMatchData['team1Lineup'] ?? [])
          : List.from(currentMatchData['team2Lineup'] ?? []);
          
      for (var p in currentLineup) {
        if (p['id'].toString() == eventData['playerOutId']?.toString()) p['status'] = 'starter';
        if (p['id'].toString() == eventData['playerInId']?.toString()) p['status'] = 'sub';
      }

      await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
        eventData['team'] == currentMatchData['team1'] ? 'team1Lineup' : 'team2Lineup': currentLineup,
      });
    }
  }

  // ── بناء واجهة اللوحة العلوية للصافرات والنتيجة ────────────────
  Widget _buildMatchPhaseStepper(String stage) {
    final phases = [
      {'key': 'not_started', 'label': 'قبل البداية', 'icon': Icons.schedule},
      {'key': 'first_half', 'label': 'الشوط 1', 'icon': Icons.play_arrow},
      {'key': 'half_time', 'label': 'استراحة', 'icon': Icons.pause},
      {'key': 'second_half', 'label': 'الشوط 2', 'icon': Icons.fast_forward},
      {'key': 'finished', 'label': 'منتهية', 'icon': Icons.flag},
    ];

    int activeIdx = 0;
    if (stage == 'first_half') activeIdx = 1;
    else if (stage == 'half_time') activeIdx = 2;
    else if (stage == 'second_half') activeIdx = 3;
    else if (stage == 'finished') activeIdx = 4;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(phases.length, (i) {
          final p = phases[i];
          final bool isCurrent = i == activeIdx;
          final bool isPassed = i < activeIdx;

          Color iconColor = Colors.white38;
          Color textColor = Colors.white38;
          if (isCurrent) {
            iconColor = (stage == 'finished') ? Colors.blueAccent : (stage == 'half_time' ? Colors.amberAccent : Colors.greenAccent);
            textColor = Colors.white;
          } else if (isPassed) {
            iconColor = Colors.green.shade400;
            textColor = Colors.white70;
          }

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrent
                              ? iconColor.withOpacity(0.25)
                              : (isPassed ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.05)),
                          border: Border.all(
                            color: isCurrent ? iconColor : (isPassed ? Colors.green.shade600 : Colors.white24),
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          isPassed ? Icons.check : (p['icon'] as IconData),
                          size: 14,
                          color: isPassed ? Colors.greenAccent : iconColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p['label'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < phases.length - 1)
                  Container(
                    width: 12,
                    height: 2,
                    color: isPassed ? Colors.green.shade600 : Colors.white12,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEventTypeChip(String type, String label, Color color) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedType != type) {
            setState(() {
              _selectedType = type;
              _selectedPlayerId = null;
              _selectedPlayerName = null;
              _subOutPlayerId = null;
              _subOutPlayerName = null;
              _subInPlayerId = null;
              _subInPlayerName = null;
              _manualPlayerCtrl.clear();
              _manualSubOutCtrl.clear();
              _manualSubInCtrl.clear();
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildScoreboardAndWhistleBar(Map<String, dynamic> matchData) {
    final stage = _resolveStage(matchData);
    final displayMin = _formatDisplayMinute(matchData);
    final isLive = stage == 'first_half' || stage == 'second_half';
    final isHalfTime = stage == 'half_time';
    final isFinished = stage == 'finished';
    final added1 = (matchData['addedTime1'] as num?)?.toInt() ?? 0;
    final added2 = (matchData['addedTime2'] as num?)?.toInt() ?? 0;

    final team1Name = matchData['team1'] ?? 'المستضيف';
    final team2Name = matchData['team2'] ?? 'الضيف';

    // Ensure score displays 0 - 0 cleanly when live, half time, or finished
    String s1 = (matchData['score1'] ?? '').toString();
    String s2 = (matchData['score2'] ?? '').toString();
    if (isLive || isHalfTime || isFinished) {
      if (s1.isEmpty || s1 == '-') s1 = '0';
      if (s2.isEmpty || s2 == '-') s2 = '0';
    } else {
      if (s1.isEmpty) s1 = '-';
      if (s2.isEmpty) s2 = '-';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F2B1D),
            const Color(0xFF0A1B12),
            const Color(0xFF07120C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLive ? Colors.greenAccent.withOpacity(0.3) : Colors.white12,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive ? Colors.green.withOpacity(0.15) : Colors.black45,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // شريط أطوار المباراة المرئي
          _buildMatchPhaseStepper(stage),

          // ── زر البداية المباشر والفوري للمباراة (قبل انطلاقها) ──
          if (stage == 'not_started')
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF16A34A).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                ],
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.sports, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'المباراة لم تنطلق بعد • اضغط الزر للبدء فوراً',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startFirstHalf,
                      icon: const Icon(Icons.play_circle_fill, color: Color(0xFF15803D), size: 24),
                      label: const Text(
                        'صافرة بداية المباراة (انطلاق الشوط 1 وتثبيت 0 - 0) 🏁',
                        style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF15803D),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // شريط معلومات الدقيقة وزر الطوارئ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLive
                      ? Colors.red.withOpacity(0.2)
                      : (isHalfTime ? Colors.amber.withOpacity(0.2) : Colors.white10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isLive
                        ? Colors.redAccent.withOpacity(0.5)
                        : (isHalfTime ? Colors.amberAccent.withOpacity(0.5) : Colors.white24),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLive) ...[
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Text(
                      isLive ? 'مباشر ($displayMin)' : displayMin,
                      style: TextStyle(
                        color: isLive
                            ? Colors.redAccent
                            : (isHalfTime ? Colors.amberAccent : Colors.white),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _changeStageManually(stage),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.tune, color: Colors.white38, size: 12),
                      SizedBox(width: 4),
                      Text('تعديل يدوي (طوارئ)', style: TextStyle(color: Colors.white38, fontSize: 10.5, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── لوحة النتيجة الرقمية وأزرار الأهداف السريعة ────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // الفريق 1 (المستضيف)
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Text(
                      team1Name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isLive || isHalfTime)
                      InkWell(
                        onTap: () => _quickAddGoal(team1Name, true, matchData),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF059669).withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.sports_soccer, size: 14, color: Colors.greenAccent),
                              SizedBox(width: 4),
                              Text('+ هدف', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // شاشة النتيجة الرقمية الوسطى
              Expanded(
                flex: 5,
                child: InkWell(
                  onTap: () => _showQuickScoreEditDialog(matchData),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF030D08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isLive ? Colors.greenAccent.withOpacity(0.4) : Colors.grey.shade800,
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              s1,
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '-',
                                style: TextStyle(color: Colors.white38, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              s2,
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.edit, size: 10, color: Colors.white38),
                            SizedBox(width: 3),
                            Text('تعديل النتيجة', style: TextStyle(color: Colors.white38, fontSize: 9)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // الفريق 2 (الضيف)
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Text(
                      team2Name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isLive || isHalfTime)
                      InkWell(
                        onTap: () => _quickAddGoal(team2Name, false, matchData),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF059669).withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.sports_soccer, size: 14, color: Colors.greenAccent),
                              SizedBox(width: 4),
                              Text('+ هدف', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),

          // ── مركز التحكم بالصافرات والوقت بدل الضائع ───────────────────
          _buildWhistleControls(stage, added1, added2),
        ],
      ),
    );
  }

  Widget _buildWhistleControls(String stage, int added1, int added2) {
    if (stage == 'not_started') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _startFirstHalf,
          icon: const Icon(Icons.sports, color: Colors.white, size: 24),
          label: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('صافرة بداية المباراة (انطلاق الشوط الأول) 🏁', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              SizedBox(height: 2),
              Text('بدء عداد المباراة وتثبيت النتيجة (0 - 0) فوراً في التطبيق والموقع', style: TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 4,
          ),
        ),
      );
    }

    if (stage == 'first_half') {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showAddedTimeDialog('first_half', added1),
            icon: const Icon(Icons.add_alarm, size: 18),
            label: Text(added1 > 0 ? 'الوقت الإضافي (+ $added1 د)' : '⏱️ الوقت بدل الضائع', style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: added1 > 0 ? Colors.indigo.shade700 : const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _endFirstHalf,
            icon: const Icon(Icons.pause_circle_filled, size: 20),
            label: const Text('صافرة نهاية الشوط الأول ⏸️', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    }

    if (stage == 'half_time') {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.pause_circle, color: Colors.amberAccent, size: 18),
                SizedBox(width: 8),
                Text('استراحة بين الشوطين (45 دقيقة انتهت)', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startSecondHalf,
              icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 22),
              label: const Text('صافرة انطلاق الشوط الثاني ▶️', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    if (stage == 'second_half') {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showAddedTimeDialog('second_half', added2),
            icon: const Icon(Icons.add_alarm, size: 18),
            label: Text(added2 > 0 ? 'الوقت الإضافي (+ $added2 د)' : '⏱️ الوقت بدل الضائع', style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: added2 > 0 ? Colors.indigo.shade700 : const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _endMatch,
            icon: const Icon(Icons.stop_circle, size: 20),
            label: const Text('صافرة نهاية المباراة 🏁', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    }

    // Finished
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
              SizedBox(width: 8),
              Text('المباراة منتهية رسمياً بالصافرة النهائية للحكم ✅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (c) => DelegateReportDialog(matchId: widget.matchId, matchData: _localData),
              );
            },
            icon: const Icon(Icons.assignment_turned_in, color: Colors.greenAccent, size: 18),
            label: const Text('ملء / مراجعة تقرير محافظ اللقاء الرسمي 📝', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.greenAccent),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('matches').doc(widget.matchId).snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> matchData = Map<String, dynamic>.from(_localData);
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists && snapshot.data!.data() != null) {
          final sData = snapshot.data!.data() as Map<String, dynamic>;
          matchData.addAll(sData);
        }

        if (_selectedTeam.isEmpty) {
          _selectedTeam = matchData['team1'] ?? '';
        }

        List<dynamic> lineup = _selectedTeam == matchData['team1']
            ? (matchData['team1Lineup'] ?? [])
            : (matchData['team2Lineup'] ?? []);

        List<Map<String, dynamic>> dbSquad = _selectedTeam == matchData['team1']
            ? _team1DbPlayers
            : _team2DbPlayers;

        // دمج قائمة اللاعبين من التشكيلة أو من قاعدة معطيات النادي
        List<Map<String, dynamic>> activePool = [];
        if (lineup.isNotEmpty) {
          activePool = lineup.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else if (dbSquad.isNotEmpty) {
          activePool = List.from(dbSquad);
        }

        // ترتيب اللاعبين تصاعدياً برقم القميص
        activePool.sort((a, b) {
          int numA = int.tryParse((a['number'] ?? a['jersey_number'] ?? '999').toString()) ?? 999;
          int numB = int.tryParse((b['number'] ?? b['jersey_number'] ?? '999').toString()) ?? 999;
          return numA.compareTo(numB);
        });

        List<Map<String, dynamic>> onFieldPlayers = activePool.where((p) => p['status'] == 'starter').toList();
        List<Map<String, dynamic>> benchedPlayers = activePool.where((p) => p['status'] == 'sub').toList();
        if (onFieldPlayers.isEmpty) onFieldPlayers = List.from(activePool);
        if (benchedPlayers.isEmpty) benchedPlayers = List.from(activePool);

        final defaultMin = _getDefaultEventMinute(matchData);

        // شريط الأحداث الزمني (الجهة اليسرى أو السفلية)
        Widget timelineWidget = Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          height: isMobile ? 320 : null,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('شريط أحداث اللقاء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Icon(Icons.timeline, color: Colors.blueGrey, size: 20),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('matches')
                      .doc(widget.matchId)
                      .collection('events')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, evSnap) {
                    List<Map<String, dynamic>> eventList = [];
                    if (evSnap.hasData && evSnap.data != null && evSnap.data!.docs.isNotEmpty) {
                      eventList = evSnap.data!.docs.map((d) {
                        final m = d.data() as Map<String, dynamic>;
                        m['id'] = d.id;
                        return m;
                      }).toList();
                    } else if (matchData['events'] is List && (matchData['events'] as List).isNotEmpty) {
                      eventList = (matchData['events'] as List)
                          .map((e) => Map<String, dynamic>.from(e as Map))
                          .toList()
                          .reversed
                          .toList();
                    }

                    if (eventList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.sports_soccer, size: 36, color: Colors.grey),
                            SizedBox(height: 6),
                            Text('لا توجد أحداث مسجلة بعد', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: eventList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        var evt = eventList[index];
                        String icon = '⚽';
                        if (evt['type'] == 'بطاقة صفراء' || evt['type'] == 'yellow_card') icon = '🟨';
                        if (evt['type'] == 'بطاقة حمراء' || evt['type'] == 'red_card') icon = '🟥';
                        if (evt['type'] == 'تبديل' || evt['type'] == 'sub') icon = '🔄';

                        return ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              "د${evt['minute']}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12),
                            ),
                          ),
                          title: Text('$icon ${evt['team']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(
                            evt['type'] == 'تبديل'
                                ? 'خروج: ${evt['playerOut']} ⬇️\nدخول: ${evt['playerIn']} ⬆️'
                                : '${evt['player']} - ${evt['type']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            tooltip: 'حذف الحدث والتراجع',
                            onPressed: () => _deleteEvent((evt['id'] ?? '').toString(), evt, matchData),
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

        // نموذج إضافة حدث جديد (الجهة اليمنى)
        Widget eventForm = Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إضافة حدث جديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 12),
                if (lineup.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.info_outline, color: Color(0xFF166534), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'التشكيلة غير محددة: يمكنك كتابة رقم القميص مباشرة، أو توليد أرقام اللاعبين (1-18) بنقرة واحدة.',
                                style: TextStyle(color: Color(0xFF166534), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            final field = _selectedTeam == matchData['team1'] ? 'team1Lineup' : 'team2Lineup';
                            _generateQuickLineupForTeam(matchData, field);
                          },
                          icon: const Icon(Icons.flash_on, size: 15),
                          label: const Text('⚡ تعبئة أرقام القمصان (1 إلى 18) لهذا الفريق', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ),

                // اختيار الفريق بتصميم أزرار مريحة وواضحة
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                          _selectedTeam = matchData['team1'] ?? '';
                          _selectedPlayerId = null;
                          _selectedPlayerName = null;
                          _subOutPlayerId = null;
                          _subInPlayerId = null;
                        }),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _selectedTeam == matchData['team1'] ? const Color(0xFF1B5E20) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedTeam == matchData['team1'] ? const Color(0xFF1B5E20) : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            matchData['team1'] ?? 'المضيف',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedTeam == matchData['team1'] ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                          _selectedTeam = matchData['team2'] ?? '';
                          _selectedPlayerId = null;
                          _selectedPlayerName = null;
                          _subOutPlayerId = null;
                          _subInPlayerId = null;
                        }),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _selectedTeam == matchData['team2'] ? const Color(0xFF1B5E20) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedTeam == matchData['team2'] ? const Color(0xFF1B5E20) : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            matchData['team2'] ?? 'الضيف',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedTeam == matchData['team2'] ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── نوع الحدث بأزرار تفاعلية سريعة بنقرة واحدة (بدل القائمة) ──
                Row(
                  children: [
                    _buildEventTypeChip('هدف', '⚽ هدف', const Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    _buildEventTypeChip('بطاقة صفراء', '🟨 إنذار', const Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    _buildEventTypeChip('بطاقة حمراء', '🟥 طرد', const Color(0xFFDC2626)),
                    const SizedBox(width: 6),
                    _buildEventTypeChip('تبديل', '🔄 تبديل', const Color(0xFF0F766E)),
                  ],
                ),
                if (_isLoadingDbPlayers)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                const SizedBox(height: 14),

                // ── واجهة اختيار قمصان اللاعبين والبحث بالرقم ───────────
                if (_selectedType != 'تبديل') ...[
                  Builder(
                    builder: (context) {
                      Color themeColor = const Color(0xFF1B7A36);
                      if (_selectedType == 'بطاقة صفراء') themeColor = Colors.amber.shade800;
                      if (_selectedType == 'بطاقة حمراء') themeColor = Colors.red.shade700;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          JerseyPlayerPicker(
                            players: activePool,
                            selectedPlayerId: _selectedPlayerId,
                            title: 'قميص اللاعب المعني بـ ($_selectedType)',
                            subtitle: 'مرر لاختيار القميص أو اكتب رقم القميص للقفز التلقائي',
                            primaryColor: themeColor,
                            onPlayerSelected: (player) {
                              setState(() {
                                if (player != null) {
                                  _selectedPlayerId = player['id']?.toString();
                                  _selectedPlayerName = player['name']?.toString();
                                  _manualPlayerCtrl.text = player['name']?.toString() ?? '';
                                } else {
                                  _selectedPlayerId = null;
                                  _selectedPlayerName = null;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: Text(
                                'أو كتابة اسم ورقم اللاعب يدوياً (حالة استثنائية)',
                                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, decoration: TextDecoration.underline),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                                  child: TextField(
                                    controller: _manualPlayerCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'اسم اللاعب / رقمه يدوياً',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.edit_note, size: 20),
                                      isDense: true,
                                    ),
                                    onChanged: (v) {
                                      if (v.isNotEmpty && _selectedPlayerId != null) {
                                        setState(() {
                                          _selectedPlayerId = null;
                                          _selectedPlayerName = null;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],

                if (_selectedType == 'تبديل') ...[
                  Builder(
                    builder: (context) {
                      List<Map<String, dynamic>> outList = [];
                      List<Map<String, dynamic>> inList = [];

                      if (lineup.isNotEmpty) {
                        outList = lineup.where((p) => p['status'] == 'starter').map((e) => Map<String, dynamic>.from(e as Map)).toList();
                        inList = lineup.where((p) => p['status'] == 'sub').map((e) => Map<String, dynamic>.from(e as Map)).toList();
                      }

                      if (outList.isEmpty) outList = List.from(activePool);
                      if (inList.isEmpty) inList = List.from(activePool);

                      return Column(
                        children: [
                          JerseyPlayerPicker(
                            players: outList,
                            selectedPlayerId: _subOutPlayerId,
                            title: 'اللاعب الخارج ⬇️ (مغادرة الميدان)',
                            subtitle: 'اختر قميص اللاعب المستبدل أو اكتب رقمه',
                            primaryColor: Colors.red.shade700,
                            onPlayerSelected: (player) {
                              setState(() {
                                if (player != null) {
                                  _subOutPlayerId = player['id']?.toString();
                                  _subOutPlayerName = player['name']?.toString();
                                  _manualSubOutCtrl.text = player['name']?.toString() ?? '';
                                } else {
                                  _subOutPlayerId = null;
                                  _subOutPlayerName = null;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          JerseyPlayerPicker(
                            players: inList,
                            selectedPlayerId: _subInPlayerId,
                            title: 'اللاعب الداخل ⬆️ (دخول الميدان)',
                            subtitle: 'اختر قميص اللاعب البديل أو اكتب رقمه',
                            primaryColor: Colors.green.shade700,
                            onPlayerSelected: (player) {
                              setState(() {
                                if (player != null) {
                                  _subInPlayerId = player['id']?.toString();
                                  _subInPlayerName = player['name']?.toString();
                                  _manualSubInCtrl.text = player['name']?.toString() ?? '';
                                } else {
                                  _subInPlayerId = null;
                                  _subInPlayerName = null;
                                }
                              });
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
                const SizedBox(height: 14),

                // الدقيقة
                TextField(
                  controller: _minuteCtrl,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'الدقيقة (تلقائي = د $defaultMin)',
                    border: const OutlineInputBorder(),
                    hintText: 'اتركه فارغاً للتعبئة بصافرة العداد الحالية',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'تعبئة الدقيقة الحالية',
                      onPressed: () {
                        setState(() => _minuteCtrl.text = defaultMin);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // زر الحفظ المحمي من الضغط المتكرر
                ElevatedButton.icon(
                  onPressed: _isSubmittingEvent ? null : () => _addEvent(matchData),
                  icon: _isSubmittingEvent
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                  label: Text(
                    _isSubmittingEvent ? 'جاري توثيق الحدث في البث المباشر...' : 'تسجيل الحدث في المباراة ✅',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: _isSubmittingEvent ? Colors.grey.shade600 : const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    elevation: _isSubmittingEvent ? 0 : 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        );

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إدارة أحداث ومجريات المباراة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            content: SizedBox(
              width: isMobile ? double.maxFinite : 950,
              height: isMobile ? null : 650,
              child: isMobile
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildScoreboardAndWhistleBar(matchData),
                          eventForm,
                          const SizedBox(height: 16),
                          timelineWidget,
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildScoreboardAndWhistleBar(matchData),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: timelineWidget),
                              const SizedBox(width: 16),
                              Expanded(flex: 5, child: SingleChildScrollView(child: eventForm)),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق اللوحة'),
              ),
            ],
          ),
        );
      },
    );
  }
}