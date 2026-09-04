import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/theme_extensions.dart';

class IosInstallBanner extends StatefulWidget {
  const IosInstallBanner({super.key});

  @override
  State<IosInstallBanner> createState() => _IosInstallBannerState();
}

class _IosInstallBannerState extends State<IosInstallBanner> {
  bool _dismissed = false;

  bool get _shouldShow {
    if (!kIsWeb || _dismissed) return false;
    return true;
  }

  void _showInstallGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: context.appCardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // شريط السحب العلوي
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // عنوان النافذة
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.appPrimary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.apple, color: context.appPrimary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تثبيت التطبيق على الآيفون',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: context.appTextPrimary,
                        ),
                      ),
                      Text(
                        'خطوات بسيطة وسريعة لتثبيت التطبيق على شاشتك الرئيسية',
                        style: TextStyle(fontSize: 12, color: context.appTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── الخطوة 1 ──────────────────────────────────────
            _buildStepItem(
              context: context,
              stepNumber: '1',
              title: 'اضغط على زر المشاركة (Share)',
              description: 'في متصفح Safari، اضغط على أيقونة المربع مع السهم للأعلى الموجودة في أسفل الشاشة.',
              icon: Icons.ios_share,
              iconColor: Colors.blue,
            ),

            const SizedBox(height: 16),

            // ── الخطوة 2 ──────────────────────────────────────
            _buildStepItem(
              context: context,
              stepNumber: '2',
              title: 'اختر "إضافة إلى الشاشة الرئيسية"',
              description: 'مرر القائمة للأسفل قليلاً واضغط على "Sur l\'écran d\'accueil" أو "Add to Home Screen".',
              icon: Icons.add_box_outlined,
              iconColor: context.appPrimary,
            ),

            const SizedBox(height: 16),

            // ── الخطوة 3 ──────────────────────────────────────
            _buildStepItem(
              context: context,
              stepNumber: '3',
              title: 'اضغط على "إضافة" (Ajouter / Add)',
              description: 'في أعلى يمين الشاشة، اضغط على إضافة وسيظهر التطبيق فوراً على شاشة هاتفك الرئيسية كأي تطبيق رسمي!',
              icon: Icons.check_circle_outline,
              iconColor: Colors.green,
            ),

            const SizedBox(height: 24),

            // زر فهمت
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'فهمت، سأقوم بالتثبيت الآن',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required BuildContext context,
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: context.appPrimary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),
                    Icon(icon, color: iconColor, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: context.appTextSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appPrimary.withOpacity(0.4), width: 1.2),
        boxShadow: context.appCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showInstallGuide(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.appPrimary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.install_mobile, color: context.appPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'تثبيت التطبيق على الآيفون 📲',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: context.appPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.appPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('اضغط لمعرفة الطريقة', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'اضغط زر المشاركة (Share) في Safari ثم "إضافة إلى الشاشة الرئيسية".',
                        style: TextStyle(fontSize: 11, color: context.appTextSecondary, height: 1.3),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: context.appTextSecondary),
                  onPressed: () => setState(() => _dismissed = true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
