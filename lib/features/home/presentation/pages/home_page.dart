import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/in_app_notification.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import 'home_tab.dart';
import '../../../competitions/presentation/pages/explore_page.dart';
import '../../../match_details/presentation/pages/results_page.dart';
import '../../../competitions/presentation/pages/standings_page.dart';
import '../../../administration/presentation/pages/administration_page.dart';
import '../../../../core/widgets/ios_install_banner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  int _unreadNotificationsCount = 0;
  int _lastReadTimestamp = 0;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  bool _isInitialLoad = true;

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
  void initState() {
    super.initState();
    _loadLastReadTimeAndListen();
  }

  Future<void> _loadLastReadTimeAndListen() async {
    final prefs = await SharedPreferences.getInstance();
    _lastReadTimestamp = prefs.getInt('last_read_notifications_timestamp') ?? 0;

    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'];
        if (timestamp is Timestamp) {
          final timeMs = timestamp.millisecondsSinceEpoch;
          if (timeMs > _lastReadTimestamp) {
            count++;
          }
        }
      }

      if (!_isInitialLoad && mounted) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data() as Map<String, dynamic>?;
            if (data != null) {
              final title = data['title'] ?? 'تنبيه جديد';
              final body = data['body'] ?? '';
              final type = data['type'] ?? 'عاجل';

              InAppNotification.show(
                context,
                title: title,
                body: body,
                type: type,
                onTap: () => _openNotificationsPage(),
              );
            }
          }
        }
      }

      _isInitialLoad = false;
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = count;
        });
      }
    });
  }

  Future<void> _openNotificationsPage() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('last_read_notifications_timestamp', now);
    _lastReadTimestamp = now;

    if (mounted) {
      setState(() {
        _unreadNotificationsCount = 0;
      });
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotificationsPage()),
      );
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appCardBackground,
        elevation: 0.5,
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
                _currentIndex == 0 ? 'الرابطة الجهوية لكرة القدم البليدة' : _titles[_currentIndex],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: context.appPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Theme Toggle Button
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: context.appPrimary,
            ),
            tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
            onPressed: () {
              context.read<ThemeCubit>().toggleTheme();
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_active, color: context.appPrimary),
                onPressed: _openNotificationsPage,
              ),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$_unreadNotificationsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          const IosInstallBanner(),
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.appCardBackground,
          border: Border(top: BorderSide(color: context.appBorder, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: context.appPrimary,
          unselectedItemColor: context.appTextSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'استكشاف'),
            BottomNavigationBarItem(icon: Icon(Icons.sports_soccer_outlined), activeIcon: Icon(Icons.sports_soccer), label: 'النتائج'),
            BottomNavigationBarItem(icon: Icon(Icons.format_list_numbered), activeIcon: Icon(Icons.format_list_numbered), label: 'الترتيب'),
            BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), activeIcon: Icon(Icons.admin_panel_settings), label: 'إدارة الرابطة'),
          ],
        ),
      ),
    );
  }
}
