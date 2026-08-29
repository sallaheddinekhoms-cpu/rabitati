import 'news_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/news_cubit.dart';
import '../cubit/news_state.dart';
import '../../data/models/news_model.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('أحدث الأخبار', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildLiveNewsList(),
      ],
    );
  }

  Widget _buildLiveNewsList() {
    return BlocBuilder<NewsCubit, NewsState>(
      builder: (context, state) {
        if (state is NewsLoading || state is NewsInitial) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is NewsError) {
          return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
        } else if (state is NewsLoaded) {
          final newsList = state.news;
          if (newsList.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('لا توجد أخبار حالياً.', style: TextStyle(color: AppColors.textSecondary))));
          }
          return Column(
            children: newsList.map((news) {
              Color catColor = const Color(0xFF1E3A8A);
              if (news.category.contains('رسمي')) catColor = const Color(0xFFE8681A);
              if (news.category.contains('كأس')) catColor = const Color(0xFFDC2626);
              if (news.category.contains('إحصائيات')) catColor = const Color(0xFF1B7A36);

              return _buildNewsItem(
                context: context,
                news: news,
                time: _getTimeAgo(news.timestamp), 
                imgColor: catColor,
              );
            }).toList(),
          );
        }
        return const SizedBox();
      },
    );
  }
  
  String _getTimeAgo(DateTime? time) {
    if (time == null) return 'مؤخراً';
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays} أيام';
    if (diff.inHours > 0) return '${diff.inHours} ساعات';
    if (diff.inMinutes > 0) return '${diff.inMinutes} دقائق';
    return 'الآن';
  }

  Widget _buildNewsItem({required BuildContext context, required NewsModel news, required String time, required Color imgColor}) {
    final hasImage = news.imageUrl.isNotEmpty;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NewsDetailsPage(news: news))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(
              width: 110, 
              height: 95, 
              decoration: BoxDecoration(
                color: imgColor,
                image: hasImage ? DecorationImage(image: NetworkImage(news.imageUrl), fit: BoxFit.cover) : null,
              ),
              child: !hasImage ? const Center(child: Icon(Icons.newspaper, color: Colors.white54, size: 30)) : null
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(news.category, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: imgColor)),
                    const SizedBox(height: 6),
                    Text(news.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(children: [const Icon(Icons.access_time, size: 12, color: AppColors.textSecondary), const SizedBox(width: 4), Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))]),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}