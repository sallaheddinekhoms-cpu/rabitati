import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/network/api_client.dart';

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

  String _selectedLeague = 'الكل';
  String? _selectedMatchId;
  Map<String, dynamic>? _selectedMatchData;
  String _selectedMediaType = 'صحافة مكتوبة';
  bool _isSubmitting = false;
  bool _isLoadingMatches = false;
  bool _isSearchingTrack = false;
  String? _photoBase64;
  String? _documentBase64;

  // Unified API Data
  List<Map<String, dynamic>> _apiMatches = [];
  List<Map<String, dynamic>> _apiTrackResults = [];

  // Tracking Tab
  final TextEditingController _trackingQueryCtrl = TextEditingController();
  String _activeSearchQuery = '';

  Future<void> _pickPhoto({required bool isPersonalPhoto, required ImageSource source}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: isPersonalPhoto ? 600 : 1200,
        maxHeight: isPersonalPhoto ? 600 : 1600,
        imageQuality: 75,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          if (isPersonalPhoto) {
            _photoBase64 = base64Encode(bytes);
          } else {
            _documentBase64 = base64Encode(bytes);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر التقاط / اختيار الصورة: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImageSourceSheet({required bool isPersonalPhoto, required String title}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('التقاط صورة بالكاميرا الآن (تصوير / سكان)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(isPersonalPhoto: isPersonalPhoto, source: ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('اختيار صورة من معرض الصور'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(isPersonalPhoto: isPersonalPhoto, source: ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> get _dynamicLeagues {
    final list = <String>['الكل'];
    final knownLeagues = [
      'كأس الجزائر',
      'الجهوي الأول',
      'الجهوي الثاني - فوج أ',
      'الجهوي الثاني - فوج ب',
    ];
    for (final k in knownLeagues) {
      if (!list.contains(k)) list.add(k);
    }
    for (final m in _apiMatches) {
      final l = (m['league'] ?? '').toString().trim();
      if (l.isNotEmpty && !list.contains(l)) {
        list.add(l);
      }
    }
    return list;
  }

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
    _loadApiMatches();
  }

  Future<void> _loadApiMatches() async {
    if (mounted) setState(() => _isLoadingMatches = true);
    try {
      final matches = await ApiClient().getAccreditationMatches();
      if (mounted) {
        setState(() {
          _apiMatches = matches;
          _isLoadingMatches = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMatches = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredMatches() {
    if (_apiMatches.isEmpty) return [];
    if (_selectedLeague == 'الكل') return _apiMatches;

    return _apiMatches.where((m) {
      final league = (m['league'] ?? '').toString();
      final round = (m['round'] ?? '').toString();

      if (_selectedLeague.contains('كأس') || _selectedLeague.contains('كاس')) {
        return league.contains('كأس') || league.contains('كاس') || league.toLowerCase().contains('coupe') ||
               round.contains('كأس') || round.contains('كاس') || round.toLowerCase().contains('coupe');
      }
      if (_selectedLeague.contains('أول')) {
        return (league.contains('أول') || league.contains('الجهوي الأول')) &&
               !league.contains('كأس') && !league.contains('كاس');
      }
      if (_selectedLeague.contains('فوج أ')) {
        return (league.contains('فوج أ') || league.contains('2 أ')) &&
               !league.contains('كأس') && !league.contains('كاس');
      }
      if (_selectedLeague.contains('فوج ب')) {
        return (league.contains('فوج ب') || league.contains('2 ب')) &&
               !league.contains('كأس') && !league.contains('كاس');
      }
      return league.contains(_selectedLeague) || _selectedLeague.contains(league);
    }).toList();
  }

  Future<void> _searchTrackApi(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      if (mounted) setState(() => _apiTrackResults = []);
      return;
    }
    if (mounted) setState(() => _isSearchingTrack = true);
    try {
      final results = await ApiClient().trackAccreditations(clean);
      if (mounted) {
        setState(() {
          _apiTrackResults = results;
          _isSearchingTrack = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearchingTrack = false);
    }
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
        _searchTrackApi(lastPhone);
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

    if (_photoBase64 == null || _photoBase64!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الصورة الشخصية للصحفي إلزامية! يرجى التقاطها بالكاميرا أو إرفاقها.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_documentBase64 == null || _documentBase64!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('وثيقة الاعتماد الرسمي من النادي أو البطاقة المهنية إلزامية! يرجى تصويرها أو إرفاقها.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String refCode = 'LRF-PRESS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final matchTitle = _selectedMatchData!['match_title'] ?? '${_selectedMatchData!['team1']} ضد ${_selectedMatchData!['team2']}';

      // Submit to Unified Laravel Website API
      try {
        final apiRes = await ApiClient().submitAccreditation({
          'journalist_name': _nameCtrl.text.trim(),
          'media_outlet': _mediaOutletCtrl.text.trim(),
          'media_type': _selectedMediaType,
          'press_card_number': _cardNumCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'photo_base64': _photoBase64 ?? '',
          'document_base64': _documentBase64 ?? '',
          'match_id': _selectedMatchId,
          'match_title': matchTitle,
          'match_date': '${_selectedMatchData!['date'] ?? ''} ${_selectedMatchData!['time'] ?? ''}'.trim(),
          'stadium': _selectedMatchData!['stadium'] ?? 'الملعب الرسمي',
          'league': _selectedMatchData!['league'] ?? _selectedLeague,
          'round': _selectedMatchData!['round'] ?? '',
        });
        if (apiRes != null && apiRes['status'] == 'error') {
          if (mounted) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(apiRes['message'] ?? 'فشل إرسال الطلب'), backgroundColor: Colors.red),
            );
          }
          return;
        }
        if (apiRes != null && apiRes['data'] != null && apiRes['data']['reference_code'] != null) {
          refCode = apiRes['data']['reference_code'].toString();
        }
      } catch (e) {
        debugPrint('Accreditation API submit error: $e');
      }

      await _saveCredentials();

      if (!mounted) return;

      // Update tracking query and reset photo & document
      setState(() {
        _activeSearchQuery = _phoneCtrl.text.trim();
        _trackingQueryCtrl.text = _phoneCtrl.text.trim();
        _photoBase64 = null;
        _documentBase64 = null;
      });
      _searchTrackApi(_phoneCtrl.text.trim());

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
              const Text('تم تسجيل طلب الاعتماد الخاص بكم لدى خلية الإعلام بالرابطة بنجاح عبر النظام الرقمي الموحد.'),
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

  void _showDigitalBadgeDialog(Map<String, dynamic> data) {
    final ref = data['referenceCode'] ?? data['reference_code'] ?? 'LRF-PASS';
    final qrUrl = data['qrCodeUrl'] ?? 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=LRF-ACCREDITATION-$ref';

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
                        data['matchTitle'] ?? data['match_title'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data['league'] ?? data['league_name'] ?? ''} ${data['round'] ?? ''}'.trim(),
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
                                  child: Text('التاريخ: ${data['matchDate'] ?? data['match_date'] ?? ''}', style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 10),

                      // Journalist Info + Photo + QR Code
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((data['photoBase64'] ?? data['photo_path'] ?? '').toString().isNotEmpty && !(data['photoBase64'] ?? data['photo_path'] ?? '').toString().startsWith('http'))
                            Container(
                              width: 65,
                              height: 80,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF1B7A36), width: 1.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(
                                  base64Decode((data['photoBase64'] ?? data['photo_path']).toString()),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 36, color: Colors.grey),
                                ),
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('الاسم واللقب:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(data['journalistName'] ?? data['journalist_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 6),
                                const Text('المؤسسة الإعلامية:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(data['mediaOutlet'] ?? data['media_outlet'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1B7A36))),
                                const SizedBox(height: 6),
                                const Text('رقم البطاقة المهنية:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(data['pressCardNumber'] ?? data['press_card_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                          // QR Code
                          Column(
                            children: [
                              Container(
                                width: 85,
                                height: 85,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    qrUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.qr_code, size: 60, color: Colors.green),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(ref, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54)),
                            ],
                          ),
                        ],
                      ),

                      if ((data['adminNote'] ?? data['admin_note'] ?? '').toString().isNotEmpty) ...[
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
                            'ملاحظة: ${data['adminNote'] ?? data['admin_note']}',
                            style: TextStyle(color: Colors.orange.shade900, fontSize: 11),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      // Email confirmation notification banner from administration
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.mark_email_read, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'تم اعتماد طلبكم رسمياً من قبل خلية الإعلام بالرابطة.',
                                style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B7A36),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('إغلاق', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
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
    final filteredMatches = _getFilteredMatches();

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
                  Icon(Icons.info_outline, color: context.appPrimary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'مرحباً بأسرة الإعلام الوطني. يرجى اختيار المباراة وملء بياناتكم الرسمية للحصول على بطاقة التغطية الصحفية المعتمدة.',
                      style: TextStyle(fontSize: 13, color: context.appTextPrimary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 1. اختيار البطولة
            Text('1. تصفية حسب القسم / البطولة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary)),
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
                  value: _dynamicLeagues.contains(_selectedLeague) ? _selectedLeague : 'الكل',
                  isExpanded: true,
                  items: _dynamicLeagues.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('2. اختيار المباراة المراد تغطيتها:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary)),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'تحديث قائمة المباريات',
                  onPressed: _loadApiMatches,
                ),
              ],
            ),
            const SizedBox(height: 4),

            if (_isLoadingMatches)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (filteredMatches.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.appCardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.appBorder),
                ),
                child: Text(
                  'لا توجد مباريات مبرمجة حالياً في قسم $_selectedLeague.',
                  style: TextStyle(color: context.appTextSecondary, fontSize: 13),
                ),
              )
            else
              Container(
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
                    items: filteredMatches.map((m) {
                      final leagueName = (m['league'] ?? '').toString();
                      final isCup = leagueName.contains('كأس') || leagueName.contains('كاس') || leagueName.toLowerCase().contains('coupe');
                      final prefix = isCup ? '🏆 [كأس الجزائر] ' : '';
                      final roundTag = (m['round'] != null && m['round'].toString().isNotEmpty && !m['round'].toString().contains('رسمية')) 
                          ? ' - ${m['round']}' 
                          : '';
                      final title = '$prefix${m['match_title'] ?? "${m['team1']} ضد ${m['team2']}"}$roundTag (${m['date'] ?? ''})';
                      return DropdownMenuItem<String>(
                        value: m['id'].toString(),
                        child: Text(title, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final selected = filteredMatches.firstWhere((m) => m['id'].toString() == val);
                        setState(() {
                          _selectedMatchId = val;
                          _selectedMatchData = selected;
                        });
                      }
                    },
                  ),
                ),
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
                      color: context.appPrimary.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: context.appPrimary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.sports_soccer, color: context.appPrimary, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedMatchData!['match_title'] ?? '${_selectedMatchData!['team1']} ضد ${_selectedMatchData!['team2']}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.appTextPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.stadium_outlined, size: 16, color: context.appTextSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'الملعب: ${_selectedMatchData!['stadium'] ?? 'الملعب الرسمي'}',
                            style: TextStyle(fontSize: 12.5, color: context.appTextSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.event_outlined, size: 16, color: context.appTextSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'الموعد: ${_selectedMatchData!['date'] ?? ''} ${_selectedMatchData!['time'] ?? ''}'.trim(),
                          style: TextStyle(fontSize: 12.5, color: context.appTextSecondary),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.appPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _selectedMatchData!['round'] ?? 'مباراة رسمية',
                            style: TextStyle(color: context.appPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 3. نوع الوسيلة الإعلامية
            Text('3. نوع الوسيلة الإعلامية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary)),
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
                  value: _selectedMediaType,
                  isExpanded: true,
                  items: _mediaTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMediaType = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. الصورة الشخصية للصحفي (إلزامي)
            Row(
              children: [
                Text('4. الصورة الشخصية للصحفي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary)),
                const SizedBox(width: 6),
                const Text('*(إلزامي)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showImageSourceSheet(
                isPersonalPhoto: true,
                title: 'إرفاق الصورة الشخصية للصحفي (كاميرا أو معرض)',
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.appCardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _photoBase64 != null ? Colors.green : Colors.red.withOpacity(0.5),
                    width: _photoBase64 != null ? 1.8 : 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    if (_photoBase64 != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(_photoBase64!),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('تم إرفاق الصورة الشخصية بنجاح ✓', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                            Text('اضغط للتعديل أو التقاط صورة جديدة', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() => _photoBase64 = null),
                      ),
                    ] else ...[
                      const Icon(Icons.add_a_photo_outlined, color: Colors.redAccent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('التقاط بالكاميرا أو اختيار الصورة الشخصية *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.appTextPrimary)),
                            Text('إلزامية لتثبيتها في بطاقة الدخول الصحفية (PRESS PASS)', style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.touch_app_outlined, color: Colors.grey, size: 20),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 5. وثيقة الاعتماد الرسمي من النادي أو البطاقة المهنية (إلزامي)
            Row(
              children: [
                Text('5. الاعتماد الرسمي من النادي أو البطاقة المهنية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary)),
                const SizedBox(width: 6),
                const Text('*(إلزامي)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showImageSourceSheet(
                isPersonalPhoto: false,
                title: 'تصوير أو إرفاق وثيقة الاعتماد / البطاقة المهنية',
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.appCardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _documentBase64 != null ? Colors.green : Colors.red.withOpacity(0.5),
                    width: _documentBase64 != null ? 1.8 : 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    if (_documentBase64 != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(_documentBase64!),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('تم إرفاق الوثيقة / بطاقة الصحافة بنجاح ✓', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                            Text('اضغط لإعادة التصوير أو التغيير', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() => _documentBase64 = null),
                      ),
                    ] else ...[
                      const Icon(Icons.document_scanner_outlined, color: Colors.redAccent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('تصوير أو سكان لوثيقة النادي أو بطاقة الصحافة *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.appTextPrimary)),
                            Text('بدونها لا يمكن قبول طلب الاعتماد من طرف إدارة الرابطة', style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.touch_app_outlined, color: Colors.grey, size: 20),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 6. البيانات الشخصية
            Text('6. البيانات الشخصية والمهنية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary)),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'الاسم واللقب *',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال الاسم واللقب' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _mediaOutletCtrl,
              decoration: InputDecoration(
                labelText: 'المؤسسة الإعلامية أو الموقع *',
                prefixIcon: const Icon(Icons.business_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم الوسيلة الإعلامية' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _cardNumCtrl,
              decoration: InputDecoration(
                labelText: 'رقم البطاقة المهنية / بطاقة الصحافة *',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال رقم البطاقة المهنية' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف للاتصال ومتابعة الطلب *',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال رقم الهاتف' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني (لتلقي نسخة الاعتماد)',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _submitRequest,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'جاري إرسال الطلب...' : 'إرسال طلب الاعتماد رسميـاً',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Tab 2: متابعة الطلبات والبطاقة الرقمية
  // ══════════════════════════════════════════════════════════════
  Widget _buildTrackingTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Box
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
                    onSubmitted: (v) {
                      final q = v.trim();
                      setState(() => _activeSearchQuery = q);
                      _searchTrackApi(q);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    final q = _trackingQueryCtrl.text.trim();
                    setState(() => _activeSearchQuery = q);
                    _searchTrackApi(q);
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
                : _isSearchingTrack
                    ? Center(child: CircularProgressIndicator(color: context.appPrimary))
                    : _apiTrackResults.isEmpty
                        ? Center(
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
                          )
                        : RefreshIndicator(
                            onRefresh: () => _searchTrackApi(_activeSearchQuery),
                            child: ListView.separated(
                              itemCount: _apiTrackResults.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final data = _apiTrackResults[index];
                                final status = data['status'] ?? 'pending';

                                Color statusColor = Colors.orange;
                                String statusText = 'قيد المراجعة من طرف الرابطة';
                                IconData statusIcon = Icons.hourglass_top;

                                if (status == 'approved' || status == 'مقبول') {
                                  statusColor = Colors.green;
                                  statusText = 'تم قبول الاعتماد رسميـاً 🎉';
                                  statusIcon = Icons.verified;
                                } else if (status == 'rejected' || status == 'مرفوض') {
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
                                              data['referenceCode'] ?? data['reference_code'] ?? '',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Match Title
                                      Text(
                                        data['matchTitle'] ?? data['match_title'] ?? '',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.appTextPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${data['league'] ?? data['league_name'] ?? ''} | الملعب: ${data['stadium'] ?? 'غير محدد'}',
                                        style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'التاريخ: ${data['matchDate'] ?? data['match_date'] ?? ''}',
                                        style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                                      ),

                                      if ((data['adminNote'] ?? data['admin_note'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'ملاحظة الإدارة: ${data['adminNote'] ?? data['admin_note']}',
                                            style: TextStyle(color: statusColor, fontSize: 12),
                                          ),
                                        ),
                                      ],

                                      if (status == 'approved' || status == 'مقبول') ...[
                                        const SizedBox(height: 14),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 44,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            icon: const Icon(Icons.badge, color: Colors.white, size: 20),
                                            label: const Text(
                                              'عرض بطاقة الاعتماد الرقمية (PRESS PASS)',
                                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                            ),
                                            onPressed: () => _showDigitalBadgeDialog(data),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
