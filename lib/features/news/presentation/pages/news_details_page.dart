import 'package:flutter/material.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_image.dart';
import '../../data/models/news_model.dart';

class NewsDetailsPage extends StatelessWidget {
  final NewsModel news;
  
  const NewsDetailsPage({super.key, required this.news});

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
                color: catColor.withOpacity(0.1),
                image: hasImage && getAppImageProvider(news.imageUrl) != null
                    ? DecorationImage(
                        image: getAppImageProvider(news.imageUrl)!,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasImage || getAppImageProvider(news.imageUrl) == null
                  ? Center(child: Icon(Icons.newspaper, size: 70, color: catColor.withOpacity(0.5)))
                  : null,
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

                  // نص الخبر
                  Text(
                    news.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: context.appTextPrimary,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
