import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../news/presentation/pages/news_page.dart';
import 'delegate_login_page.dart';
import '../../../delegate/delegate_dashboard.dart';

class AdministrationPage extends StatelessWidget {
  const AdministrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'المركز الإداري والإعلامي',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'الوثائق الرسمية، العقوبات، وتعيينات الحكام الخاصة برابطة ما بين الجهات.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        _buildAdminCard(context: context, 
          title: 'الأخبار والمستجدات',
          subtitle: 'أحدث الأخبار الرسمية وإعلانات الرابطة.',
          icon: Icons.article,
          color: AppColors.primaryOrange,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsPage()));
          },
        ),
        _buildAdminCard(context: context, 
          title: 'القرارات الانضباطية (العقوبات)',
          subtitle: 'النشرة الرسمية الأسبوعية، عقوبات اللاعبين والأندية.',
          icon: Icons.gavel,
          color: Colors.red,
        ),
        _buildAdminCard(context: context, 
          title: 'المناشير والقوانين الأساسية',
          subtitle: 'تحميل اللوائح، التعديلات القانونية، والمراسلات.',
          icon: Icons.description,
          color: Colors.blue,
        ),
        _buildAdminCard(context: context, 
          title: 'تعيينات الحكام',
          subtitle: 'قائمة الحكام المعينين لمباريات الجولة القادمة.',
          icon: Icons.sports,
          color: Colors.green,
        ),
        _buildAdminCard(context: context, 
          title: 'نماذج ووثائق للتحميل',
          subtitle: 'استمارات تسجيل اللاعبين، نماذج الطعون.',
          icon: Icons.download,
          color: AppColors.primaryOrange,
        ),
        _buildAdminCard(
          context: context,
          title: 'بوابة محافظي المباريات',
          subtitle: 'تسجيل الدخول لمحافظي ومراقبي المباريات.',
          icon: Icons.shield,
          color: Colors.purple,
          onTap: () {
            if (FirebaseAuth.instance.currentUser != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => DelegateDashboard(email: FirebaseAuth.instance.currentUser!.email!)));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DelegateLoginPage()));
            }
          },
        ),
      ],
    );
  }

  Widget _buildAdminCard({BuildContext? context, VoidCallback? onTap, required String title, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}