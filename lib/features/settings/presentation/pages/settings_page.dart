import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/club_logo_widget.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../favorites/presentation/pages/select_favorite_team_page.dart';
import '../../../administration/presentation/pages/about_app_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'ar';
  bool _notifyMatches = true;
  bool _notifyDecisions = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('app_language') ?? 'ar';
      _notifyMatches = prefs.getBool('notify_matches') ?? true;
      _notifyDecisions = prefs.getBool('notify_decisions') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', langCode);
    setState(() => _selectedLanguage = langCode);

    if (mounted) {
      if (langCode == 'fr') {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Text('🇫🇷 Français'),
              ],
            ),
            content: const Text(
              'La langue française a été sélectionnée comme préférence. La traduction complète de l''ensemble des rubriques sera déployée dans la version v1.2.0.',
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: context.appPrimary),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('D''accord', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعيين اللغة العربية كلغة افتراضية للتطبيق'), backgroundColor: Color(0xFF1B7A36)),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('مسح الذاكرة المؤقتة'),
        content: const Text('هل ترغب في تفريغ ذاكرة التخزين المؤقت لشعارات الأندية والصور المحفوظة؟ سيتم إعادة تحميلها تلقائياً عند الحاجة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('مسح الذاكرة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_club_logos');
      await TeamLogoService.init();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم مسح الذاكرة المؤقتة بنجاح وتفريغ المساحة!'), backgroundColor: Color(0xFF1B7A36)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;
    final favorites = context.watch<FavoritesCubit>().state;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: const Text('الإعدادات والتفضيلات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: context.appCardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: context.appPrimary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── 1. قسم المظهر واللغة ─────────────────────────
                _buildSectionHeader(context, 'المظهر واللغة', Icons.palette_outlined),
                Container(
                  decoration: BoxDecoration(
                    color: context.appCardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.appBorder),
                    boxShadow: context.appCardShadow,
                  ),
                  child: Column(
                    children: [
                      // الوضع الليلي
                      SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.appPrimary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: context.appPrimary, size: 22),
                        ),
                        title: Text('الوضع الليلي (Dark Mode)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: context.appTextPrimary)),
                        subtitle: Text(isDark ? 'مفعّل حالياً' : 'معطّل (الوضع النهاري)', style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
                        value: isDark,
                        activeColor: context.appPrimary,
                        onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                      ),
                      Divider(height: 1, color: context.appBorder),
                      // لغة التطبيق
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.language, color: Colors.blue, size: 22),
                        ),
                        title: Text('لغة التطبيق / Langue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: context.appTextPrimary)),
                        subtitle: Text(_selectedLanguage == 'ar' ? 'العربية (افتراضي)' : 'Français (v1.2.0)', style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
                        trailing: DropdownButton<String>(
                          value: _selectedLanguage,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'ar', child: Text('🇩🇿 العربية')),
                            DropdownMenuItem(value: 'fr', child: Text('🇫🇷 Français')),
                          ],
                          onChanged: (val) {
                            if (val != null) _saveLanguage(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── 2. قسم الإشعارات والتنبيهات ─────────────────
                _buildSectionHeader(context, 'الإشعارات والتنبيهات', Icons.notifications_outlined),
                Container(
                  decoration: BoxDecoration(
                    color: context.appCardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.appBorder),
                    boxShadow: context.appCardShadow,
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sports_soccer, color: Colors.green, size: 22),
                        ),
                        title: Text('تنبيهات المباريات والأهداف المباشرة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary)),
                        subtitle: Text('إشعارات فورية عند تسجيل هدف أو بداية مباراة', style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
                        value: _notifyMatches,
                        activeColor: context.appPrimary,
                        onChanged: (val) async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('notify_matches', val);
                          setState(() => _notifyMatches = val);
                        },
                      ),
                      Divider(height: 1, color: context.appBorder),
                      SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.gavel, color: Colors.red, size: 22),
                        ),
                        title: Text('تنبيهات القرارات الانضباطية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary)),
                        subtitle: Text('إشعار فوري عند صدور النشرة الرسمية والعقوبات', style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
                        value: _notifyDecisions,
                        activeColor: context.appPrimary,
                        onChanged: (val) async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('notify_decisions', val);
                          setState(() => _notifyDecisions = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── 3. النادي المفضل ────────────────────────────
                _buildSectionHeader(context, 'النادي المفضل', Icons.star_border),
                Container(
                  decoration: BoxDecoration(
                    color: context.appCardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.appBorder),
                    boxShadow: context.appCardShadow,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star, color: Colors.amber, size: 24),
                    ),
                    title: Text(
                      favorites.isEmpty ? 'لم يتم تحديد فريق مفضل بعد' : 'فرقك المفضلة: ${favorites.join('، ')}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('يتم تثبيت مباريات فرقك المفضلة دائماً في أعلى النتائج', style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.appPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectFavoriteTeamPage()));
                      },
                      child: const Text('تعديل', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── 4. إدارة البيانات والمساحة ──────────────────
                _buildSectionHeader(context, 'إدارة الذاكرة المؤقتة', Icons.cleaning_services_outlined),
                Container(
                  decoration: BoxDecoration(
                    color: context.appCardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.appBorder),
                    boxShadow: context.appCardShadow,
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_sweep_outlined, color: Colors.orange, size: 22),
                    ),
                    title: Text('مسح الذاكرة المؤقتة (Clear Cache)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appTextPrimary)),
                    subtitle: Text('تفريغ كاش شعارات الأندية وإعادة تنزيل أحدث الشعارات', style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
                    trailing: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.appBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _clearCache,
                      child: const Text('مسح', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── 5. حول التطبيق والمعلومات الرسمية ────────────
                _buildSectionHeader(context, 'معلومات التطبيق', Icons.info_outline),
                Container(
                  decoration: BoxDecoration(
                    color: context.appCardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.appBorder),
                    boxShadow: context.appCardShadow,
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.app_registration, color: Colors.teal, size: 22),
                    ),
                    title: Text('حول التطبيق (v1.1.0 Beta)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: context.appTextPrimary)),
                    subtitle: Text('التحقق من التحديثات، معلومات الاتصال بالرابطة والحقوق', style: TextStyle(fontSize: 12, color: context.appTextSecondary)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 15, color: context.appTextSecondary),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppPage()));
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // التذييل
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
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.appPrimary),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appPrimary),
          ),
        ],
      ),
    );
  }
}
