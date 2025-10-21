import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:http/http.dart' as http;
import '../models/booking_model.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final df = DateFormat('MMM d, yyyy');
  final currency = NumberFormat.currency(symbol: '\$');

  Stream<QuerySnapshot<Map<String, dynamic>>> get bookingsStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Color statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':
        return Colors.green.shade700;
      case 'pending':
        return Colors.orange.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  // 🔸 Confirmation prompt before cancel or delete
  Future<bool> _confirmAction(BuildContext context, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm Action'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade700),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> cancelBooking(String id) async {
    final confirm =
        await _confirmAction(context, 'Are you sure you want to cancel this booking?');
    if (!confirm) return;

    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(id)
        .update({'status': 'cancelled'});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking cancelled.')),
    );
  }

  Future<void> deleteBooking(String id) async {
    final confirm = await _confirmAction(
        context, 'Do you really want to permanently delete this cancelled booking?');
    if (!confirm) return;

    await FirebaseFirestore.instance.collection('bookings').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cancelled booking deleted.')),
    );
  }

  // --------------------------------------------------
  // 📄 GENERATE RECEIPT PDF + SHARE
  // --------------------------------------------------
  Future<void> generateReceipt(BookingModel b) async {
    try {
      final pdf = pw.Document();
      final now = DateFormat('MMM d, yyyy • h:mm a').format(DateTime.now());

      // 🖼 Load image (if exists)
      pw.MemoryImage? serviceImage;
      try {
        final imageUrl = b.serviceImageUrls.isNotEmpty
            ? b.serviceImageUrls.first.replaceAll('{serviceId}', b.serviceId)
            : b.serviceImageUrl;
        if (imageUrl.isNotEmpty) {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            serviceImage = pw.MemoryImage(response.bodyBytes);
          }
        }
      } catch (_) {}

      // ---------------- RECEIPT DESIGN ----------------
      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(24),
          build: (context) => pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.brown, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ---- Header ----
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'BLUE MOUNTAIN CABINS',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.brown800,
                        ),
                      ),
                      pw.Text(
                        'Official Booking Receipt',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                if (serviceImage != null)
                  pw.Center(
                    child: pw.Container(
                      height: 150,
                      width: double.infinity,
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(8),
                        image: pw.DecorationImage(
                          image: serviceImage,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.brown, thickness: 1),

                pw.SizedBox(height: 12),
                pw.Text('Receipt Date: $now',
                    style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 10),
                pw.Text('Booking ID: ${b.id}',
                    style:
                        pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                pw.SizedBox(height: 8),

                pw.Text('Service: ${b.serviceName}',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Check-in: ${df.format(b.checkIn)}'),
                pw.Text('Check-out: ${df.format(b.checkOut)}'),
                pw.Text('Guests: ${b.guestCount}'),
                pw.Text('Nights: ${b.durationInDays}'),

                pw.SizedBox(height: 12),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: b.status == 'confirmed'
                        ? PdfColors.green100
                        : b.status == 'pending'
                            ? PdfColors.amber100
                            : PdfColors.red100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: pw.Text(
                    'STATUS: ${b.status.toUpperCase()}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: b.status == 'confirmed'
                          ? PdfColors.green800
                          : b.status == 'pending'
                              ? PdfColors.orange800
                              : PdfColors.red800,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 18),
                pw.Divider(),

                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'TOTAL: ${currency.format(b.priceSnapshot)}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.brown800,
                    ),
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Thank you for choosing Blue Mountain Cabins!',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Contact: info@bluemountaincabins.com • +1 (876) 555-CABN',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // ---------------- FILE SAVE + SHARE ----------------
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/Booking_Receipt_${b.id}.pdf');
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Receipt ready for ${b.serviceName}'),
        action: SnackBarAction(
          label: 'Share',
          onPressed: () => Share.shareXFiles([XFile(file.path)]),
        ),
      ));

      // Automatically open share sheet
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating receipt: $e')),
      );
    }
  }

  // --------------------------------------------------
  // 🧾 MAIN UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.brown,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: bookingsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No bookings yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final b = BookingModel.fromFirestore(docs[i].data(), docs[i].id);
              final color = statusColor(b.status);
              final faded = b.status.toLowerCase() == 'cancelled';

              return Opacity(
                opacity: faded ? 0.6 : 1,
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: color.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (b.serviceImageUrls.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: Image.network(
                            b.serviceImageUrls.first
                                .replaceAll('{serviceId}', b.serviceId),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.serviceName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text('${df.format(b.checkIn)} → ${df.format(b.checkOut)}'),
                            Text('${b.guestCount} guests • ${b.durationInDays} night(s)'),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text(
                                    b.status.toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: color,
                                ),
                                Text(
                                  currency.format(b.priceSnapshot),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => generateReceipt(b),
                                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                                    label: const Text('Receipt'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.brown.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: b.status == 'pending'
                                        ? () => cancelBooking(b.id)
                                        : b.status == 'cancelled'
                                            ? () => deleteBooking(b.id)
                                            : null,
                                    icon: Icon(
                                      b.status == 'cancelled'
                                          ? Icons.delete_forever
                                          : Icons.cancel_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      b.status == 'cancelled'
                                          ? 'Delete'
                                          : 'Cancel',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
