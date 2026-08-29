import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';

class NewsRepository {
  final FirebaseFirestore _firestore;

  NewsRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<NewsModel>> getLiveNews() {
    return _firestore
        .collection('news')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => NewsModel.fromFirestore(doc)).toList());
  }
}