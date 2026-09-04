import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/theme_extensions.dart';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  static const String appVersion = '1.1.0';
  static const String buildNumber = '2';
  static const String releaseDate = '3 سبتمبر 2026';

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  bool _isCheckingUpdates = false;

  Future<void> _openUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر فتح الرابط: $urlString')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء محاولة فتح الرابط')),
        );
      }
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingUpdates = true);

    try {
      // فحص إصدار السيرفر من فايربيس (app_config -> version) إن وجد
      final doc = await FirebaseFirestore.instance.collection('app_config').doc('version').get().timeout(
        const Duration(seconds: 4),
        onTimeout: () => throw Exception('timeout'),
      );

      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        setState(() => _isCheckingUpdates = false);

        String latestVersion = AboutAppPage.appVersion;
        String? downloadUrl;
        if (doc.exists && doc.data() != null) {
          latestVersion = doc.data()!['latestVersion'] ?? AboutAppPage.appVersion;
          downloadUrl = doc.data()!['downloadUrl'];
        }

        if (latestVersion != AboutAppPage.appVersion && downloadUrl != null) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.system_update, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text('تحديث جديد متوفر!'),
                ],
              ),
              content: Text('يتوفر إصدار جديد من التطبيق ($latestVersion). يرجى التحديث للحصول على أفضل تجربة.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لاحقاً')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: context.appPrimary),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openUrl(downloadUrl!);
                  },
                  child: const Text('تحميل التحديث', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.check_circle, color: Color(0xFF1B7A36)),
                  SizedBox(width: 8),
                  Text('أنت على أحدث إصدار'),
                ],
              ),
              content: Text('أنت تستخدم أحدث إصدار رسمي متوفر حالياً:\nالإصدار ${AboutAppPage.appVersion} Beta.\nلا توجد تحديثات جديدة في الوقت الحالي.'),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: context.appPrimary),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('حسناً', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCheckingUpdates = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: Color(0xFF1B7A36)),
                SizedBox(width: 8),
                Text('تطبيقك محدّث'),
              ],
            ),
            content: Text('أنت تستخدم أحدث إصدار متوفر حالياً (v${AboutAppPage.appVersion} Beta). لا توجد تحديثات جديدة.'),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: context.appPrimary),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: const Text('حول التطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: context.appCardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // الشعار الرسمي للتطبيق
            Center(
              child: Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: context.appPrimary.withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.sports_soccer, size: 54, color: context.appPrimary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'رابطتي - Rabitati',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'كل الرابطة... في تطبيق واحد',
              style: TextStyle(
                fontSize: 14,
                color: context.appPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // شارة الإصدار
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: context.appPrimary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.appPrimary.withOpacity(0.3)),
              ),
              child: const Text(
                'الإصدار ${AboutAppPage.appVersion} (نسخة تجريبية / Beta)',
                style: TextStyle(
                  color: Color(0xFF1B7A36),
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // زر التحقق من التحديثات
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: _isCheckingUpdates
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  _isCheckingUpdates ? 'جارٍ التحقق من التحديثات...' : 'التحقق من التحديثات',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _isCheckingUpdates ? null : _checkForUpdates,
              ),
            ),
            const SizedBox(height: 20),

            // بطاقة نبذة عن التطبيق
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.appCardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.appBorder),
                boxShadow: context.appCardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: context.appPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'عن التطبيق',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.appTextPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'التطبيق الرسمي التفاعلي للرابطة الجهوية لكرة القدم - البليدة (LRFB). يهدف إلى رقمنة كرة القدم الجهوية وتوفير المتابعة الحية للنتائج، جداول الترتيب، قرارات اللجان، تعيينات الحكام، وتقارير المحافظين للجمهور الرياضي والأندية.',
                    style: TextStyle(fontSize: 13.5, height: 1.6, color: context.appTextSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── بطاقة معلومات الاتصال والروابط الرسمية ─────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.appCardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.appBorder),
                boxShadow: context.appCardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.contact_support_outlined, color: context.appPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'معلومات الاتصال والروابط الرسمية',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.appTextPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // الموقع الرسمي
                  _buildContactTile(
                    context,
                    icon: Icons.language,
                    iconColor: Colors.blue,
                    title: 'الموقع الرسمي للرابطة',
                    subtitle: 'https://lrf-blida.dz',
                    onTap: () => _openUrl('https://lrf-blida.dz/index.php/ar/'),
                  ),
                  const Divider(height: 18),

                  // العنوان
                  _buildContactTile(
                    context,
                    icon: Icons.location_on_outlined,
                    iconColor: Colors.red,
                    title: 'المقر / العنوان',
                    subtitle: 'Bab Zaouia Rue Houari mahfoud Larbi Tbessi Blida',
                  ),
                  const Divider(height: 18),

                  // الهاتف
                  _buildContactTile(
                    context,
                    icon: Icons.phone_outlined,
                    iconColor: Colors.green,
                    title: 'الهاتف',
                    subtitle: '028 84 54 56',
                    onTap: () => _openUrl('tel:028845456'),
                  ),
                  const Divider(height: 18),

                  // الفاكس
                  _buildContactTile(
                    context,
                    icon: Icons.print_outlined,
                    iconColor: Colors.teal,
                    title: 'الفاكس',
                    subtitle: '028 84 54 56',
                  ),
                  const Divider(height: 18),

                  // البريد الإلكتروني
                  _buildContactTile(
                    context,
                    icon: Icons.email_outlined,
                    iconColor: Colors.orange,
                    title: 'البريد الإلكتروني',
                    subtitle: 'lrfblida2026@outlook.fr',
                    onTap: () => _openUrl('mailto:lrfblida2026@outlook.fr'),
                  ),
                  const Divider(height: 18),

                  // مواقع التواصل الاجتماعي
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: Color(0xFF1877F2)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 20),
                          label: const Text('فيسبوك', style: TextStyle(color: Color(0xFF1877F2), fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () => _openUrl('https://www.facebook.com/profile.php?id=61573454559508'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: Color(0xFFE4405F)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.camera_alt, color: Color(0xFFE4405F), size: 20),
                          label: const Text('إنستغرام', style: TextStyle(color: Color(0xFFE4405F), fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () => _openUrl('https://www.instagram.com/lrfblida_official'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // معلومات إضافية وحقوق
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.appCardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.appBorder),
                boxShadow: context.appCardShadow,
              ),
              child: Column(
                children: [
                  _buildInfoRow(context, 'الجهة المطورة', 'الرابطة الجهوية لكرة القدم البليدة'),
                  const Divider(height: 20),
                  _buildInfoRow(context, 'تاريخ الإصدار', AboutAppPage.releaseDate),
                  const Divider(height: 20),
                  _buildInfoRow(context, 'رقم البناء', 'Build ${AboutAppPage.buildNumber}'),
                  const Divider(height: 20),
                  _buildInfoRow(context, 'المنصة', 'Android / iOS (PWA) / Web'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // الحقوق المحفوظة
            Text(
              '© 2026 الرابطة الجهوية لكرة القدم البليدة (LRFB)\nجميع الحقوق محفوظة',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: context.appTextSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, {required IconData icon, required Color iconColor, required String title, required String subtitle, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: context.appTextPrimary)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.open_in_new, size: 16, color: context.appTextSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: context.appTextSecondary)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appTextPrimary)),
      ],
    );
  }
}
