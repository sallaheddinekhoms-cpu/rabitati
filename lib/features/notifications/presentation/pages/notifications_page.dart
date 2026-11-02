import 'package:flutter/material.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../news/data/repositories/news_repository.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text('التنبيهات والإشعارات', style: TextStyle(fontWeight: FontWeight.bold, color: context.appPrimary)),
        centerTitle: true,
        backgroundColor: context.appCardBackground,
        elevation: 0.5,
        iconTheme: IconThemeData(color: context.appPrimary),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NewsRepository().getUrgentNewsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: context.appPrimary));
          }
          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: context.appTextSecondary.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text('لا توجد تنبيهات جديدة', style: TextStyle(color: context.appTextSecondary, fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final data = items[index];
              final title = (data['title'] ?? '').toString();
              final body = (data['excerpt'] ?? data['body'] ?? data['content'] ?? '').toString();
              final type = (data['category_name'] ?? data['type'] ?? 'عاجل').toString();
              final timeStr = (data['created_at_human'] ?? data['date'] ?? '').toString();

              IconData icon = Icons.notifications;
              Color color = context.appPrimary;

              if (type.contains('عاجل')) {
                icon = Icons.warning;
                color = Colors.red;
              } else if (type.contains('إداري') || type.contains('انضباط')) {
                icon = Icons.gavel;
                color = Colors.blue.shade700;
              } else if (type.contains('رياضي') || type.contains('مباراة')) {
                icon = Icons.sports_soccer;
                color = const Color(0xFF1B7A36);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: context.appCardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.appBorder),
                  boxShadow: context.appCardShadow,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.appTextPrimary)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(body, style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                      ],
                      if (timeStr.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(timeStr, style: TextStyle(color: context.appPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
