import '../../../notifications/presentation/pages/notifications_page.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'home_tab.dart';
import '../../../competitions/presentation/pages/explore_page.dart';
import '../../../match_details/presentation/pages/results_page.dart';
import '../../../competitions/presentation/pages/standings_page.dart';
import '../../../administration/presentation/pages/administration_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeTab(),
    const ExplorePage(),
    const ResultsPage(),
    const StandingsPage(),
    const AdministrationPage(),
  ];

  final List<String> _titles = [
    'الرئيسية',
    'استكشاف',
    'النتائج',
    'الترتيب',
    'إدارة الرابطة',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.multiply),
                  child: Image.asset('assets/images/league_logo_splash.jpg', fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _currentIndex == 0 ? 'رابطتي - الرابطة الجهوية لكرة القدم البليدة' : _titles[_currentIndex],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: AppColors.primaryOrange),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage()));
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.article_outlined), activeIcon: Icon(Icons.article), label: 'الأخبار'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer_outlined), activeIcon: Icon(Icons.sports_soccer), label: 'النتائج'),
          BottomNavigationBarItem(icon: Icon(Icons.format_list_numbered), activeIcon: Icon(Icons.format_list_numbered), label: 'الترتيب'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), activeIcon: Icon(Icons.admin_panel_settings), label: 'الإدارة'),
        ],
      ),
    );
  }
}