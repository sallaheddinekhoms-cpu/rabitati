import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DelegateReportPdfGenerator {
  static Future<Uint8List> generatePdfData(
    Map<String, dynamic> matchData,
    Map<String, dynamic> reportData,
    String matchId,
  ) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    pw.MemoryImage? logoImage;
    for (final path in ['assets/images/league_logo.png', 'assets/logo.png', 'assets/images/logo.png']) {
      try {
        final bytes = await rootBundle.load(path);
        logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
        break;
      } catch (_) {}
    }

    final String delegateName = (reportData['delegateName'] ?? matchData['delegateName'] ?? matchData['delegateEmail'] ?? 'المحافظ المعتمد').toString();
    final String league = (matchData['league'] ?? reportData['league'] ?? 'الرابطة الجهوية لكرة القدم البليدة').toString();
    final String round = (matchData['round'] ?? reportData['round'] ?? 'المباراة الرسمية').toString();
    final String date = (matchData['date'] ?? reportData['date'] ?? '').toString();
    final String stadium = (matchData['stadium'] ?? reportData['stadium'] ?? 'الملعب البلدي').toString();
    final String team1 = (matchData['team1'] ?? '').toString();
    final String team2 = (matchData['team2'] ?? '').toString();

    final String spectators = (reportData['spectatorsCount'] ?? '1000').toString();
    final String scoreFinal = '${matchData['score1'] ?? 0} - ${matchData['score2'] ?? 0}';
    final String scoreHalfTime = (reportData['halfTimeScore'] ?? '0 - 0').toString();

    // الرسميون
    final String referee = (matchData['referee'] ?? reportData['referee'] ?? 'غير محدد').toString();
    final String assistant1 = (matchData['assistant1'] ?? reportData['assistant1'] ?? 'غير محدد').toString();
    final String assistant2 = (matchData['assistant2'] ?? reportData['assistant2'] ?? 'غير محدد').toString();
    final String fourthOfficial = (matchData['fourthOfficial'] ?? reportData['fourthOfficial'] ?? 'غير محدد').toString();

    // استخراج الأحداث
    final List<dynamic> events = (matchData['events'] as List<dynamic>?) ?? [];
    
    // الهدافون (من الأحداث ومن بيانات التقرير)
    final List<Map<String, dynamic>> goals = [];
    if (reportData['goals'] is List) {
      for (final g in reportData['goals']) {
        if (g is Map) goals.add(Map<String, dynamic>.from(g));
      }
    } else {
      for (final e in events) {
        if (e is Map && (e['type'] == 'goal' || e['type'] == 'penalty_goal')) {
          goals.add({
            'team': e['team'] ?? (e['teamId'] == 'team1' ? team1 : team2),
            'player': e['player'] ?? e['playerName'] ?? 'لاعب',
            'number': e['number'] ?? e['playerNumber'] ?? '-',
            'license': e['license'] ?? '-',
            'minute': e['minute'] ?? '-',
            'method': e['method'] ?? (e['type'] == 'penalty_goal' ? 'ضربة جزاء' : 'لقطة لعب'),
          });
        }
      }
    }

    // التغييرات
    final List<Map<String, dynamic>> subs = [];
    if (reportData['subs'] is List) {
      for (final s in reportData['subs']) {
        if (s is Map) subs.add(Map<String, dynamic>.from(s));
      }
    } else {
      for (final e in events) {
        if (e is Map && e['type'] == 'sub') {
          subs.add({
            'team': e['team'] ?? (e['teamId'] == 'team1' ? team1 : team2),
            'outPlayer': e['outPlayer'] ?? e['playerOut'] ?? '-',
            'inPlayer': e['inPlayer'] ?? e['playerIn'] ?? '-',
            'minute': e['minute'] ?? '-',
          });
        }
      }
    }

    // الإنذارات
    final List<Map<String, dynamic>> yellowCards = [];
    if (reportData['yellowCards'] is List) {
      for (final c in reportData['yellowCards']) {
        if (c is Map) yellowCards.add(Map<String, dynamic>.from(c));
      }
    } else {
      for (final e in events) {
        if (e is Map && e['type'] == 'yellow_card') {
          yellowCards.add({
            'team': e['team'] ?? (e['teamId'] == 'team1' ? team1 : team2),
            'player': e['player'] ?? e['playerName'] ?? '-',
            'number': e['number'] ?? e['playerNumber'] ?? '-',
            'license': e['license'] ?? '-',
            'minute': e['minute'] ?? '-',
            'reason': e['reason'] ?? 'سلوك غير رياضي / احتجاج',
          });
        }
      }
    }

    // الطرد
    final List<Map<String, dynamic>> redCards = [];
    if (reportData['redCards'] is List) {
      for (final c in reportData['redCards']) {
        if (c is Map) redCards.add(Map<String, dynamic>.from(c));
      }
    } else {
      for (final e in events) {
        if (e is Map && (e['type'] == 'red_card' || e['type'] == 'second_yellow_card')) {
          redCards.add({
            'team': e['team'] ?? (e['teamId'] == 'team1' ? team1 : team2),
            'player': e['player'] ?? e['playerName'] ?? '-',
            'number': e['number'] ?? e['playerNumber'] ?? '-',
            'license': e['license'] ?? '-',
            'minute': e['minute'] ?? '-',
            'reason': e['reason'] ?? (e['type'] == 'second_yellow_card' ? 'إنذار ثانٍ' : 'طرد مباشر'),
          });
        }
      }
    }

    // ملاحظات التنظيم
    final bool orgGeneral = reportData['orgGeneralYes'] == true;
    final String orgGeneralNotes = (reportData['orgGeneralNotes'] ?? '').toString();

    final bool orgSecurity = reportData['orgSecurityYes'] == true;
    final String orgSecurityNotes = (reportData['orgSecurityNotes'] ?? '').toString();

    final bool orgMedical = reportData['orgMedicalYes'] == true;
    final String orgMedicalNotes = (reportData['orgMedicalNotes'] ?? '').toString();

    final bool orgMedia = reportData['orgMediaYes'] == true;
    final String orgMediaNotes = (reportData['orgMediaNotes'] ?? '').toString();

    final String orgOther = (reportData['orgOtherNotes'] ?? '').toString();

    // الحوادث
    final bool incPlayers = reportData['incPlayersYes'] == true;
    final String incPlayersNotes = (reportData['incPlayersNotes'] ?? '').toString();

    final bool incFans = reportData['incFansYes'] == true;
    final String incFansNotes = (reportData['incFansNotes'] ?? '').toString();

    final bool incOther = reportData['incOtherYes'] == true;
    final String incOtherNotes = (reportData['incOtherNotes'] ?? '').toString();

    final String reportPlace = (reportData['reportPlace'] ?? stadium).toString();
    final String reportDate = (reportData['reportDate'] ?? date).toString();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 24),
        header: (pw.Context context) {
          if (context.pageNumber > 1) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.only(bottom: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('تقرير محافظ اللقاء - $team1 ضد $team2', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700)),
                    pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ),
            );
          }
          return pw.SizedBox.shrink();
        },
        build: (pw.Context context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // ── رأس الصفحة الرسمي ──
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('الـرابــطـــة الجهويــــة لكـــرة القــــدم للبليـــدة',
                              style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.green900)),
                          pw.Text('BLIDA REGIONAL FOOTBALL LEAGUE',
                              style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.blueGrey800)),
                          pw.SizedBox(height: 3),
                          pw.Text('Bab Zaouia Rue Houari Mahfoud Larbi Tbessi Blida', style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey700)),
                          pw.Text('Standard / Tél. / Fax: 028 84 54 56  |  Site: www.lrf-blida.dz', style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey700)),
                        ],
                      ),
                      if (logoImage != null)
                        pw.Container(
                          width: 48,
                          height: 48,
                          child: pw.Image(logoImage),
                        ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(thickness: 1.5, color: PdfColors.green800),
                  pw.SizedBox(height: 6),

                  // ── عنوان التقرير ──
                  pw.Center(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        border: pw.Border.all(color: PdfColors.blueGrey800, width: 1.2),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Text(
                        'تـــقــريـــر مــحـــافــــظ الــلــقـــاء',
                        style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blueGrey900),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  // اسم المحافظ
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Text('إسم و لقب المحافظ: ', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                        pw.Text(delegateName, style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.green900)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  // ── معلومات المباراة الأساسية (1 إلى 5) ──
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
                    children: [
                      pw.TableRow(
                        children: [
                          _buildFieldCell(font, fontBold, '1/ تاريخ المقابلة', date),
                          _buildFieldCell(font, fontBold, 'مكان المقابلة (الملعب)', stadium),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _buildFieldCell(font, fontBold, '2/ الفريقان', '$team1  ضد  $team2'),
                          _buildFieldCell(font, fontBold, '3/ المنافسة / الجولة', '$league - $round'),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _buildFieldCell(font, fontBold, '4/ العدد التقريبي للمتفرجين', spectators),
                          _buildFieldCell(font, fontBold, '5/ النتيجة النهائية', '$scoreFinal  (بين الشوطين: $scoreHalfTime)'),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  // ── 6/ الرسميون (الحكام) ──
                  _buildSectionHeader(fontBold, '6/ الـرسـمـيـون:'),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          _buildTableHeaderCell(fontBold, 'الحكم الرئيسي'),
                          _buildTableHeaderCell(fontBold, 'الحكم المساعد الأول'),
                          _buildTableHeaderCell(fontBold, 'الحكم المساعد الثاني'),
                          _buildTableHeaderCell(fontBold, 'الحكم الرابع'),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          _buildTableCell(font, referee),
                          _buildTableCell(font, assistant1),
                          _buildTableCell(font, assistant2),
                          _buildTableCell(font, fourthOfficial),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  // ── 7/ الهدافون ──
                  _buildSectionHeader(fontBold, '7/ الـهـدافـون (الإشارة إلى طريقة تسجيل الأهداف: إثر لقطة لعب أو عن طريق ضربة جزاء):'),
                  if (goals.isEmpty)
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                      child: pw.Center(child: pw.Text('لا توجد أهداف مسجلة في هذا اللقاء', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700))),
                    )
                  else
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(2.0),
                        1: pw.FlexColumnWidth(1.0),
                        2: pw.FlexColumnWidth(3.5),
                        3: pw.FlexColumnWidth(1.8),
                        4: pw.FlexColumnWidth(2.0),
                        5: pw.FlexColumnWidth(1.0),
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                          children: [
                            _buildTableHeaderCell(fontBold, 'الفريق'),
                            _buildTableHeaderCell(fontBold, 'رقم القميص'),
                            _buildTableHeaderCell(fontBold, 'اسم و لقب اللاعب'),
                            _buildTableHeaderCell(fontBold, 'رقم الرخصة'),
                            _buildTableHeaderCell(fontBold, 'طريقة التسجيل'),
                            _buildTableHeaderCell(fontBold, 'الدقيقة'),
                          ],
                        ),
                        ...goals.map((g) => pw.TableRow(
                              children: [
                                _buildTableCell(font, (g['team'] ?? '-').toString()),
                                _buildTableCell(font, (g['number'] ?? '-').toString()),
                                _buildTableCell(font, (g['player'] ?? '-').toString()),
                                _buildTableCell(font, (g['license'] ?? '-').toString()),
                                _buildTableCell(font, (g['method'] ?? 'لقطة لعب').toString()),
                                _buildTableCell(font, "${g['minute'] ?? '-'}'"),
                              ],
                            )),
                      ],
                    ),
                  pw.SizedBox(height: 10),

                  // ── 8/ التغييرات ──
                  _buildSectionHeader(fontBold, '8/ الـتـغـيـيـرات:'),
                  if (subs.isEmpty)
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                      child: pw.Center(child: pw.Text('لم يتم تسجيل أي تغييرات في هذا اللقاء', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700))),
                    )
                  else
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(2.0),
                        1: pw.FlexColumnWidth(3.5),
                        2: pw.FlexColumnWidth(3.5),
                        3: pw.FlexColumnWidth(1.0),
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                          children: [
                            _buildTableHeaderCell(fontBold, 'الفريق'),
                            _buildTableHeaderCell(fontBold, 'رقم اللاعب المستبدل (الخارج)'),
                            _buildTableHeaderCell(fontBold, 'رقم اللاعب البديل (الداخل)'),
                            _buildTableHeaderCell(fontBold, 'الدقيقة'),
                          ],
                        ),
                        ...subs.map((s) => pw.TableRow(
                              children: [
                                _buildTableCell(font, (s['team'] ?? '-').toString()),
                                _buildTableCell(font, (s['outPlayer'] ?? '-').toString()),
                                _buildTableCell(font, (s['inPlayer'] ?? '-').toString()),
                                _buildTableCell(font, "${s['minute'] ?? '-'}'"),
                              ],
                            )),
                      ],
                    ),
                  pw.SizedBox(height: 10),

                  // ── 9/ ملاحظات حول التنظيم ──
                  _buildSectionHeader(fontBold, '9/ مـلاحـظـات حـول الـتـنـظـيـم:'),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          _buildTableHeaderCell(fontBold, 'المجال التنظيمي'),
                          _buildTableHeaderCell(fontBold, 'ملاحظة وتوفر الشروط'),
                          _buildTableHeaderCell(fontBold, 'التفاصيل والملاحظات المدونة'),
                        ],
                      ),
                      _buildOrgRow(font, fontBold, 'التنظيم العام للمقابلة', orgGeneral, orgGeneralNotes),
                      _buildOrgRow(font, fontBold, 'قوات حفظ الأمن الوطني', orgSecurity, orgSecurityNotes),
                      _buildOrgRow(font, fontBold, 'التغطية الطبية للمقابلة', orgMedical, orgMedicalNotes),
                      _buildOrgRow(font, fontBold, 'التنظيم الإعلامي', orgMedia, orgMediaNotes),
                    ],
                  ),
                  if (orgOther.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('تعليقات تنظيمية أخرى: ', style: pw.TextStyle(font: fontBold, fontSize: 8)),
                          pw.Expanded(child: pw.Text(orgOther, style: pw.TextStyle(font: font, fontSize: 8))),
                        ],
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 10),

                  // ── 10/ الإنذارات ──
                  _buildSectionHeader(fontBold, '10/ الإنــــذارات:'),
                  if (yellowCards.isEmpty)
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                      child: pw.Center(child: pw.Text('لا توجد إنذارات مسجلة', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700))),
                    )
                  else
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(2.0),
                        1: pw.FlexColumnWidth(1.0),
                        2: pw.FlexColumnWidth(3.5),
                        3: pw.FlexColumnWidth(1.8),
                        4: pw.FlexColumnWidth(1.0),
                        5: pw.FlexColumnWidth(3.0),
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                          children: [
                            _buildTableHeaderCell(fontBold, 'الفريق'),
                            _buildTableHeaderCell(fontBold, 'رقم القميص'),
                            _buildTableHeaderCell(fontBold, 'إسم و لقب اللاعب'),
                            _buildTableHeaderCell(fontBold, 'رقم الرخصة'),
                            _buildTableHeaderCell(fontBold, 'الدقيقة'),
                            _buildTableHeaderCell(fontBold, 'سبب الإنذار'),
                          ],
                        ),
                        ...yellowCards.map((c) => pw.TableRow(
                              children: [
                                _buildTableCell(font, (c['team'] ?? '-').toString()),
                                _buildTableCell(font, (c['number'] ?? '-').toString()),
                                _buildTableCell(font, (c['player'] ?? '-').toString()),
                                _buildTableCell(font, (c['license'] ?? '-').toString()),
                                _buildTableCell(font, "${c['minute'] ?? '-'}'"),
                                _buildTableCell(font, (c['reason'] ?? '-').toString()),
                              ],
                            )),
                      ],
                    ),
                  pw.SizedBox(height: 10),

                  // ── 11/ الطرد ──
                  _buildSectionHeader(fontBold, '11/ الـــطـــرد:'),
                  if (redCards.isEmpty)
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                      child: pw.Center(child: pw.Text('لا توجد حالات طرد مسجلة', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700))),
                    )
                  else
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(2.0),
                        1: pw.FlexColumnWidth(1.0),
                        2: pw.FlexColumnWidth(3.5),
                        3: pw.FlexColumnWidth(1.8),
                        4: pw.FlexColumnWidth(1.0),
                        5: pw.FlexColumnWidth(3.0),
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                          children: [
                            _buildTableHeaderCell(fontBold, 'الفريق'),
                            _buildTableHeaderCell(fontBold, 'رقم القميص'),
                            _buildTableHeaderCell(fontBold, 'إسم و لقب اللاعب'),
                            _buildTableHeaderCell(fontBold, 'رقم الرخصة'),
                            _buildTableHeaderCell(fontBold, 'الدقيقة'),
                            _buildTableHeaderCell(fontBold, 'سبب الطرد'),
                          ],
                        ),
                        ...redCards.map((c) => pw.TableRow(
                              children: [
                                _buildTableCell(font, (c['team'] ?? '-').toString()),
                                _buildTableCell(font, (c['number'] ?? '-').toString()),
                                _buildTableCell(font, (c['player'] ?? '-').toString()),
                                _buildTableCell(font, (c['license'] ?? '-').toString()),
                                _buildTableCell(font, "${c['minute'] ?? '-'}'"),
                                _buildTableCell(font, (c['reason'] ?? '-').toString()),
                              ],
                            )),
                      ],
                    ),
                  pw.SizedBox(height: 10),

                  // ── 12/ الحوادث الناتجة عن اللاعبين ──
                  _buildSectionHeader(fontBold, '12- الـحـوادث الـنـاتـجـة عـن الـلاعـبــيـن (ظروف البطاقات الحمراء، سلوك غير رياضي، العنف، الاستفزازات... إلخ):'),
                  _buildIncidentBox(font, fontBold, incPlayers, incPlayersNotes),
                  pw.SizedBox(height: 10),

                  // ── 13/ الحوادث الناتجة عن الجماهير ──
                  _buildSectionHeader(fontBold, '13- الـحـوادث الـنـاتـجـة عـن الـجـمـاهـيـر (مقذوفات، لافتات، اجتياح الميدان، مفرقعات، عنف، تخريب... إلخ):'),
                  _buildIncidentBox(font, fontBold, incFans, incFansNotes),
                  pw.SizedBox(height: 10),

                  // ── 14/ حوادث أخرى ──
                  _buildSectionHeader(fontBold, '14- حـوادث أخـرى (قـبـل، أثـنـاء وبـعـد الـلـقـاء):'),
                  _buildIncidentBox(font, fontBold, incOther, incOtherNotes),
                  pw.SizedBox(height: 16),

                  // ── التوقيع والتاريخ ──
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blueGrey800, width: 1),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('حــــرر فـــي: $reportPlace', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                            pw.SizedBox(height: 4),
                            pw.Text('بــتــاريـــخ: $reportDate', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                            pw.SizedBox(height: 8),
                            pw.Text('تم التوثيق إلكترونياً عبر تطبيق الرابطة', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text('إمــضــاء مــحــافــظ الـمقابـلــة', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                            pw.SizedBox(height: 16),
                            pw.Text(delegateName, style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.green900)),
                            pw.Text('[ تم التأكيد والاعتماد الرقمي ]', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.blueGrey700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> generateAndPrint(
    Map<String, dynamic> matchData,
    Map<String, dynamic> reportData,
    String matchId,
  ) async {
    final pdfBytes = await generatePdfData(matchData, reportData, matchId);
    final String team1 = (matchData['team1'] ?? '').toString();
    final String team2 = (matchData['team2'] ?? '').toString();

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Rapport_Delegue_${team1}_vs_${team2}.pdf',
    );
  }

  static pw.Widget _buildSectionHeader(pw.Font fontBold, String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: const pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border(right: pw.BorderSide(color: PdfColors.green900, width: 3)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfColors.green900),
      ),
    );
  }

  static pw.Widget _buildFieldCell(pw.Font font, pw.Font fontBold, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$label: ', style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.blueGrey900)),
            pw.TextSpan(text: value, style: pw.TextStyle(font: font, fontSize: 8.5, color: PdfColors.black)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTableHeaderCell(pw.Font fontBold, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Center(
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.blueGrey900),
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(pw.Font font, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
      child: pw.Center(
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.black),
        ),
      ),
    );
  }

  static pw.TableRow _buildOrgRow(pw.Font font, pw.Font fontBold, String domain, bool hasIncident, String notes) {
    final statusText = hasIncident ? 'ملاحظة مسجلة (نعم)' : 'عادي / مرضي (لا توجد ملاحظات)';
    final statusColor = hasIncident ? PdfColors.red900 : PdfColors.green900;

    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(domain, style: pw.TextStyle(font: fontBold, fontSize: 8)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(statusText, style: pw.TextStyle(font: fontBold, fontSize: 8, color: statusColor)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(hasIncident && notes.trim().isNotEmpty ? notes : 'الظروف كانت عادية ومطابقة للمعايير',
              style: pw.TextStyle(font: font, fontSize: 8)),
        ),
      ],
    );
  }

  static pw.Widget _buildIncidentBox(pw.Font font, pw.Font fontBold, bool occurred, String details) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: occurred ? PdfColors.red300 : PdfColors.grey300),
        color: occurred ? PdfColors.red50 : PdfColors.white,
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            occurred ? 'الـحـالـة: حـدثـت وقـائـع [نـعـم]' : 'الـحـالـة: لـم تـسـجـل أي وقـائـع [لا]',
            style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: occurred ? PdfColors.red900 : PdfColors.green900),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Text(
              occurred && details.trim().isNotEmpty ? 'الـتـفـاصـيـل: $details' : 'لا تـوجـد أي حـوادث أو مـخـالـفـات تـسـتـدعـي الـتـسـجـيـل.',
              style: pw.TextStyle(font: font, fontSize: 8, color: occurred ? PdfColors.black : PdfColors.grey700),
            ),
          ),
        ],
      ),
    );
  }
}
