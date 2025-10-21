import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getUserBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await _db
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  }

  Future<void> cancelBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({'status': 'cancelled'});
  }

  Future<void> saveBooking(Map<String, dynamic> bookingData) async {
    await _db.collection('bookings').add(bookingData);
  }

  Future<List<Map<String, dynamic>>> getServices() async {
    final snapshot = await _db.collection('services').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> saveGalleryItem(Map<String, dynamic> galleryData) async {
    await _db.collection('gallery').add(galleryData);
  }

  Future<void> deleteGalleryItem(String id) async {
    await _db.collection('gallery').doc(id).delete();
  }
}
