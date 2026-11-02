import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/theme_extensions.dart';

class RegulationsPage extends StatefulWidget {
  const RegulationsPage({super.key});

  @override
  State<RegulationsPage> createState() => _RegulationsPageState();
}

class _RegulationsPageState extends State<RegulationsPage> {
  late Future<List<Map<String, dynamic>>> _docsFuture;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  void _loadDocs() {
    setState(() {
      _docsFuture = ApiClient().getDocuments(category: 'reglements');
    });
  }

  String _sanitizeFileUrl(String raw) {
    String url = raw.trim();
    if (url.startsWith('/')) {
      url = 'https://lrf-blida.dz$url';
    }
    url = url.replaceAll(RegExp(r'^https?://(localhost(:\d+)?|127\.0\.0\.1(:\d+)?)', caseSensitive: false), 'https://lrf-blida.dz');
    if (url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  Future<void> _openFile(String rawUrl) async {
    final cleanUrl = _sanitizeFileUrl(rawUrl);
    final uri = Uri.parse(cleanUrl);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        final ok2 = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!ok2) {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        }
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تعذر فتح الوثيقة مباشرة: $err'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(
          'المناشير والقوانين الأساسية',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: context.appPrimary),
        ),
        centerTitle: true,
        backgroundColor: context.appCardBackground,
        elevation: 0.5,
        iconTheme: IconThemeData(color: context.appPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadDocs(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _docsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: context.appPrimary));
            }
            final docs = snapshot.data ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description, size: 70, color: context.appTextSecondary.withOpacity(0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد مناشير أو قوانين منشورة حالياً',
                      style: TextStyle(color: context.appTextSecondary, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index];
                final title = data['title'] ?? 'منشور رسمي';
                final date = data['created_at'] ?? '';
                final fileUrl = data['file_url'] ?? data['download_url'];
                final fileSize = data['file_size'] ?? '';
                final fileExt = (data['file_ext'] ?? 'PDF').toString().toUpperCase();

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.appCardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.appBorder),
                    boxShadow: context.appCardShadow,
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.description, color: Colors.blue, size: 24),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.appTextPrimary),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              fileExt,
                              style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (fileSize.isNotEmpty) ...[
                            Text(fileSize, style: TextStyle(color: context.appTextSecondary, fontSize: 11.5)),
                            const SizedBox(width: 8),
                          ],
                          if (date.isNotEmpty)
                            Text(date, style: TextStyle(color: context.appTextSecondary, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    children: [
                      Divider(color: context.appBorder, height: 20),
                      if (fileUrl != null && fileUrl.isNotEmpty) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.appPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.download, size: 20),
                            label: const Text('تحميل / معاينة الوثيقة الرسمية', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => _openFile(fileUrl),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
