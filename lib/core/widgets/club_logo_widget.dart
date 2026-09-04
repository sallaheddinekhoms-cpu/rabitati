import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_extensions.dart';

// ── خدمة الكاش والبحث التلقائي عن شعارات الأندية ────────────
class TeamLogoService {
  static final TeamLogoService _instance = TeamLogoService._internal();
  factory TeamLogoService() => _instance;

  static final Map<String, String> _logoCache = {};
  static final ValueNotifier<int> updatesNotifier = ValueNotifier(0);
  static bool _initialized = false;

  TeamLogoService._internal() {
    init();
  }

  // تسوية وتوحيد الحروف والهمزات العربية لضمان المطابقة 100%
  static String normalizeName(String name) {
    String n = name.trim().toLowerCase();
    n = n.replaceAll(RegExp(r'[إأآا]'), 'ا');
    n = n.replaceAll(RegExp(r'[ة]'), 'ه');
    n = n.replaceAll(RegExp(r'[ى]'), 'ي');
    n = n.replaceAll(RegExp(r'[\u064B-\u0652]'), '');
    n = n.replaceAll(RegExp(r'\s+'), ' ');
    return n;
  }

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1. استرجاع فوري من الذاكرة المحلية للجهاز بدون أي تأخير (0ms)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_club_logos');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(cachedJson);
        decoded.forEach((key, val) {
          if (val is String && val.isNotEmpty) {
            _logoCache[key] = val;
          }
        });
        updatesNotifier.value++;
      }
    } catch (_) {}

    // 2. تحميل فوري وسريع ومباشر من فايرستور
    _fetchFromFirestore();

    // 3. الاستماع التلقائي لأي تحديثات جديدة
    FirebaseFirestore.instance.collection('standings').snapshots().listen((snapshot) {
      _processSnapshot(snapshot.docs);
    });

    FirebaseFirestore.instance.collection('clubs').snapshots().listen((snapshot) {
      _processSnapshot(snapshot.docs);
    });
  }

  static Future<void> _fetchFromFirestore() async {
    try {
      final standingsSnap = await FirebaseFirestore.instance.collection('standings').get();
      _processSnapshot(standingsSnap.docs);

      final clubsSnap = await FirebaseFirestore.instance.collection('clubs').get();
      _processSnapshot(clubsSnap.docs);
    } catch (_) {}
  }

  static void _processSnapshot(List<DocumentSnapshot> docs) {
    bool hasNew = false;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;
      final team = (data['team'] ?? data['name'] ?? '').toString().trim();
      final logo = (data['logoUrl'] ?? data['logo'] ?? '').toString().trim();
      if (team.isNotEmpty && logo.isNotEmpty) {
        if (_logoCache[team] != logo) {
          _logoCache[team] = logo;
          hasNew = true;
        }
      }
    }

    if (hasNew) {
      updatesNotifier.value++;
      _saveToDisk();
    }
  }

  static Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_club_logos', jsonEncode(_logoCache));
    } catch (_) {}
  }

  static String getLogo(String teamName) {
    if (teamName.isEmpty) return '';
    final trimmed = teamName.trim();
    
    // 1. مطابقة مباشرة بالاسم الصريح
    if (_logoCache.containsKey(trimmed)) {
      return _logoCache[trimmed]!;
    }

    // 2. مطابقة بعد توحيد الهمزات والياء (إتحاد -> اتحاد)
    final normTarget = normalizeName(trimmed);
    for (var entry in _logoCache.entries) {
      final normKey = normalizeName(entry.key);
      if (normKey == normTarget) {
        return entry.value;
      }
    }

    // 3. مطابقة ذكية للأسماء المركبة
    for (var entry in _logoCache.entries) {
      final normKey = normalizeName(entry.key);
      if (normKey.contains(normTarget) || normTarget.contains(normKey)) {
        return entry.value;
      }
    }

    return '';
  }
}

// ── ويدجت عرض شعار النادي عبر الاسم تلقائياً ─────────────────
class TeamLogoWidget extends StatelessWidget {
  final String teamName;
  final String? logoUrl;
  final double size;
  final Color? fallbackColor;

  const TeamLogoWidget({
    super.key,
    required this.teamName,
    this.logoUrl,
    this.size = 36,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    TeamLogoService.init();

    return ValueListenableBuilder<int>(
      valueListenable: TeamLogoService.updatesNotifier,
      builder: (context, _, __) {
        final effectiveUrl = (logoUrl != null && logoUrl!.isNotEmpty)
            ? logoUrl!
            : TeamLogoService.getLogo(teamName);

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.isDarkMode ? Colors.white12 : const Color(0xFFEAF5EE),
          ),
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          child: ClubLogoWidget(
            logoUrl: effectiveUrl,
            size: size * 0.85,
            fallbackColor: fallbackColor ?? context.appPrimary,
          ),
        );
      },
    );
  }
}

// ── ويدجت رسم الشعار من الرابط أو Base64 ──────────────────────
class ClubLogoWidget extends StatelessWidget {
  final String logoUrl;
  final double size;
  final Color? fallbackColor;

  const ClubLogoWidget({
    super.key,
    required this.logoUrl,
    this.size = 40,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = fallbackColor ?? (context.isDarkMode ? Colors.white70 : const Color(0xFF1B7A36));

    if (logoUrl.isEmpty) {
      return Icon(Icons.shield, size: size, color: color);
    }

    if (logoUrl.startsWith('data:image')) {
      try {
        final commaIndex = logoUrl.indexOf(',');
        final base64String = commaIndex != -1 ? logoUrl.substring(commaIndex + 1) : logoUrl;
        return Image.memory(
          base64Decode(base64String),
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.shield, size: size, color: color),
        );
      } catch (_) {
        return Icon(Icons.shield, size: size, color: color);
      }
    }

    return Image.network(
      logoUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.shield, size: size, color: color),
    );
  }
}
