import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_image.dart';
import '../cubit/news_cubit.dart';
import '../cubit/news_state.dart';
import '../../data/models/news_model.dart';
import 'news_details_page.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  String _selectedCategory = 'الكل';
  final List<String> _categories = ['الكل', 'بيان رسمي', 'قرارات', 'كأس الرابطة', 'إحصائيات'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(
          'الأخبار والمستجدات',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.appPrimary),
        ),
        centerTitle: true,
        backgroundColor: context.appCardBackground,
        elevation: 0.5,
        iconTheme: IconThemeData(color: context.appPrimary),
      ),
      body: BlocBuilder<NewsCubit, NewsState>(
        builder: (context, state) {
          if (state is NewsLoading || state is NewsInitial) {
            return Center(child: CircularProgressIndicator(color: context.appPrimary));
          } else if (state is NewsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red.withOpacity(0.6)),
                  const SizedBox(height: 12),
                  Text(state.message, style: TextStyle(color: context.appTextSecondary)),
                ],
              ),
            );
          } else if (state is NewsLoaded) {
            final allNews = state.news;
            final filteredNews = _selectedCategory == 'الكل'
                ? allNews
                : allNews.where((n) => n.category.contains(_selectedCategory)).toList();

            if (allNews.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.newspaper, size: 70, color: context.appTextSecondary.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد أخبار منشورة حالياً',
                      style: TextStyle(color: context.appTextSecondary, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // ── شريط تصنيفات الأخبار ──────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCategory = category),
                          selectedColor: context.appPrimary,
                          backgroundColor: context.appCardBackground,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : context.appTextSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? context.appPrimary : context.appBorder,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // ── الخبر البارز في المقدمة ────────────────────────────
                if (filteredNews.isNotEmpty && _selectedCategory == 'الكل') ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildFeaturedNewsCard(context, filteredNews.first),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── عنوان قائمة الأخبار ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: context.appPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedCategory == 'الكل' ? 'جميع الأخبار والبيانات' : 'أخبار: $_selectedCategory',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.appTextPrimary),
                      ),
                      const Spacer(),
                      Text(
                        '${filteredNews.length} خبر',
                        style: TextStyle(fontSize: 12, color: context.appTextSecondary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── قائمة الأخبار ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: (_selectedCategory == 'الكل' && filteredNews.length > 1
                            ? filteredNews.sublist(1)
                            : filteredNews)
                        .map((news) => _buildNewsCard(context, news))
                        .toList(),
                  ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  // ── بطاقة الخبر البارز (Hero Featured Card) ──────────────────────
  Widget _buildFeaturedNewsCard(BuildContext context, NewsModel news) {
    final hasImage = news.imageUrl.isNotEmpty;
    final timeStr = _getTimeAgo(news.timestamp);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailsPage(news: news))),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.appBorder),
          boxShadow: context.appCardShadow,
          image: hasImage && getAppImageProvider(news.imageUrl) != null
              ? DecorationImage(
                  image: getAppImageProvider(news.imageUrl)!,
                  fit: BoxFit.cover,
                )
              : null,
          color: hasImage ? null : const Color(0xFF1B7A36),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // التدرج اللوني الشفاف
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
            // محتوى الخبر البارز
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B7A36),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      news.category.isNotEmpty ? news.category : 'خبر بارز',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 13, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(timeStr, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                      const Spacer(),
                      const Text(
                        'اقرأ المزيد',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── بطاقة الخبر العادية (News Item Card) ──────────────────────────
  Widget _buildNewsCard(BuildContext context, NewsModel news) {
    final hasImage = news.imageUrl.isNotEmpty;
    final timeStr = _getTimeAgo(news.timestamp);

    Color catColor = const Color(0xFF1B7A36);
    if (news.category.contains('بيان') || news.category.contains('رسمي')) catColor = const Color(0xFF1B7A36);
    if (news.category.contains('قرارات') || news.category.contains('انضباط')) catColor = Colors.red.shade700;
    if (news.category.contains('كأس')) catColor = const Color(0xFFE8681A);
    if (news.category.contains('إحصائيات')) catColor = Colors.blue.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailsPage(news: news))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // الصورة
                Container(
                  width: 100,
                  height: 90,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    image: hasImage && getAppImageProvider(news.imageUrl) != null
                        ? DecorationImage(
                            image: getAppImageProvider(news.imageUrl)!,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !hasImage || getAppImageProvider(news.imageUrl) == null
                      ? Center(child: Icon(Icons.newspaper, color: catColor, size: 32))
                      : null,
                ),
                const SizedBox(width: 14),
                // التفاصيل
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          news.category,
                          style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        news.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.appTextPrimary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: context.appTextSecondary),
                          const SizedBox(width: 4),
                          Text(timeStr, style: TextStyle(fontSize: 11, color: context.appTextSecondary)),
                          const Spacer(),
                          Icon(Icons.arrow_forward_ios, size: 12, color: context.appTextSecondary),
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

  String _getTimeAgo(DateTime? time) {
    if (time == null) return 'مؤخراً';
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return 'منذ ${diff.inDays} أيام';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعات';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }
}
