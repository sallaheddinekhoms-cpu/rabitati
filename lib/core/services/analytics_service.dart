import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static Future<void> trackAppOpen() async {
    try {
      final now = FieldValue.serverTimestamp();
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection('analytics').doc('platform_stats');

      if (kIsWeb) {
        // زيارة عبر متصفح الويب / الآيفون PWA
        await docRef.set({
          'totalWebVisits': FieldValue.increment(1),
          'lastWebVisitAt': now,
        }, SetOptions(merge: true));
      } else {
        // تطبيق الأندرويد APK المثبت على الهاتف
        final prefs = await SharedPreferences.getInstance();
        final hasInstalled = prefs.getBool('analytics_has_installed') ?? false;

        if (!hasInstalled) {
          // تثبيت لأول مرة
          await docRef.set({
            'totalApkInstalls': FieldValue.increment(1),
            'lastApkInstallAt': now,
            'totalAppOpens': FieldValue.increment(1),
            'lastAppOpenAt': now,
          }, SetOptions(merge: true));
          await prefs.setBool('analytics_has_installed', true);
        } else {
          // فتح متكرر للتطبيق
          await docRef.set({
            'totalAppOpens': FieldValue.increment(1),
            'lastAppOpenAt': now,
          }, SetOptions(merge: true));
        }
      }
    } catch (_) {
      // إخفاق صامت دون التأثير على عمل التطبيق
    }
  }
}
