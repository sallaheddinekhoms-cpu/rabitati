import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/theme_extensions.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('ar', null);
    
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text('التنبيهات والإشعارات', style: TextStyle(fontWeight: FontWeight.bold, color: context.appPrimary)),
        centerTitle: true,
        backgroundColor: context.appCardBackground,
        elevation: 0.5,
        iconTheme: IconThemeData(color: context.appPrimary),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: context.appPrimary));
          }
          final docs = snapshot.data?.docs ?? [];
          
          if (docs.isEmpty) {
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
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? '';
              final body = data['body'] ?? '';
              final type = data['type'] ?? 'عاجل';
              
              DateTime? date;
              if (data['timestamp'] != null) {
                date = (data['timestamp'] as Timestamp).toDate();
              }
              String timeStr = date != null ? DateFormat('HH:mm - yyyy/MM/dd').format(date) : '';

              IconData icon = Icons.notifications;
              Color color = context.appPrimary;
              
              if (type == 'عاجل') { icon = Icons.warning; color = Colors.red; }
              else if (type == 'إداري') { icon = Icons.gavel; color = Colors.blue.shade700; }
              else if (type == 'رياضي') { icon = Icons.sports_soccer; color = const Color(0xFF1B7A36); }

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
                      const SizedBox(height: 6),
                      Text(body, style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(timeStr, style: TextStyle(color: context.appPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
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
