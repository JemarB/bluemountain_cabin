import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_model.dart';

/// -------------------- BOOKING RULES MODEL --------------------
class BookingRules {
  final String? type; // e.g. "weekend_getaway" or "daypass"
  final int? allowedStartWeekday; // e.g. 5 = Friday
  final int? nights; // number of nights required
  final String? checkInEarliest;
  final String? checkInLatest;
  final String? checkOutLatest;

  const BookingRules({
    this.type,
    this.allowedStartWeekday,
    this.nights,
    this.checkInEarliest,
    this.checkInLatest,
    this.checkOutLatest,
  });

  factory BookingRules.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const BookingRules();

    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return BookingRules(
      type: (m['type'] ?? m['Type'])?.toString().toLowerCase(),
      allowedStartWeekday: _toInt(m['allowedStartWeekday']),
      nights: _toInt(m['nights']),
      checkInEarliest: m['checkInEarliest']?.toString(),
      checkInLatest: m['checkInLatest']?.toString(),
      checkOutLatest: m['checkOutLatest']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        if (type != null) 'type': type,
        if (allowedStartWeekday != null)
          'allowedStartWeekday': allowedStartWeekday,
        if (nights != null) 'nights': nights,
        if (checkInEarliest != null) 'checkInEarliest': checkInEarliest,
        if (checkInLatest != null) 'checkInLatest': checkInLatest,
        if (checkOutLatest != null) 'checkOutLatest': checkOutLatest,
      };
}

/// -------------------- SERVICE MODEL --------------------
class ServiceModel {
  final String id;
  final String name;
  final double basePrice;
  final double pricePerPerson;
  final bool hasWifi;
  final bool hasPool;
  final bool hasBreakfast;
  final String? imageUrl;
  final List<String> imageUrls;
  final String stayType;
  final String duration;
  final int minGuests;
  final int maxGuests;
  final int? baseIncludedGuests;
  final BookingRules bookingRules;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.pricePerPerson,
    required this.hasWifi,
    required this.hasPool,
    required this.hasBreakfast,
    required this.imageUrl,
    required this.imageUrls,
    required this.stayType,
    required this.duration,
    required this.minGuests,
    required this.maxGuests,
    this.baseIncludedGuests,
    required this.bookingRules,
  });

  // ---------------- TYPE HELPERS ----------------
  bool get isDaypass {
    final t = stayType.toLowerCase().replaceAll('_', '').replaceAll('-', '');
    return t == 'daypass' || bookingRules.type?.toLowerCase() == 'daypass';
  }

  bool get isWeekendGetaway {
    final t = stayType.toLowerCase().replaceAll('_', '').replaceAll('-', '');
    return t == 'weekendgetaway' ||
        (bookingRules.type?.toLowerCase() == 'weekend_getaway');
  }

  bool get isOvernight => !isDaypass && !isWeekendGetaway;

  // ---------------- FROM FIRESTORE ----------------
  factory ServiceModel.fromFirestore(String id, Map<String, dynamic> data) {
    String _parseType(Map<String, dynamic> d) {
      return (d['stayType'] ??
              d['staytype'] ??
              d['type'] ??
              d['bookingRules']?['type'] ??
              '')
          .toString()
          .toLowerCase();
    }

    List<String> _imageList(dynamic raw) {
      if (raw is List) return List<String>.from(raw);
      if (raw is String && raw.isNotEmpty) return [raw];
      return [];
    }

    return ServiceModel(
      id: id,
      name: data['name'] ?? 'Untitled',
      basePrice: (data['basePrice'] ?? 0).toDouble(),
      pricePerPerson: (data['pricePerPerson'] ?? 0).toDouble(),
      hasWifi: data['hasWifi'] ?? false,
      hasPool: data['hasPool'] ?? false,
      hasBreakfast: data['hasBreakfast'] ?? false,
      imageUrl: data['imageUrl'],
      imageUrls: _imageList(data['imageUrls']),
      stayType: _parseType(data),
      duration: data['duration'] ?? '',
      minGuests: (data['minGuests'] ?? 1),
      maxGuests: (data['maxGuests'] ?? 5),
      baseIncludedGuests: (data['baseIncludedGuests'] ?? 1),
      bookingRules: BookingRules.fromMap(data['bookingRules']),
    );
  }

  // ---------------- AVAILABILITY CHECK ----------------
  static Future<bool> isAvailable({
    required String serviceId,
    required DateTime checkIn,
    required DateTime checkOut,
    int? requestedGuests,
    bool allowShared = false,
  }) async {
    final query = await FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceId', isEqualTo: serviceId)
        // 🔒 Prevent double-booking of pending OR confirmed dates
        .where('status', whereIn: ['pending', 'confirmed'])
        .get();

    if (allowShared) {
      int totalGuests = 0;
      for (final doc in query.docs) {
        final data = doc.data();
        final existing = BookingModel.fromFirestore(data, doc.id);
        if (existing.overlaps(checkIn, checkOut)) {
          totalGuests += existing.guestCount;
        }
      }
      // Example: Daypass — allow up to 20 total guests concurrently
      return totalGuests + (requestedGuests ?? 0) <= 20;
    }

    // Standard exclusive service (one booking at a time)
    for (final doc in query.docs) {
      final existing = BookingModel.fromFirestore(doc.data(), doc.id);
      if (existing.overlaps(checkIn, checkOut)) return false;
    }
    return true;
  }

  // ---------------- NEXT AVAILABLE DATE ----------------
  static Future<DateTime?> nextAvailableDate(String serviceId) async {
    final query = await FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceId', isEqualTo: serviceId)
        .where('status', isEqualTo: 'confirmed')
        .orderBy('checkOut', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final last = query.docs.first.data();
    final ts = last['checkOut'];
    if (ts is Timestamp) {
      return ts.toDate().add(const Duration(days: 1));
    }
    return null;
  }

  // ---------------- CALCULATE PRICE ----------------
  double calculateTotal({
    required int guests,
    required int nights,
  }) {
    if (pricePerPerson > 0) {
      return pricePerPerson * guests * nights;
    }
    return basePrice * nights;
  }
}

