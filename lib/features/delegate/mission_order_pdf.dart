import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MissionOrderPdfGenerator {
  static Future<Uint8List> generatePdfData(Map<String, dynamic> matchData, String matchId) async {
    final pdf = pw.Document();

    pw.Font font;
    pw.Font fontBold;
    try {
      final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      final fontBoldData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
      font = pw.Font.ttf(fontData);
      fontBold = pw.Font.ttf(fontBoldData);
    } catch (_) {
      try {
        font = await PdfGoogleFonts.amiriRegular();
        fontBold = await PdfGoogleFonts.amiriBold();
      } catch (_) {
        font = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }
    }

    // Load league logo
    pw.MemoryImage? logoImage;
    try {
      final bytes = await rootBundle.load('assets/images/league_logo.png');
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      try {
        final bytes = await rootBundle.load('assets/images/logo.png');
        logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (_) {
        try {
          final bytes = await rootBundle.load('assets/logo.png');
          logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
        } catch (_) {}
      }
    }


    final String delegateName = (matchData['delegateName'] ?? matchData['delegateEmail'] ?? 'طايبي امعمر').toString();
    final String league = (matchData['league'] ?? 'الرابطة الجهوية لكرة القدم البليدة').toString();
    final String round = (matchData['round'] ?? 'المباراة الرسمية').toString();
    final String date = (matchData['date'] ?? '').toString();
    final String time = (matchData['time'] ?? '15:00').toString();
    final String stadium = (matchData['stadium'] ?? 'الملعب البلدي').toString();
    final String team1 = (matchData['team1'] ?? '').toString();
    final String team2 = (matchData['team2'] ?? '').toString();

    final String missionNumber = matchData['missionOrderNumber'] ?? '150 / ر.ج.ك.ق.ب / أ.ع / 2026 - 2027';
    final String issuedDate = matchData['missionOrderIssuedDate'] ?? (date.isNotEmpty ? date : '2026/09/16');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blueGrey900, width: 1.6),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // ── الشريط الوطني المزخرف في الأعلى ─────────────────
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          height: 3.5,
                          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF006633)),
                        ),
                      ),
                      pw.Container(
                        width: 14,
                        height: 3.5,
                        decoration: const pw.BoxDecoration(color: PdfColors.white),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          height: 3.5,
                          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFD21034)),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),

                  // ── الترويسة الرسمية (LRF Blida) ────────────────────
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // جهة النصوص
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'الـرابــطـــة الجهويــــة لكـــرة القــــدم للبليـــدة',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 15,
                              color: const PdfColor.fromInt(0xFF0B2545),
                            ),
                          ),
                          pw.SizedBox(height: 1),
                          pw.Text(
                            'LIGUE RÉGIONALE DE FOOTBALL - BLIDA',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 10,
                              color: const PdfColor.fromInt(0xFFB71C1C),
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Bab Zaouia Rue Houari Mahfoud Larbi Tbessi - Blida',
                            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey800),
                          ),
                          pw.Text(
                            'SG Tél./Fax: 028 84 54 56   |   Standard: 028 84 54 56',
                            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey800),
                          ),
                          pw.Text(
                            'Site Web: www.lrf-blida.dz',
                            style: pw.TextStyle(font: fontBold, fontSize: 8, color: const PdfColor.fromInt(0xFF0D47A1)),
                          ),
                        ],
                      ),
                      // شعار الرابطة الرسمي
                      if (logoImage != null)
                        pw.Container(
                          width: 58,
                          height: 58,
                          child: pw.Image(logoImage),
                        ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Divider(thickness: 1.2, color: PdfColors.blueGrey700),
                  pw.SizedBox(height: 10),

                  // ── عنوان الوثيقة الرسمي ──────────────────────────
                  pw.Center(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: PdfColors.blueGrey800, width: 1.2),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'أَمْـــــــــر بِمَهِمَّــــــــة',
                            style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfColors.black),
                          ),
                          pw.Text(
                            'ORDRE DE MISSION',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 9.5,
                              color: PdfColors.blueGrey700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // ── رقم الإرسال والتاريخ ─────────────────────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'رقم: $missionNumber',
                        style: pw.TextStyle(font: fontBold, fontSize: 10.5, color: PdfColors.black),
                      ),
                      pw.Text(
                        'البليدة في: $issuedDate',
                        style: pw.TextStyle(font: fontBold, fontSize: 10.5, color: PdfColors.black),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  // ── بيانات المحافظ والتكليف ─────────────────────────
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFF9FAFB),
                      borderRadius: pw.BorderRadius.circular(5),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoLine(font, fontBold, 'السيد', delegateName),
                        pw.SizedBox(height: 4.5),
                        _buildInfoLine(font, fontBold, 'الصفة', 'محافظ اللقاء'),
                        pw.SizedBox(height: 4.5),
                        _buildInfoLine(font, fontBold, 'المنافسة', '$league ($round)'),
                        pw.SizedBox(height: 4.5),
                        _buildInfoLine(
                          font,
                          fontBold,
                          'العنوان الإداري',
                          'الرابطة الجهوية لكرة القدم البليدة / باب الزاوية شارع هواري محفوظ العربي التبسي البليدة',
                        ),
                        pw.SizedBox(height: 4.5),
                        _buildInfoLine(font, fontBold, 'وسائل النقل', 'كل الوسائل المتاحة'),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // ── جملة التكليف ──────────────────────────────────
                  pw.Text(
                    'بموجب هذا الأمر يكلف المعني بالإشراف على المباراة كما يلي:',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 11,
                      color: const PdfColor.fromInt(0xFF0B2545),
                    ),
                  ),
                  pw.SizedBox(height: 6),

                  // ── جدول المباراة المكلف بها (RTL: من اليمين لليسار كما في taibi.pdf) ──
                  // الأعمدة من اليمين لليسار: الملعب | الموعد | التوقيت | اللقاء
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2.2), // الملعب (يمين)
                      1: const pw.FlexColumnWidth(2.4), // الموعد
                      2: const pw.FlexColumnWidth(1.5), // التوقيت
                      3: const pw.FlexColumnWidth(3.8), // اللقاء (يسار)
                    },
                    children: [
                      // رأس الجدول
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEEEEE)),
                        children: [
                          _buildTableCell(fontBold, 'الملعـــب', isHeader: true),
                          _buildTableCell(fontBold, 'الموعـــد', isHeader: true),
                          _buildTableCell(fontBold, 'التوقيت', isHeader: true),
                          _buildTableCell(fontBold, 'اللقــــاء', isHeader: true),
                        ],
                      ),
                      // بيانات المباراة
                      pw.TableRow(
                        children: [
                          _buildTableCell(fontBold, stadium, fontSize: 10),
                          _buildTableCell(fontBold, date, fontSize: 10),
                          _buildTableCell(fontBold, time, fontSize: 10),
                          _buildTableCell(fontBold, '$team1  —  $team2', fontSize: 10.5),
                        ],
                      ),
                    ],
                  ),

                  // ── التنبيه الإلزامي (متصل بالجدول كما في النموذج الرسمي) ─
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: pw.BoxDecoration(
                      border: const pw.Border(
                        left: pw.BorderSide(color: PdfColors.black, width: 1),
                        right: pw.BorderSide(color: PdfColors.black, width: 1),
                        bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                      ),
                      color: const PdfColor.fromInt(0xFFFFF9E6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'هــــام جــــداً:',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10.5,
                            color: const PdfColor.fromInt(0xFFB71C1C),
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'يتعيّن على المحافظين ومندوبي ومنسقي المباريات والحكام إرسال ورقة اللقاء وكذا التقارير إلى الرابطة الجهوية لكرة القدم البليدة، عبر البريد الإلكتروني التالي: LRFBlida2026@outlook.fr وذلك في غضون ثلاث (03) ساعات من نهاية المباراة.',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8.5,
                            color: PdfColors.black,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // ── خانة الختم والإمضاء الرسمي ────────────────────────
                  // كما في النموذج taibi.pdf: الختم والإمضاء على جهة اليسار
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // جهة اليمين: ختم التحقق والتوثيق الرقمي للرابطة
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                          borderRadius: pw.BorderRadius.circular(6),
                          color: const PdfColor.fromInt(0xFFFAFAFA),
                        ),
                        child: pw.Row(
                          children: [
                            pw.BarcodeWidget(
                              barcode: pw.Barcode.qrCode(),
                              data: 'LRFB-MISSION-$matchId-$missionNumber',
                              width: 44,
                              height: 44,
                            ),
                            pw.SizedBox(width: 8),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'الجمهورية الجزائرية الديمقراطية الشعبية',
                                  style: pw.TextStyle(font: fontBold, fontSize: 6.5, color: PdfColors.blueGrey800),
                                ),
                                pw.Text(
                                  'الاتحاد الجزائري لكرة القدم (FAF)',
                                  style: pw.TextStyle(font: font, fontSize: 6, color: PdfColors.grey700),
                                ),
                                pw.Text(
                                  'وثيقة تكليف رسمية صادرة ومؤمنة رقمياً',
                                  style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 6.5,
                                    color: const PdfColor.fromInt(0xFF006633),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // جهة اليسار: رئيس الرابطة رشيد حمري
                      pw.Container(
                        width: 190,
                        padding: const pw.EdgeInsets.symmetric(vertical: 6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              'رئيس الرابطة',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 14,
                                color: const PdfColor.fromInt(0xFF0B2545),
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              'رشيد حمري',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 16,
                                color: PdfColors.black,
                              ),
                            ),
                            pw.SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.Spacer(),

                  // ── تسهيل المهمة من السلطات المدنية والعسكرية ───────
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFF3F4F6),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'يتعين على السلطات المدنية والعسكرية تسهيل ومساعدة وتقديم يد العون لحامل أمر المهمة هذا',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 9.5,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Divider(thickness: 0.8, color: PdfColors.blueGrey800),
                  pw.SizedBox(height: 2),

                  // ── تذييل الوثيقة (العنوان وحساب البنك) ──────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'العنوان: باب الزاوية شارع هواري محفوظ العربي التبسي - البليدة',
                        style: pw.TextStyle(font: font, fontSize: 7.8, color: PdfColors.grey800),
                      ),
                      pw.Text(
                        'N° Compte CPA : 00400 10641815511 94',
                        style: pw.TextStyle(font: fontBold, fontSize: 7.8, color: PdfColors.blueGrey900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> generateAndPrint(Map<String, dynamic> matchData, String matchId) async {
    final pdfBytes = await generatePdfData(matchData, matchId);
    final String delegateName = (matchData['delegateName'] ?? 'المحافظ').toString();
    final String team1 = (matchData['team1'] ?? '').toString();
    final String team2 = (matchData['team2'] ?? '').toString();
    final fileName = 'Ordre_De_Mission_${delegateName}_${team1}_vs_$team2.pdf';

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: fileName,
      );
    } catch (_) {
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    }
  }

  static Future<void> downloadPdf(Map<String, dynamic> matchData, String matchId) async {
    final pdfBytes = await generatePdfData(matchData, matchId);
    final String delegateName = (matchData['delegateName'] ?? 'المحافظ').toString();
    final String team1 = (matchData['team1'] ?? '').toString();
    final String team2 = (matchData['team2'] ?? '').toString();
    final fileName = 'Ordre_De_Mission_${delegateName}_${team1}_vs_$team2.pdf';

    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  static pw.Widget _buildInfoLine(pw.Font font, pw.Font fontBold, String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('- $label: ', style: pw.TextStyle(font: fontBold, fontSize: 10.5, color: const PdfColor.fromInt(0xFF1F2937))),
        pw.Expanded(
          child: pw.Text(value, style: pw.TextStyle(font: font, fontSize: 10.5, color: PdfColors.black)),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(pw.Font font, String text, {bool isHeader = false, double fontSize = 9.5}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Center(
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: font,
            fontSize: fontSize,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: isHeader ? const PdfColor.fromInt(0xFF0B2545) : PdfColors.black,
          ),
        ),
      ),
    );
  }
}
