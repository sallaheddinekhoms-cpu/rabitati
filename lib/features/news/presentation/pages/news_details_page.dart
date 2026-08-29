import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/news_model.dart';

class NewsDetailsPage extends StatelessWidget {
  final NewsModel news;
  
  const NewsDetailsPage({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    final hasImage = news.imageUrl.isNotEmpty;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('تفاصيل الخبر', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.primaryOrange),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              Image.network(
                news.imageUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: AppColors.cardBackground,
                  child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: AppColors.cardBackground,
                child: const Center(child: Icon(Icons.article, size: 80, color: AppColors.primaryOrange)),
              ),
              
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.primaryOrange.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text(news.category, style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 16),
                  Text(news.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.4)),
                  const SizedBox(height: 16),
                  if (news.timestamp != null)
                    Row(
                      children: [
                        const Icon(Icons.date_range, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text('${news.timestamp!.year}-${news.timestamp!.month}-${news.timestamp!.day}', style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  const Divider(height: 40, color: AppColors.border),
                  Text(news.content, style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}