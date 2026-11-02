import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_image.dart';
import '../../data/models/news_model.dart';

class NewsDetailsPage extends StatelessWidget {
  final NewsModel news;
  
  const NewsDetailsPage({super.key, required this.news});

  static Future<void> launchLink(BuildContext context, String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;

    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      try {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر فتح الرابط المطلوب')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ أثناء فتح الرابط: $e')),
          );
        }
      }
    }
  }

  /// Converts HTML content to clean readable plain text while preserving structure
  String _cleanContent(String raw) {
    if (raw.isEmpty) return '';
    var text = raw;
    // Replace breaks and paragraphs with newlines
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</tr>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</td>', caseSensitive: false), '  ');
    // Strip all remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    // Decode common HTML entities
    text = text.replaceAll('&nbsp;', ' ')
               .replaceAll('&amp;', '&')
               .replaceAll('&quot;', '"')
               .replaceAll('&apos;', "'")
               .replaceAll('&gt;', '>')
               .replaceAll('&lt;', '<');
    // Normalize consecutive blank lines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  /// Builds a RichText with clickable links for any raw URLs inside the text
  Widget _buildContentWithClickableLinks(BuildContext context, String text) {
    final urlRegex = RegExp(r'(https?://[^\s]+)', caseSensitive: false);
    final matches = urlRegex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 15,
          color: context.appTextPrimary,
          height: 1.8,
        ),
      );
    }

    final spans = <TextSpan>[];
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(
            fontSize: 15,
            color: context.appTextPrimary,
            height: 1.8,
          ),
        ));
      }

      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF059669),
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          height: 1.8,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => launchLink(context, url),
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(
          fontSize: 15,
          color: context.appTextPrimary,
          height: 1.8,
        ),
      ));
    }

    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = news.imageUrl.isNotEmpty;
    
    Color catColor = const Color(0xFF1B7A36);
    if (news.category.contains('بيان') || news.category.contains('رسمي')) catColor = const Color(0xFF1B7A36);
    if (news.category.contains('قرارات') || news.category.contains('انضباط')) catColor = Colors.red.shade700;
    if (news.category.contains('كأس')) catColor = const Color(0xFFE8681A);
    if (news.category.contains('إحصائيات')) catColor = Colors.blue.shade700;

    String dateStr = 'تاريخ النشر غير محدد';
    if (news.timestamp != null) {
      final t = news.timestamp!;
      final m = t.month.toString().padLeft(2, '0');
      final d = t.day.toString().padLeft(2, '0');
      dateStr = '${t.year}/$m/$d';
    }

    final cleanedBody = _cleanContent(news.content);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appCardBackground,
        elevation: 0.5,
        title: Text(
          'تفاصيل الخبر',
          style: TextStyle(color: context.appPrimary, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: context.appPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── بطاقة الصورة الرئيسية ─────────────────────────────
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.appBorder),
                boxShadow: context.appCardShadow,
                color: catColor.withOpacity(0.08),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? AppImage(
                      imageUrl: news.imageUrl,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      fallback: Center(child: Icon(Icons.newspaper, size: 70, color: catColor.withOpacity(0.5))),
                    )
                  : Center(child: Icon(Icons.newspaper, size: 70, color: catColor.withOpacity(0.5))),
            ),

            const SizedBox(height: 18),

            // ── بطاقة تفاصيل ومحتوى الخبر ─────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.appCardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.appBorder),
                boxShadow: context.appCardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // شريط التصنيف والتاريخ
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          news.category,
                          style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.calendar_today, size: 14, color: context.appTextSecondary),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // عنوان الخبر
                  Text(
                    news.title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                      height: 1.4,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: context.appBorder, height: 1),
                  ),

                  // نص الخبر مع الروابط القابلة للنقر
                  _buildContentWithClickableLinks(context, cleanedBody),

                  // ── بطاقة الروابط والمستندات المرفقة (إن وجدت) ─────
                  if (news.links.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF059669).withOpacity(0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.attachment_rounded, size: 20, color: Color(0xFF059669)),
                              SizedBox(width: 8),
                              Text(
                                'الروابط والمستندات المرفقة بالخبر',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...news.links.map((link) {
                            final isPdf = link.isFile || link.url.toLowerCase().endsWith('.pdf');
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => launchLink(context, link.url),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: context.appCardBackground,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: context.appBorder),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: isPdf
                                              ? Colors.red.withOpacity(0.12)
                                              : const Color(0xFF059669).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          isPdf ? Icons.picture_as_pdf_rounded : Icons.link_rounded,
                                          size: 20,
                                          color: isPdf ? Colors.red.shade700 : const Color(0xFF059669),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              link.title,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: context.appTextPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              link.url,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: context.appTextSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF059669),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Text(
                                              'فتح',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(Icons.open_in_new_rounded, size: 13, color: Colors.white),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
