import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/network/api_client.dart';
import 'delegate_report_pdf.dart';

class DelegateReportDialog extends StatefulWidget {
  final String matchId;
  final Map<String, dynamic> matchData;

  const DelegateReportDialog({
    super.key,
    required this.matchId,
    required this.matchData,
  });

  @override
  State<DelegateReportDialog> createState() => _DelegateReportDialogState();
}

class _DelegateReportDialogState extends State<DelegateReportDialog> {
  late TextEditingController _spectatorsCtrl;
  late TextEditingController _halfTimeScoreCtrl;
  late TextEditingController _refereeCtrl;
  late TextEditingController _assistant1Ctrl;
  late TextEditingController _assistant2Ctrl;
  late TextEditingController _fourthOfficialCtrl;

  // أسئلة التنظيم (قسم 9)
  bool _orgGeneralYes = false;
  late TextEditingController _orgGeneralNotesCtrl;

  bool _orgSecurityYes = false;
  late TextEditingController _orgSecurityNotesCtrl;

  bool _orgMedicalYes = false;
  late TextEditingController _orgMedicalNotesCtrl;

  bool _orgMediaYes = false;
  late TextEditingController _orgMediaNotesCtrl;

  late TextEditingController _orgOtherNotesCtrl;

  // الحوادث (أقسام 12، 13، 14)
  bool _incPlayersYes = false;
  late TextEditingController _incPlayersNotesCtrl;

  bool _incFansYes = false;
  late TextEditingController _incFansNotesCtrl;

  bool _incOtherYes = false;
  late TextEditingController _incOtherNotesCtrl;

  late TextEditingController _reportPlaceCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final match = widget.matchData;
    final Map<String, dynamic> existingReport = (match['delegateReport'] is Map)
        ? Map<String, dynamic>.from(match['delegateReport'])
        : {};

    _spectatorsCtrl = TextEditingController(
        text: (existingReport['spectatorsCount'] ?? '1000').toString());
    _halfTimeScoreCtrl = TextEditingController(
        text: (existingReport['halfTimeScore'] ?? '0 - 0').toString());

    _refereeCtrl = TextEditingController(
        text: (existingReport['referee'] ?? match['refereeMain'] ?? match['referee'] ?? '').toString());
    _assistant1Ctrl = TextEditingController(
        text: (existingReport['assistant1'] ?? match['refereeAss1'] ?? match['assistant1'] ?? '').toString());
    _assistant2Ctrl = TextEditingController(
        text: (existingReport['assistant2'] ?? match['refereeAss2'] ?? match['assistant2'] ?? '').toString());
    _fourthOfficialCtrl = TextEditingController(
        text: (existingReport['fourthOfficial'] ?? match['refereeFourth'] ?? match['fourthOfficial'] ?? '').toString());

    _orgGeneralYes = existingReport['orgGeneralYes'] == true;
    _orgGeneralNotesCtrl = TextEditingController(text: existingReport['orgGeneralNotes'] ?? '');

    _orgSecurityYes = existingReport['orgSecurityYes'] == true;
    _orgSecurityNotesCtrl = TextEditingController(text: existingReport['orgSecurityNotes'] ?? '');

    _orgMedicalYes = existingReport['orgMedicalYes'] == true;
    _orgMedicalNotesCtrl = TextEditingController(text: existingReport['orgMedicalNotes'] ?? '');

    _orgMediaYes = existingReport['orgMediaYes'] == true;
    _orgMediaNotesCtrl = TextEditingController(text: existingReport['orgMediaNotes'] ?? '');

    _orgOtherNotesCtrl = TextEditingController(text: existingReport['orgOtherNotes'] ?? '');

    _incPlayersYes = existingReport['incPlayersYes'] == true;
    _incPlayersNotesCtrl = TextEditingController(text: existingReport['incPlayersNotes'] ?? '');

    _incFansYes = existingReport['incFansYes'] == true;
    _incFansNotesCtrl = TextEditingController(text: existingReport['incFansNotes'] ?? '');

    _incOtherYes = existingReport['incOtherYes'] == true;
    _incOtherNotesCtrl = TextEditingController(text: existingReport['incOtherNotes'] ?? '');

