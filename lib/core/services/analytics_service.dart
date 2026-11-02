import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';

class AnalyticsService {
  static Future<void> trackAppOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasInstalled = prefs.getBool('analytics_has_installed') ?? false;

      if (!hasInstalled) {
        await prefs.setBool('analytics_has_installed', true);
      }

      // Refresh remote config softly in background
      ApiClient().getConfig();
    } catch (_) {}
  }
}
