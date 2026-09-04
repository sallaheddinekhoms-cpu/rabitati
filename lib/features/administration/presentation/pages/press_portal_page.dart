import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/theme_extensions.dart';

class PressPortalPage extends StatefulWidget {
  const PressPortalPage({super.key});

  @override
  State<PressPortalPage> createState() => _PressPortalPageState();
}

class _PressPortalPageState extends State<PressPortalPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _mediaOutletCtrl = TextEditingController();
  final TextEditingController _cardNumCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  String _selectedLeague = 'جهوي أول';
  String? _selectedMatchId;
  Map<String, dynamic>? _selectedMatchData;
  String _selectedMediaType = 'صحافة مكتوبة';
  bool _isSubmitting = false;

  // Tracking Tab
  final TextEditingController _trackingQueryCtrl = TextEditingController();
  String _activeSearchQuery = '';

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

  final List<String> _mediaTypes = [
    'صحافة مكتوبة',
    'سمعي بصري / تلفزيون',
    'صحافة إلكترونية',
    'إذاعة مسموعة',
    'مصور فوتوغرافي',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _mediaOutletCtrl.dispose();
    _cardNumCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _trackingQueryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameCtrl.text = prefs.getString('saved_journalist_name') ?? '';
      _mediaOutletCtrl.text = prefs.getString('saved_media_outlet') ?? '';
      _cardNumCtrl.text = prefs.getString('saved_press_card') ?? '';
      _phoneCtrl.text = prefs.getString('saved_phone') ?? '';
      _emailCtrl.text = prefs.getString('saved_email') ?? '';
      
      final lastPhone = prefs.getString('saved_phone') ?? '';
      if (lastPhone.isNotEmpty) {
        _trackingQueryCtrl.text = lastPhone;
        _activeSearchQuery = lastPhone;
      }
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_journalist_name', _nameCtrl.text.trim());
    await prefs.setString('saved_media_outlet', _mediaOutletCtrl.text.trim());
    await prefs.setString('saved_press_card', _cardNumCtrl.text.trim());
    await prefs.setString('saved_phone', _phoneCtrl.text.trim());
    await prefs.setString('saved_email', _emailCtrl.text.trim());
  }

  Future<void> _submitRequest() async {
    if (_selectedMatchId == null || _selectedMatchData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار المباراة المراد تغطيتها أولاً!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final refCode = 'LRF-PRESS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final matchTitle = '${_selectedMatchData!['team1']} ضد ${_selectedMatchData!['team2']}';

      await FirebaseFirestore.instance.collection('media_accreditations').add({
        'referenceCode': refCode,
        'journalistName': _nameCtrl.text.trim(),
        'mediaOutlet': _mediaOutletCtrl.text.trim(),
        'mediaType': _selectedMediaType,
        'pressCardNumber': _cardNumCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'league': _selectedLeague,
        'matchId': _selectedMatchId,
        'matchTitle': matchTitle,
        'matchDate': '${_selectedMatchData!['date'] ?? ''} ${_selectedMatchData!['time'] ?? ''}'.trim(),
        'stadium': _selectedMatchData!['stadium'] ?? 'الملعب الرسمي',
        'round': _selectedMatchData!['round'] ?? '',
        'status': 'pending',
        'adminNote': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _saveCredentials();

      if (!mounted) return;

      // Update tracking query
      setState(() {
        _activeSearchQuery = _phoneCtrl.text.trim();
        _trackingQueryCtrl.text = _phoneCtrl.text.trim();
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              const Text('تم إرسال الطلب بنجاح', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تم تسجيل طلب الاعتماد الخاص بكم لدى خلية الإعلام بالرابطة.'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('رقم المرجع الخاص بك:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 4),
                    SelectableText(
                      refCode,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'يمكنك متابعة حالة طلبك والحصول على بطاقة الاعتماد الرقمية عبر تبويب "متابعة طلباتي".',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _tabController.animateTo(1);
              },
              child: const Text('متابعة حالة الطلب', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إرسال الطلب: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _sendBadgeEmail(Map<String, dynamic> data) async {
    final email = data['email'] ?? '';
    final ref = data['referenceCode'] ?? '';
    final match = data['matchTitle'] ?? '';
    final stadium = data['stadium'] ?? '';
    final date = data['matchDate'] ?? '';
    final journalist = data['journalistName'] ?? '';
    final outlet = data['mediaOutlet'] ?? '';

    final subject = Uri.encodeComponent('بطاقة الاعتماد الصحفي الرسمي - الرابطة الجهوية البليدة ($ref)');
    final body = Uri.encodeComponent(
      'السيد(ة) الإعلامي(ة): $journalist\n'
      'المؤسسة: $outlet\n\n'
      'يسر الرابطة الجهوية لكرة القدم البليدة إعلامكم بقبول طلب الاعتماد لتغطية المباراة الرسمية:\n\n'
      '⚽ المباراة: $match\n'
      '🏟️ الملعب: $stadium\n'
      '📅 التاريخ والتوقيت: $date\n'
      '🎫 رقم المرجع: $ref\n'
      '📌 ملاحظات الدخول: ${data['adminNote'] ?? 'معتمد رسمياً للدخول'}\n\n'
      'يرجى الاستظهار بهذه الرسالة أو ببطاقة الاعتماد الرقمية عبر تطبيق رابطتي مع بطاقة الصحافة الوطنية عند مدخل الملعب.\n\n'
      'مع تحيات خلية الإعلام والاتصال - الرابطة الجهوية لكرة القدم البليدة',
    );

    final mailtoUri = Uri.parse('mailto:$email?subject=$subject&body=$body');
    try {
      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
      } else {
        await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح تطبيق البريد الإلكتروني تلقائياً.')),
        );
      }
    }
  }

  void _showDigitalBadgeDialog(Map<String, dynamic> data) {
    final ref = data['referenceCode'] ?? 'LRF-PASS';
    final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=LRF-ACCREDITATION-$ref';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Container(
          width: 380,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B7A36),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.shield, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'الرابطة الجهوية لكرة القدم - البليدة',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8681A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'بطاقة اعتماد صحفي رسمي - PRESS PASS',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                // Match details inside badge
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        data['matchTitle'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data['league'] ?? ''} ${data['round'] ?? ''}'.trim(),
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.stadium, size: 16, color: Color(0xFF1B7A36)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text('الملعب: ${data['stadium'] ?? 'غير محدد'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text('التاريخ: ${data['matchDate'] ?? ''}', style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 10),

                      // Journalist Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('الاسم واللقب:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(data['journalistName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 6),
                                const Text('المؤسسة الإعلامية:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(data['mediaOutlet'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1B7A36))),
                                const SizedBox(height: 6),
                                const Text('رقم البطاقة المهنية:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(data['pressCardNumber'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                          // QR Code
                          Column(
                            children: [
                              Container(
                                width: 95,
                                height: 95,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    qrUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.qr_code, size: 70, color: Colors.green),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(ref, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                            ],
                          ),
                        ],
                      ),

                      if ((data['adminNote'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(
                            'ملاحظة: ${data['adminNote']}',
                            style: TextStyle(color: Colors.orange.shade900, fontSize: 11),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      // Actions row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1B7A36),
                                side: const BorderSide(color: Color(0xFF1B7A36)),
                              ),
                              icon: const Icon(Icons.email, size: 16),
                              label: const Text('إرسال للإيميل', style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _sendBadgeEmail(data);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B7A36)),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('إغلاق', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(
          'بوابة الإعلام والصحافة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.appPrimary),
        ),
        centerTitle: true,
        backgroundColor: context.appCardBackground,
        elevation: 0.5,
        iconTheme: IconThemeData(color: context.appPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.appPrimary,
          unselectedLabelColor: context.appTextSecondary,
          indicatorColor: context.appPrimary,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.edit_document), text: 'طلب اعتماد جديد'),
            Tab(icon: Icon(Icons.assignment_turned_in), text: 'متابعة طلباتي'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewRequestTab(),
          _buildTrackingTab(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Tab 1: تقديم طلب اعتماد جديد
  // ══════════════════════════════════════════════════════════════
  Widget _buildNewRequestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.appPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appPrimary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.newspaper, color: context.appPrimary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اعتمادات تغطية مباريات الرابطة',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.appTextPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'اختر القسم والمباراة وأدخل بياناتك للحصول على بطاقة الاعتماد الرقمية.',
                          style: TextStyle(fontSize: 12, color: context.appTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 1. اختيار القسم
            Text('1. اختيار القسم / البطولة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.appCardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.appBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLeague,
                  isExpanded: true,
                  items: _leagues.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedLeague = val;
                        _selectedMatchId = null;
                        _selectedMatchData = null;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. اختيار المباراة
            Text('2. اختيار المباراة المراد تغطيتها:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('matches')
                  .where('league', isEqualTo: _selectedLeague)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.appCardBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.appBorder),
                    ),
                    child: Text(
                      'لا توجد مباريات مسجلة حالياً في قسم $_selectedLeague.',
                      style: TextStyle(color: context.appTextSecondary, fontSize: 13),
                    ),
                  );
                }

                final matchItems = docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final title = '${data['team1']} ضد ${data['team2']} (${data['round'] ?? 'مباراة'})';
                  return {'id': d.id, 'title': title, 'data': data};
                }).toList();

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: context.appCardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      hint: const Text('اضغط لاختيار المباراة'),
                      value: _selectedMatchId,
                      isExpanded: true,
                      items: matchItems.map((m) {
                        return DropdownMenuItem<String>(
                          value: m['id'] as String,
                          child: Text(m['title'] as String, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final selected = matchItems.firstWhere((m) => m['id'] == val);
                          setState(() {
                            _selectedMatchId = val;
                            _selectedMatchData = selected['data'] as Map<String, dynamic>;
                          });
                        }
                      },
                    ),
                  ),
                );
              },
            ),

            // ── Auto Match Details Card ───────────────────────────
            if (_selectedMatchData != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.appCardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.appPrimary.withOpacity(0.35), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.appPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_selectedMatchData!['league'] ?? ''} - ${_selectedMatchData!['round'] ?? ''}',
                            style: TextStyle(color: context.appPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(
                            _selectedMatchData!['status'] ?? 'لم تبدأ',
                            style: TextStyle(color: Colors.orange.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.shield, size: 36, color: Color(0xFF1B7A36)),
                              const SizedBox(height: 4),
                              Text(
                                _selectedMatchData!['team1'] ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('VS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.shield_outlined, size: 36, color: Color(0xFFE8681A)),
                              const SizedBox(height: 4),
                              Text(
                                _selectedMatchData!['team2'] ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.stadium, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'الملعب: ${_selectedMatchData!['stadium'] ?? 'ملعب معتمد من الرابطة'}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text(
                          'التاريخ: ${_selectedMatchData!['date'] ?? 'محدد لاحقاً'}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time, size: 16, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          'التوقيت: ${_selectedMatchData!['time'] ?? '15:00'}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            // 3. بيانات الصحفي
            Text('3. بيانات الصحفي / الهيئة الإعلامية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary)),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'الاسم واللقب الكامل *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال الاسم واللقب' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _mediaOutletCtrl,
              decoration: const InputDecoration(
                labelText: 'المؤسسة الإعلامية / الموقع / القناة *',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم المؤسسة الإعلامية' : null,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedMediaType,
              decoration: const InputDecoration(
                labelText: 'نوع الوسيلة / الصفة',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: _mediaTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedMediaType = val);
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _cardNumCtrl,
              decoration: const InputDecoration(
                labelText: 'رقم بطاقة الصحافة المهنية / الوطنية *',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال رقم بطاقة الصحافة' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف للتواصل ومتابعة الطلب *',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().length < 9) ? 'يرجى إدخال رقم هاتف صحيح' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني لاستلام نسخة الاعتماد *',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || !v.contains('@')) ? 'يرجى إدخال بريد إلكتروني صحيح' : null,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'جاري إرسال الطلب...' : 'إرسال طلب الاعتماد',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _isSubmitting ? null : _submitRequest,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Tab 2: متابعة طلباتي وبطاقة الاعتماد
  // ══════════════════════════════════════════════════════════════
  Widget _buildTrackingTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.appCardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _trackingQueryCtrl,
                    decoration: InputDecoration(
                      hintText: 'أدخل رقم الهاتف أو رقم المرجع...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (v) => setState(() => _activeSearchQuery = v.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    setState(() => _activeSearchQuery = _trackingQueryCtrl.text.trim());
                  },
                  child: const Text('بحث', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Results Stream
          Expanded(
            child: _activeSearchQuery.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: context.appTextSecondary.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'أدخل رقم هاتفك المسجل أو رقم المرجع للبحث عن طلباتك.',
                          style: TextStyle(color: context.appTextSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('media_accreditations')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: context.appPrimary));
                      }

                      final allDocs = snapshot.data?.docs ?? [];
                      final query = _activeSearchQuery.toLowerCase();
                      final results = allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final phone = (data['phone'] ?? '').toString();
                        final ref = (data['referenceCode'] ?? '').toString().toLowerCase();
                        return phone.contains(query) || ref.contains(query);
                      }).toList();

                      if (results.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_off, size: 64, color: context.appTextSecondary.withOpacity(0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'لم يتم العثور على أي طلب اعتماد بهذا الرقم أو المرجع.',
                                style: TextStyle(color: context.appTextSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final data = results[index].data() as Map<String, dynamic>;
                          final status = data['status'] ?? 'pending';

                          Color statusColor = Colors.orange;
                          String statusText = 'قيد المراجعة من طرف الرابطة';
                          IconData statusIcon = Icons.hourglass_top;

                          if (status == 'approved') {
                            statusColor = Colors.green;
                            statusText = 'تم قبول الاعتماد رسميـاً 🎉';
                            statusIcon = Icons.verified;
                          } else if (status == 'rejected') {
                            statusColor = Colors.red;
                            statusText = 'تم رفض الطلب';
                            statusIcon = Icons.cancel;
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.appCardBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: statusColor.withOpacity(0.4)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status Banner
                                Row(
                                  children: [
                                    Icon(statusIcon, color: statusColor, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      statusText,
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        data['referenceCode'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Match Title
                                Text(
                                  data['matchTitle'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${data['league'] ?? ''} | الملعب: ${data['stadium'] ?? 'غير محدد'}',
                                  style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'التاريخ: ${data['matchDate'] ?? ''}',
                                  style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                                ),

                                if ((data['adminNote'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'ملاحظة الإدارة: ${data['adminNote']}',
                                      style: TextStyle(color: statusColor, fontSize: 12),
                                    ),
                                  ),
                                ],

                                if (status == 'approved') ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          icon: const Icon(Icons.badge, color: Colors.white, size: 18),
                                          label: const Text('عرض البطاقة الرقمية', style: TextStyle(color: Colors.white, fontSize: 13)),
                                          onPressed: () => _showDigitalBadgeDialog(data),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.green.shade50,
                                        ),
                                        icon: const Icon(Icons.email, color: Colors.green),
                                        tooltip: 'إرسال نسخة للإيميل',
                                        onPressed: () => _sendBadgeEmail(data),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
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
  }
}
