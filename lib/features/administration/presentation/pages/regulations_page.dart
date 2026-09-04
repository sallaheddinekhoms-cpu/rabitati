import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/theme_extensions.dart';

class RegulationsPage extends StatelessWidget {
  const RegulationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(
          'المناشير والقوانين الأساسية',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: context.appPrimary),
        ),
        centerTitle: true,
        backgroundColor: context.appCardBackground,
        elevation: 0.5,
        iconTheme: IconThemeData(color: context.appPrimary),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('regulations')
            .orderBy('createdAt', descending: true)
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
                  Icon(Icons.description, size: 70, color: context.appTextSecondary.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد مناشير أو قوانين منشورة حالياً',
                    style: TextStyle(color: context.appTextSecondary, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'منشور رسمي';
              final type = data['type'] ?? 'منشور';
              final number = data['number'] ?? '';
              final date = data['date'] ?? '';
              final content = data['content'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.appCardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.appBorder),
                  boxShadow: context.appCardShadow,
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.description, color: Colors.blue, size: 24),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.appTextPrimary),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        if (type.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              type,
                              style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (number.isNotEmpty) ...[
                          Text(number, style: TextStyle(color: context.appTextSecondary, fontSize: 11.5)),
                          const SizedBox(width: 8),
                        ],
                        if (date.isNotEmpty)
                          Text(date, style: TextStyle(color: context.appTextSecondary, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  children: [
                    Divider(color: context.appBorder, height: 20),
                    if (content.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'نص المنشور / البلاغ:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: context.appPrimary, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFF9FBFA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.appBorder),
                        ),
                        child: Text(
                          content,
                          style: TextStyle(color: context.appTextPrimary, fontSize: 13.5, height: 1.6),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
