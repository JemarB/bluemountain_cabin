
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String serviceId;
  final String serviceName;
  final String serviceImageUrl;
  final List<String> serviceImageUrls;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestCount;
  final int nights;
  final double priceSnapshot;
  final double totalCost; // 🆕 for full cost tracking
  final String status; // pending | confirmed | cancelled
  final DateTime? createdAt;
  final String? userId;

  const BookingModel({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.serviceImageUrl,
    required this.serviceImageUrls,
    required this.checkIn,
    required this.checkOut,
    required this.guestCount,
    required this.nights,
    required this.priceSnapshot,
    required this.totalCost,
    required this.status,
    this.createdAt,
    this.userId,
  });

  // -------------------- FROM FIRESTORE --------------------
  factory BookingModel.fromFirestore(Map<String, dynamic> data, String id) {
    int _toInt(dynamic v, {int fallback = 1}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    DateTime _toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    List<String> _toList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.whereType<String>().toList();
      if (raw is String && raw.isNotEmpty) return [raw];
      return [];
    }

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    final ci = _toDate(data['checkIn']);
    final co = _toDate(data['checkOut']);
    final calcNights = co.difference(ci).inDays <= 0 ? 1 : co.difference(ci).inDays;

    return BookingModel(
      id: id,
      serviceId: (data['serviceId'] ?? '').toString(),
      serviceName: (data['serviceName'] ?? 'Unnamed Service').toString(),
      serviceImageUrl: (data['serviceImageUrl'] ?? data['imageUrl'] ?? '').toString(),
      serviceImageUrls: _toList(data['serviceImageUrls'] ?? data['imageUrls']),
      checkIn: ci,
      checkOut: co,
      guestCount: _toInt(data['guestCount']),
      nights: _toInt(data['nights'], fallback: calcNights),
      priceSnapshot: _toDouble(data['priceSnapshot']),
      totalCost: _toDouble(data['totalCost'] ?? data['priceSnapshot']),
      status: (data['status'] ?? 'pending').toString().toLowerCase(),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      userId: data['userId']?.toString(),
    );
  }

  // -------------------- TO MAP (FOR FIRESTORE UPLOAD) --------------------
  Map<String, dynamic> toMap() => {
        'serviceId': serviceId,
        'serviceName': serviceName,
        'serviceImageUrl': serviceImageUrl,
        'serviceImageUrls': serviceImageUrls,
        'checkIn': Timestamp.fromDate(checkIn),
        'checkOut': Timestamp.fromDate(checkOut),
        'guestCount': guestCount,
        'nights': nights,
        'priceSnapshot': priceSnapshot,
        'totalCost': totalCost,
        'status': status,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        if (userId != null) 'userId': userId,
      };

  // -------------------- UTILITIES --------------------

  /// 🧮 Returns total stay duration in days (minimum 1)
  int get durationInDays {
    final diff = checkOut.difference(checkIn).inDays;
    return diff <= 0 ? 1 : diff;
  }

  /// 📅 Returns human-readable date range for UI
  String get dateRangeText {
    final start = "${checkIn.month}/${checkIn.day}/${checkIn.year}";
    final end = "${checkOut.month}/${checkOut.day}/${checkOut.year}";
    return (checkIn.isAtSameMomentAs(checkOut)) ? start : "$start - $end";
  }

  /// ⚖️ Checks overlap between this booking and another date range
  bool overlaps(DateTime otherCheckIn, DateTime otherCheckOut) {
    return checkIn.isBefore(otherCheckOut.add(const Duration(days: 1))) &&
        checkOut.isAfter(otherCheckIn.subtract(const Duration(days: 1)));
  }

  // -------------------- STATUS HELPERS --------------------
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';

  /// 🧾 Active = pending or confirmed
  bool get isActive => isPending || isConfirmed;

  /// 🕓 Display-friendly duration label
  String get durationLabel =>
      "$durationInDays night${durationInDays > 1 ? 's' : ''}";
}

