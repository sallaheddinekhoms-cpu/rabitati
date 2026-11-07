import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../news/presentation/pages/news_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import 'delegate_login_page.dart';
import 'disciplinary_page.dart';
import 'regulations_page.dart';
import 'referees_page.dart';
import 'forms_page.dart';
import 'press_portal_page.dart';
import '../../../delegate/delegate_dashboard.dart';
import '../../../../core/network/api_client.dart';

class AdministrationPage extends StatelessWidget {
  const AdministrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: context.appPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'المركز الإداري والإعلامي',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appTextPrimary),
                ),
              ],
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.appCardBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.appBorder),
                ),
                child: Icon(Icons.settings_outlined, color: context.appPrimary, size: 20),
              ),
              tooltip: 'الإعدادات والتفضيلات',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'الوثائق الرسمية، العقوبات، وتعيينات الحكام الخاصة بالرابطة الجهوية البليدة.',
          style: TextStyle(fontSize: 13.5, color: context.appTextSecondary),
        ),
        const SizedBox(height: 20),

        // 1. الأخبار والمستجدات
        _buildAdminCard(
          context: context, 
          title: 'الأخبار والمستجدات',
          subtitle: 'أحدث الأخبار الرسمية وإعلانات الرابطة.',
          icon: Icons.article,
          color: const Color(0xFF1B7A36),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsPage()));
          },
        ),

        // 2. القرارات الانضباطية (العقوبات)
        _buildAdminCard(
          context: context, 
          title: 'القرارات الانضباطية (العقوبات)',
          subtitle: 'النشرة الرسمية الأسبوعية، عقوبات اللاعبين والأندية.',
          icon: Icons.gavel,
          color: Colors.red.shade700,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DisciplinaryPage()));
          },
        ),

        // 3. المناشير والقوانين الأساسية
        _buildAdminCard(
          context: context, 
          title: 'المناشير والقوانين الأساسية',
          subtitle: 'تحميل اللوائح، التعديلات القانونية، والمراسلات.',
          icon: Icons.description,
          color: Colors.blue.shade700,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RegulationsPage()));
          },
        ),

        // 4. تعيينات الحكام
        _buildAdminCard(
          context: context, 
          title: 'تعيينات الحكام',
          subtitle: 'قائمة الحكام المعينين لمباريات الجولة القادمة.',
          icon: Icons.sports,
          color: const Color(0xFF2EB85C),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RefereesPage()));
          },
        ),

        // 5. نماذج ووثائق للتحميل
        _buildAdminCard(
          context: context, 
          title: 'نماذج ووثائق للتحميل',
          subtitle: 'استمارات تسجيل اللاعبين، نماذج الطعون.',
          icon: Icons.download,
          color: const Color(0xFFE8681A),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FormsPage()));
          },
        ),

        // 6. بوابة الإعلام والصحافة (طلب الاعتماد الصحفي)
        _buildAdminCard(
          context: context, 
          title: 'بوابة الإعلام والصحافة',
          subtitle: 'طلب اعتمادات رسمية لتغطية المباريات، ومتابعة البطاقة الرقمية.',
          icon: Icons.badge,
          color: const Color(0xFF0F766E),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PressPortalPage()));
          },
        ),

        // 7. بوابة محافظي المباريات
        _buildAdminCard(
          context: context, 
          title: 'بوابة محافظي المباريات',
          subtitle: 'منصة مستقلة (PWA) للمحافظين مع إمكانية التثبيت والتحديث التلقائي.',
          icon: Icons.shield,
          color: const Color(0xFF1B7A36),
          onTap: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: const [
                          Icon(Icons.shield, color: Color(0xFF1B7A36), size: 28),
                          SizedBox(width: 10),
                          Text(
                            'بوابة محافظي ومراقبي المباريات',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'تم تخصيص منصة ويب مستقلة (PWA) للمحافظين قابلة للتثبيت على شاشة الهاتف (أندرويد وآيفون) وتعمل بالتحديث الفوري والمباشر مع نفس بيانات الدخول.',
                        style: TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final uri = Uri.parse('https://www.lrf-blida.dz/delg-app');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              final backupUri = Uri.parse('https://rabitati-f4cc1.web.app');
                              await launchUrl(backupUri, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('فتح المنصة المستقلة PWA (موصى به)', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B7A36),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final savedUser = await ApiClient().getSavedUser();
                            final firebaseUser = FirebaseAuth.instance.currentUser;
                            final email = savedUser?['email'] ?? firebaseUser?.email;
                            if (context.mounted) {
                              if (email != null && email.toString().trim().isNotEmpty) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => DelegateDashboard(email: email.toString().trim())));
                              } else {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const DelegateLoginPage()));
                              }
                            }
                          },
                          icon: const Icon(Icons.phone_android),
                          label: const Text('المتابعة عبر التطبيق'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1B7A36),
                            side: const BorderSide(color: Color(0xFF1B7A36)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // 8. الإعدادات والتفضيلات
        _buildAdminCard(
          context: context,
          title: 'الإعدادات والتفضيلات',
          subtitle: 'المظهر واللغة، الإشعارات، مسح الذاكرة، وحول التطبيق.',
          icon: Icons.settings_outlined,
          color: Colors.blueGrey.shade700,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
          },
        ),

        const SizedBox(height: 16),
        // التذييل الرسمي ورقم الإصدار
        Center(
          child: Column(
            children: [
              Text(
                'رابطتي | الإصدار 1.4.0',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.appTextSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'الرابطة الجهوية لكرة القدم البليدة © 2026',
                style: TextStyle(fontSize: 11, color: context.appTextSecondary.withOpacity(0.7)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildAdminCard({required BuildContext context, VoidCallback? onTap, required String title, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: context.appTextPrimary)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(subtitle, style: TextStyle(fontSize: 12.5, color: context.appTextSecondary)),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 15, color: context.appTextSecondary),
        onTap: onTap,
      ),
    );
  }
}
