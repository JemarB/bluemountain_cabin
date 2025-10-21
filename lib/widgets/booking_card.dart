import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';

class BookingCard extends StatefulWidget {
  final BookingModel booking;
  final VoidCallback onCancel;
  final VoidCallback onReceipt;
  final VoidCallback onEdit;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onCancel,
    required this.onReceipt,
    required this.onEdit,
  });

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _scaleAnim =
        Tween<double>(begin: 0.98, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  void _triggerVisualUpdate() {
    setState(() => _opacity = 0.5);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() => _opacity = 1.0);
        _controller.forward(from: 0);
      }
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
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

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  String _formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool bold = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.brown),
        const SizedBox(width: 6),
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.booking.id)
          .snapshots(),
      builder: (context, snapshot) {
        BookingModel booking = widget.booking;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data()!;
          booking = BookingModel.fromFirestore(data, snapshot.data!.id);
        }

        final status = booking.status.toLowerCase();
        final statusColor = _statusColor(status);
        final statusIcon = _statusIcon(status);
        final nights = booking.nights;

        final isWeekend = booking.serviceName.toLowerCase().contains('weekend getaway');
        final isDaypass = booking.serviceName.toLowerCase().contains('scenic cabin');
        final isPending = status == 'pending';
        final isConfirmed = status == 'confirmed';
        final isCancelled = status == 'cancelled';

        final imageUrl = booking.serviceImageUrls.isNotEmpty
            ? booking.serviceImageUrls.first.replaceAll('{serviceId}', booking.serviceId)
            : booking.serviceImageUrl;

        final borderColor = isConfirmed
            ? Colors.green.shade300
            : isPending
                ? Colors.amber.shade300
                : Colors.transparent;

        if (snapshot.hasData) {
          _triggerVisualUpdate(); // trigger fade + scale whenever Firestore updates
        }

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isCancelled ? 0.6 : _opacity,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor, width: isConfirmed ? 2 : 1),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: isPending ? Colors.amber.shade50 : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- IMAGE HEADER ----
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 150,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported, size: 50),
                            ),
                          )
                        : Container(
                            height: 150,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 50),
                          ),
                  ),

                  // ---- DETAILS ----
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---- Service name + badge ----
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                booking.serviceName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (isWeekend)
                              Chip(
                                label: const Text('Weekend Getaway'),
                                backgroundColor: Colors.orange.shade100,
                                labelStyle: const TextStyle(
                                  color: Colors.deepOrange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (isDaypass)
                              Chip(
                                label: const Text('Day Pass'),
                                backgroundColor: Colors.teal.shade100,
                                labelStyle: const TextStyle(
                                  color: Colors.teal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.calendar_today, 'Check-in', _formatDate(booking.checkIn)),
                        _buildInfoRow(Icons.logout, 'Check-out', _formatDate(booking.checkOut)),
                        _buildInfoRow(Icons.people, 'Guests', '${booking.guestCount}'),
                        if (!isDaypass)
                          _buildInfoRow(Icons.nights_stay, 'Nights', nights.toString()),

                        const SizedBox(height: 8),

                        // ---- Total & Status ----
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total: ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(booking.priceSnapshot)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Row(
                              children: [
                                Icon(statusIcon, color: statusColor, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  booking.status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // ---- Pending hint ----
                        if (isPending)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: const [
                                Icon(Icons.info_outline, size: 16, color: Colors.orange),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Awaiting admin approval...',
                                    style: TextStyle(fontSize: 12, color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Colors.grey),

                        // ---- Action Buttons ----
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      (!isConfirmed && !isCancelled) ? widget.onEdit : null,
                                  icon: const Icon(Icons.edit_calendar),
                                  label: const Text('Edit'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: widget.onReceipt,
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text('Receipt'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.brown.shade700,
                                    side: BorderSide(color: Colors.brown.shade300),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextButton.icon(
                                  onPressed:
                                      (!isConfirmed && !isCancelled) ? widget.onCancel : null,
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('Cancel'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
