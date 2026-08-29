import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfGenerator {
  static Future<void> generateAndPrintMatchSheet(Map<String, dynamic> matchData, String matchId) async {
    final pdf = pw.Document();
    
    // Fetch events
    final eventsSnapshot = await FirebaseFirestore.instance.collection('matches').doc(matchId).collection('events').orderBy('timestamp').get();
    final events = eventsSnapshot.docs.map((e) => e.data()).toList();

    // Font setup for Arabic support (using a standard font or skipping complex font injection for basic web)
    final font = await PdfGoogleFonts.cairoRegular();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('الرابطة الجهوية لكرة القدم', style: pw.TextStyle(font: font, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('ورقة المباراة الرسمية', style: pw.TextStyle(font: font, fontSize: 18)),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),
                
                // Score and Teams
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(matchData['team1'] ?? '', style: pw.TextStyle(font: font, fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: pw.BoxDecoration(border: pw.Border.all(width: 2)),
                      child: pw.Text('${matchData['score1']} - ${matchData['score2']}', style: pw.TextStyle(font: font, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Text(matchData['team2'] ?? '', style: pw.TextStyle(font: font, fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 20),
                
                // Match Info
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('القسم: ${matchData['league']} | الجولة: ${matchData['round']}', style: pw.TextStyle(font: font, fontSize: 14)),
                      pw.Text('التاريخ: ${matchData['date']} | الوقت: ${matchData['time']}', style: pw.TextStyle(font: font, fontSize: 14)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Referees
                pw.Text('طاقم التحكيم:', style: pw.TextStyle(font: font, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('حكم الساحة: ${matchData['refereeMain'] ?? 'غير محدد'}', style: pw.TextStyle(font: font, fontSize: 14)),
                pw.Text('مساعد أول: ${matchData['refereeAss1'] ?? 'غير محدد'} | مساعد ثاني: ${matchData['refereeAss2'] ?? 'غير محدد'}', style: pw.TextStyle(font: font, fontSize: 14)),
                pw.SizedBox(height: 20),
                
                // Events
                pw.Text('أحداث المباراة:', style: pw.TextStyle(font: font, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                ...events.map((e) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text('د${e['minute']} | ${e['team']} | ${e['type']} | ${e['player'] ?? ''} ${e['playerOut'] != null ? 'خروج: ${e['playerOut']} / دخول: ${e['playerIn']}' : ''}', style: pw.TextStyle(font: font, fontSize: 12)),
                  );
                }).toList(),
                
                pw.Spacer(),
                // Footer
                pw.Divider(),
                pw.Text('تم إصدار هذه الورقة إلكترونياً عبر نظام الرابطة الجهوية', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Match_Sheet_${matchData['team1']}_vs_${matchData['team2']}.pdf',
    );
  }
}