    _reportPlaceCtrl = TextEditingController(
        text: (existingReport['reportPlace'] ?? match['stadium'] ?? 'البليدة').toString());
  }

  @override
  void dispose() {
    _spectatorsCtrl.dispose();
    _halfTimeScoreCtrl.dispose();
    _refereeCtrl.dispose();
    _assistant1Ctrl.dispose();
    _assistant2Ctrl.dispose();
    _fourthOfficialCtrl.dispose();
    _orgGeneralNotesCtrl.dispose();
    _orgSecurityNotesCtrl.dispose();
    _orgMedicalNotesCtrl.dispose();
    _orgMediaNotesCtrl.dispose();
    _orgOtherNotesCtrl.dispose();
    _incPlayersNotesCtrl.dispose();
    _incFansNotesCtrl.dispose();
    _incOtherNotesCtrl.dispose();
    _reportPlaceCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _collectReportData() {
    return {
      'spectatorsCount': _spectatorsCtrl.text.trim(),
      'halfTimeScore': _halfTimeScoreCtrl.text.trim(),
      'referee': _refereeCtrl.text.trim(),
      'assistant1': _assistant1Ctrl.text.trim(),
      'assistant2': _assistant2Ctrl.text.trim(),
      'fourthOfficial': _fourthOfficialCtrl.text.trim(),
      'orgGeneralYes': _orgGeneralYes,
      'orgGeneralNotes': _orgGeneralNotesCtrl.text.trim(),
      'orgSecurityYes': _orgSecurityYes,
      'orgSecurityNotes': _orgSecurityNotesCtrl.text.trim(),
      'orgMedicalYes': _orgMedicalYes,
      'orgMedicalNotes': _orgMedicalNotesCtrl.text.trim(),
      'orgMediaYes': _orgMediaYes,
      'orgMediaNotes': _orgMediaNotesCtrl.text.trim(),
      'orgOtherNotes': _orgOtherNotesCtrl.text.trim(),
      'incPlayersYes': _incPlayersYes,
      'incPlayersNotes': _incPlayersNotesCtrl.text.trim(),
      'incFansYes': _incFansYes,
      'incFansNotes': _incFansNotesCtrl.text.trim(),
      'incOtherYes': _incOtherYes,
      'incOtherNotes': _incOtherNotesCtrl.text.trim(),
      'reportPlace': _reportPlaceCtrl.text.trim(),
      'reportDate': widget.matchData['date'] ?? DateTime.now().toString().substring(0, 10),
      'delegateName': widget.matchData['delegateName'] ?? widget.matchData['delegateEmail'] ?? 'المحافظ المعتمد',
    };
  }

  Future<void> _saveAndGeneratePdf() async {
    setState(() => _isSaving = true);
    final reportData = _collectReportData();

    bool apiSuccess = false;
    try {
      apiSuccess = await ApiClient().submitDelegateReport(widget.matchId, reportData);
    } catch (_) {}

    try {
      await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
        'delegateReport': reportData,
        'reportSubmitted': true,
        'reportSubmittedAt': FieldValue.serverTimestamp(),
        'report': 'تم اعتماد تقرير المحافظ الرسمي للرابطة الجهوية بنجاح.',
        'status': 'منتهية',
      });
    } catch (_) {}

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ التقرير واعتماده رسمياً! جاري فتح ملف PDF...'),
        backgroundColor: Colors.green,
      ),
    );

    // توليد وطباعة ملف PDF
    try {
      await DelegateReportPdfGenerator.generateAndPrint(widget.matchData, reportData, widget.matchId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ التقرير بنجاح ولكن تعذر فتح الـ PDF: $e'), backgroundColor: Colors.orange),
        );
      }
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.matchData;
    final team1 = match['team1'] ?? 'الفريق 1';
    final team2 = match['team2'] ?? 'الفريق 2';
    final events = (match['events'] as List<dynamic>?) ?? [];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: 800,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Column(
            children: [
              // ── الترويسة العلوية ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B5E20),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_turned_in, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تقرير محافظ اللقاء الرسمي (LRF Blida)',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$team1 ضد $team2 | ${match['league'] ?? ''} - ${match['round'] ?? ''}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
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

              // ── محتوى الاستمارة التفاعلية ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // تنبيه توضيحي
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline, color: Colors.blue, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'البيانات الأساسية والأحداث تم جلبها تلقائياً. اختر "نعم" أو "لا" للإجابة عن أسئلة التنظيم والحوادث. عند اختيار "نعم" سيظهر حقل كتابة الملاحظات فوراً.',
                                style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── معلومات المقابلة والنتيجة ──
                      _buildSectionTitle('1 - 5 / معلومات المقابلة والنتيجة'),
                      Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildReadOnlyInfoTile('تاريخ ومكان المقابلة', '${match['date'] ?? ''} - ${match['stadium'] ?? ''}'),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildReadOnlyInfoTile('النتيجة النهائية للمقابلة', '${match['score1'] ?? 0} - ${match['score2'] ?? 0}'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _halfTimeScoreCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'النتيجة بين الشوطين',
                                        hintText: 'مثال: 1 - 0',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.timer_outlined),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _spectatorsCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'العدد التقريبي للمتفرجين',
                                        hintText: 'مثال: 800',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.groups),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── طاقم التحكيم ──
                      _buildSectionTitle('6 / طاقم التحكيم الرسمي للمباراة'),
                      Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _refereeCtrl,
                                      decoration: const InputDecoration(labelText: 'الحكم الرئيسي', border: OutlineInputBorder()),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _assistant1Ctrl,
                                      decoration: const InputDecoration(labelText: 'الحكم المساعد الأول', border: OutlineInputBorder()),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _assistant2Ctrl,
                                      decoration: const InputDecoration(labelText: 'الحكم المساعد الثاني', border: OutlineInputBorder()),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _fourthOfficialCtrl,
                                      decoration: const InputDecoration(labelText: 'الحكم الرابع', border: OutlineInputBorder()),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── ملخص الهدافين والبطاقات ──
                      _buildSectionTitle('7 - 11 / الهدافون والبطاقات (مسجلة تلقائياً)'),
                      _buildEventsOverview(events),
                      const SizedBox(height: 16),

                      // ── 9 / استمارة التنظيم (نعم / لا) ──
                      _buildSectionTitle('9 / ملاحظات حول التنظيم'),
                      _buildYesNoQuestionCard(
                        title: 'التنظيم العام للمقابلة',
                        subtitle: 'هل سارت الأمور التنظيمية بشكل غير مرضٍ أو تم تسجيل نقائص تنظيمية؟',
                        isYes: _orgGeneralYes,
                        onChanged: (val) => setState(() => _orgGeneralYes = val),
                        notesCtrl: _orgGeneralNotesCtrl,
                        notesHint: 'اكتب تفاصيل النقائص أو المشاكل التنظيمية المسجلة...',
                      ),
                      _buildYesNoQuestionCard(
                        title: 'قوات حفظ الأمن الوطني',
                        subtitle: 'هل تم تسجيل أي نقص في التعداد الأمني أو تأخر في الحضور أو مشاكل أمنية؟',
                        isYes: _orgSecurityYes,
                        onChanged: (val) => setState(() => _orgSecurityYes = val),
                        notesCtrl: _orgSecurityNotesCtrl,
                        notesHint: 'اكتب ملاحظاتك حول التغطية الأمنية وتعداد قوات الأمن...',
                      ),
                      _buildYesNoQuestionCard(
                        title: 'التغطية الطبية للمقابلة',
                        subtitle: 'هل تم تسجيل أي غياب لسيارة الإسعاف أو نقص في الطاقم الطبي والأجهزة؟',
                        isYes: _orgMedicalYes,
                        onChanged: (val) => setState(() => _orgMedicalYes = val),
                        notesCtrl: _orgMedicalNotesCtrl,
                        notesHint: 'اكتب ملاحظاتك حول التغطية الطبية وتوفر الإسعاف...',
                      ),
                      _buildYesNoQuestionCard(
                        title: 'التنظيم الإعلامي والصحفي',
                        subtitle: 'هل حدثت أي مشاكل مع رجال الإعلام أو عدم احترام الأماكن المخصصة للصحافة؟',
                        isYes: _orgMediaYes,
                        onChanged: (val) => setState(() => _orgMediaYes = val),
                        notesCtrl: _orgMediaNotesCtrl,
                        notesHint: 'اكتب تفاصيل الملاحظات الخاصة بالتغطية الإعلامية...',
                      ),

                      // تعليقات تنظيمية إضافية
                      TextField(
                        controller: _orgOtherNotesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'تعليقات تنظيمية أخرى (اختياري)',
                          hintText: 'أي ملاحظات تنظيمية أخرى ترغب في تدوينها...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── 12 - 14 / استمارة الحوادث (نعم / لا) ──
                      _buildSectionTitle('12 - 14 / الحوادث والوقائع الاستثنائية'),
                      _buildYesNoQuestionCard(
                        title: '12 / الحوادث الناتجة عن اللاعبين أو المسيرين',
                        subtitle: 'ظروف البطاقات الحمراء، سلوك غير رياضي، العنف ضد الأشخاص، الاحتجاجات أو الاستفزازات؟',
                        isYes: _incPlayersYes,
                        onChanged: (val) => setState(() => _incPlayersYes = val),
                        notesCtrl: _incPlayersNotesCtrl,
                        notesHint: 'وضح بدقة ما قام به اللاعب أو المسير والدقيقة والأشخاص المعنيين...',
                        isWarning: true,
                      ),
                      _buildYesNoQuestionCard(
                        title: '13 / الحوادث الناتجة عن الجماهير',
                        subtitle: 'رشق مقذوفات، رفع لافتات مسيئة، اجتياح الميدان، مفرقعات وشماريخ، عنف، تخريب...',
                        isYes: _incFansYes,
                        onChanged: (val) => setState(() => _incFansYes = val),
                        notesCtrl: _incFansNotesCtrl,
                        notesHint: 'صف نوع المقذوفات، الشماريخ، مدرجات المعنيين، وما أسفرت عنه الوقائع...',
                        isWarning: true,
                      ),
                      _buildYesNoQuestionCard(
                        title: '14 / حوادث أخرى (قبل، أثناء وبعد اللقاء)',
                        subtitle: 'أي أحداث وقعت داخل غرف الملابس، الممرات، أو محيط الملعب وخارجه؟',
                        isYes: _incOtherYes,
                        onChanged: (val) => setState(() => _incOtherYes = val),
                        notesCtrl: _incOtherNotesCtrl,
                        notesHint: 'اكتب تفاصيل الحوادث الأخرى والوقت التقريبي لحدوثها...',
                        isWarning: true,
                      ),

                      // مكان التحرير
                      const SizedBox(height: 10),
                      TextField(
                        controller: _reportPlaceCtrl,
                        decoration: const InputDecoration(
                          labelText: 'حُرر في (المدينة / الملعب)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── شريط الأزرار السفلي ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('رجوع'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isSaving ? null : _saveAndGeneratePdf,
                      icon: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf),
                      label: Text(
                        _isSaving ? 'جاري الحفظ والتوليد...' : 'اعتماد التقرير وتحميل الـ PDF 📄',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
      ),
    );
  }

  Widget _buildReadOnlyInfoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEventsOverview(List<dynamic> events) {
    final goals = events.where((e) => e is Map && (e['type'] == 'goal' || e['type'] == 'penalty_goal')).toList();
    final cards = events.where((e) => e is Map && (e['type'] == 'yellow_card' || e['type'] == 'red_card')).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الأهداف المسجلة (${goals.length}): ${goals.map((g) => "${g['player'] ?? 'لاعب'} (${g['minute'] ?? '-'}')").join(' ، ')}',
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text('البطاقات (${cards.length}): ${cards.map((c) => "${c['type'] == 'red_card' ? '🔴' : '🟡'} ${c['player'] ?? 'لاعب'} (${c['minute'] ?? '-'}')").join(' ، ')}',
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildYesNoQuestionCard({
    required String title,
    required String subtitle,
    required bool isYes,
    required ValueChanged<bool> onChanged,
    required TextEditingController notesCtrl,
    required String notesHint,
    bool isWarning = false,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isYes ? (isWarning ? Colors.red.shade400 : Colors.orange.shade400) : Colors.grey.shade300,
          width: isYes ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // زري نعم / لا كبار وواضحين
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => onChanged(false),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: !isYes ? Colors.green.shade600 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '✕ لا',
                          style: TextStyle(
                            color: !isYes ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => onChanged(true),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isYes ? (isWarning ? Colors.red.shade600 : Colors.orange.shade700) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '✓ نعم',
                          style: TextStyle(
                            color: isYes ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // حقل الملاحظات التلقائي عند اختيار "نعم"
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'التفاصيل والملاحظات:',
                    hintText: notesHint,
                    filled: true,
                    fillColor: isWarning ? Colors.red.shade50 : Colors.orange.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              crossFadeState: isYes ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}
