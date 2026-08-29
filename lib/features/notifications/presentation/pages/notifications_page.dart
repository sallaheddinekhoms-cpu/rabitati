import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('ar', null);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التنبيهات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('لا توجد تنبيهات جديدة', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? '';
              final body = data['body'] ?? '';
              final type = data['type'] ?? 'عاجل'; // عاجل، إداري، رياضي
              
              DateTime? date;
              if (data['timestamp'] != null) {
                date = (data['timestamp'] as Timestamp).toDate();
              }
              String timeStr = date != null ? DateFormat('HH:mm - yyyy/MM/dd').format(date) : '';

              IconData icon = Icons.notifications;
              Color color = AppColors.primaryOrange;
              
              if (type == 'عاجل') { icon = Icons.warning; color = Colors.red; }
              else if (type == 'إداري') { icon = Icons.gavel; color = Colors.blue; }
              else if (type == 'رياضي') { icon = Icons.sports_soccer; color = Colors.green; }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(body, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text(timeStr, style: const TextStyle(color: AppColors.primaryOrange, fontSize: 10)),
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