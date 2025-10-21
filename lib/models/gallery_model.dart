import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryModel {
  final String id;
  final String userId;
  final String imageUrl;
  final String name;
  final String caption;
  final DateTime timestamp;

  GalleryModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.name,
    required this.caption,
    required this.timestamp,
  });

  factory GalleryModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parsedDate;

    final ts = data['timestamp'];
    if (ts is Timestamp) {
      parsedDate = ts.toDate();
    } else if (ts is DateTime) {
      parsedDate = ts;
    } else if (ts is String) {
      parsedDate = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return GalleryModel(
      id: id,
      userId: (data['userId'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      name: (data['name'] ?? 'Untitled').toString(),
      caption: (data['caption'] ?? 'No caption').toString(),
      timestamp: parsedDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'name': name,
      'caption': caption,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
