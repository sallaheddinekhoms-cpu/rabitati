import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/theme_extensions.dart';

class RefereesPage extends StatelessWidget {
  const RefereesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(
          'تعيينات الحكام',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: context.appPrimary),
        ),
        centerTitle: true,
        backgroundColor: context.appCardBackground,
        elevation: 0.5,
        iconTheme: IconThemeData(color: context.appPrimary),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('referee_designations')
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
                  Icon(Icons.sports, size: 70, color: context.appTextSecondary.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد تعيينات حكام منشورة حالياً',
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
              final match = data['match'] ?? 'مباراة غير محددة';
              final league = data['league'] ?? '';
              final mainReferee = data['mainReferee'] ?? 'غير محدد';
              final assistant1 = data['assistant1'] ?? '';
              final assistant2 = data['assistant2'] ?? '';
              final fourthOfficial = data['fourthOfficial'] ?? '';
              final delegate = data['delegate'] ?? '';
              final stadium = data['stadium'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.appCardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.appBorder),
                  boxShadow: context.appCardShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              match,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: context.appTextPrimary,
                              ),
                            ),
                          ),
                          if (league.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: context.appPrimary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                league,
                                style: TextStyle(
                                  color: context.appPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (stadium.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: context.appTextSecondary),
                            const SizedBox(width: 4),
                            Text(stadium, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
                          ],
                        ),
                      ],

                      Divider(color: context.appBorder, height: 20),

                      // Referees List
                      _buildRefRow(context, 'حكم الساحة:', mainReferee, Icons.sports),
                      if (assistant1.isNotEmpty)
                        _buildRefRow(context, 'المساعد الأول:', assistant1, Icons.flag_outlined),
                      if (assistant2.isNotEmpty)
                        _buildRefRow(context, 'المساعد الثاني:', assistant2, Icons.flag_outlined),
                      if (fourthOfficial.isNotEmpty)
                        _buildRefRow(context, 'الحكم الرابع:', fourthOfficial, Icons.looks_4_outlined),
                      if (delegate.isNotEmpty)
                        _buildRefRow(context, 'محافظ اللقاء:', delegate, Icons.shield_outlined),
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

  Widget _buildRefRow(BuildContext context, String label, String name, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.appPrimary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: context.appTextSecondary, fontSize: 12.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontWeight: FontWeight.bold, color: context.appTextPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
