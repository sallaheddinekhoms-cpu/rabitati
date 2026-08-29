import 'package:cloud_firestore/cloud_firestore.dart';

class NewsModel {
  final String id;
  final String title;
  final String category;
  final String content;
  final String imageUrl;
  final DateTime? timestamp;

  NewsModel({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.imageUrl,
    this.timestamp,
  });

  factory NewsModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NewsModel(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? 'عام',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}