import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/widgets/app_image.dart';

class NewsLinkItem {
  final String title;
  final String url;
  final bool isFile;

  NewsLinkItem({
    required this.title,
    required this.url,
    this.isFile = false,
  });

  factory NewsLinkItem.fromJson(Map<String, dynamic> json) {
    return NewsLinkItem(
      title: (json['title'] ?? 'رابط مرفق').toString(),
      url: (json['url'] ?? '').toString(),
      isFile: json['is_file'] == true || (json['url'] ?? '').toString().toLowerCase().endsWith('.pdf'),
    );
  }
}

class NewsModel {
  final String id;
  final String title;
  final String category;
  final String content;
  final String imageUrl;
  final String? filePath;
  final List<NewsLinkItem> links;
  final DateTime? timestamp;

  NewsModel({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.imageUrl,
    this.filePath,
    this.links = const [],
    this.timestamp,
  });

  factory NewsModel.fromJson(Map<String, dynamic> data) {
    DateTime? dt;
    if (data['created_at'] != null) {
      dt = DateTime.tryParse(data['created_at'].toString());
    } else if (data['date'] != null) {
      dt = DateTime.tryParse(data['date'].toString());
    }

    final rawImage = (data['image_url'] ?? data['image'] ?? data['imageUrl'] ?? '').toString();
    final file = (data['file_path'] ?? data['file_url'] ?? data['filePath'] ?? '')?.toString();

    // Parse links array
    final rawLinks = data['links'];
    List<NewsLinkItem> parsedLinks = [];
    if (rawLinks is List) {
      for (var l in rawLinks) {
        if (l is Map) {
          parsedLinks.add(NewsLinkItem.fromJson(Map<String, dynamic>.from(l)));
        } else if (l is String && l.startsWith('http')) {
          parsedLinks.add(NewsLinkItem(title: 'رابط مرفق', url: l));
        }
      }
    }

    // If filePath is set and not already in links, add it
    if (file != null && file.isNotEmpty && file != 'null') {
      if (!parsedLinks.any((item) => item.url == file)) {
        parsedLinks.add(NewsLinkItem(title: 'تحميل الوثيقة المرفقة (PDF)', url: file, isFile: true));
      }
    }

    return NewsModel(
      id: data['id']?.toString() ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? 'عام',
      content: data['content'] ?? data['summary'] ?? '',
      imageUrl: resolveFullImageUrl(rawImage),
      filePath: (file != null && file.isNotEmpty && file != 'null') ? file : null,
      links: parsedLinks,
      timestamp: dt,
    );
  }

  factory NewsModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final rawImage = (data['imageUrl'] ?? data['image'] ?? data['image_url'] ?? '').toString();
    final file = (data['file_path'] ?? data['file_url'] ?? '')?.toString();

    return NewsModel(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? 'عام',
      content: data['content'] ?? '',
      imageUrl: resolveFullImageUrl(rawImage),
      filePath: (file != null && file.isNotEmpty && file != 'null') ? file : null,
      links: const [],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}
