import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../news/presentation/pages/news_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import 'delegate_login_page.dart';
import 'disciplinary_page.dart';
import 'regulations_page.dart';
import 'referees_page.dart';
import 'forms_page.dart';
import 'about_app_page.dart';
import '../../../delegate/delegate_dashboard.dart';

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

        // 6. بوابة محافظي المباريات
        _buildAdminCard(
          context: context, 
          title: 'بوابة محافظي المباريات',
          subtitle: 'تسجيل الدخول لمحافظي ومراقبي المباريات.',
          icon: Icons.shield,
          color: const Color(0xFF1B7A36),
          onTap: () {
            if (FirebaseAuth.instance.currentUser != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => DelegateDashboard(email: FirebaseAuth.instance.currentUser!.email!)));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DelegateLoginPage()));
            }
          },
        ),

        // 7. الإعدادات والتفضيلات
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
                'رابطتي | الإصدار 1.1.0 (Beta)',
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
