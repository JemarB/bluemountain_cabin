import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as fb_storage;
import 'package:intl/intl.dart';

import '../models/service_model.dart';
import '../widgets/booking_sheet.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _currency = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  // ---------- Resolve Firebase Storage image URLs ----------
  Future<String?> _resolveImageUrl(String? raw, String docId) async {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final trimmed = raw.trim().replaceAll('{serviceId}', docId);
      if (trimmed.startsWith('http')) return trimmed;
      if (trimmed.startsWith('gs://')) {
        final ref = fb_storage.FirebaseStorage.instance.refFromURL(trimmed);
        return await ref.getDownloadURL();
      }
      final ref = fb_storage.FirebaseStorage.instance.ref(trimmed);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('resolveImageUrl failed for $raw: $e');
      return null;
    }
  }

  // ---------- Compute total price ----------
  double computeTotal(ServiceModel s, int guests, int nights) {
    if (s.isDaypass) return s.pricePerPerson * guests;

    final effectiveGuests =
        (s.baseIncludedGuests != null && guests < s.baseIncludedGuests!)
            ? s.baseIncludedGuests!
            : guests;

    if (s.pricePerPerson > 0) {
      return s.pricePerPerson * effectiveGuests * (nights <= 0 ? 1 : nights);
    }
    return s.basePrice * (nights <= 0 ? 1 : nights);
  }

  // ---------- Open booking sheet ----------
  void _openBookingSheet(ServiceModel service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: BookingSheet(
                    initialService: service,
                    computeTotal: computeTotal,
                    resolveImageUrl: _resolveImageUrl,
                    currencyFormat: _currency,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------- Amenity chips ----------
  Widget _amenity(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.blueAccent),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }

  Widget _amenitiesRow(ServiceModel s) {
    final chips = <Widget>[];
    if (s.hasWifi) chips.add(_amenity('Free Wi-Fi', Icons.wifi));
    if (s.hasPool) chips.add(_amenity('Pool', Icons.pool));
    if (s.hasBreakfast) chips.add(_amenity('Breakfast', Icons.free_breakfast));
    return Wrap(spacing: 12, runSpacing: 6, children: chips);
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Cabin'),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('services').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No services available at the moment.\nPlease check back later.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final services = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ServiceModel.fromFirestore(doc.id, data);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final s = services[index];
              final rawPreview =
                  s.imageUrls.isNotEmpty ? s.imageUrls.first : (s.imageUrl ?? '');
              final previewUrl = rawPreview.replaceAll('{serviceId}', s.id);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: previewUrl.isNotEmpty
                          ? Image.network(
                              previewUrl,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) {
                                debugPrint('Image load error for ${s.id}: $err');
                                return Container(
                                  height: 160,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image, size: 56),
                                );
                              },
                            )
                          : Container(
                              height: 160,
                              color: Colors.grey[200],
                              child: const Icon(Icons.photo, size: 56),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              Text(
                                s.isDaypass
                                    ? '${_currency.format(s.pricePerPerson)} /person'
                                    : '${_currency.format(s.pricePerPerson > 0 ? s.pricePerPerson : s.basePrice)} /night',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _amenitiesRow(s),
                          const SizedBox(height: 8),
                          Text(
                            s.duration,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _openBookingSheet(s),
                              icon: const Icon(Icons.event_available),
                              label: const Text('Book'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown.shade700,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
