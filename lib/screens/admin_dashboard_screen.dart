// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:intl/intl.dart';

// // class AdminDashboardScreen extends StatelessWidget {
// //   const AdminDashboardScreen({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     final dateFmt = DateFormat('MMM d, yyyy');
// //     final currency = NumberFormat.currency(symbol: '\$');

// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Admin Dashboard'),
// //         backgroundColor: Colors.brown[700],
// //       ),
// //       body: StreamBuilder<QuerySnapshot>(
// //         stream: FirebaseFirestore.instance
// //             .collection('bookings')
// //             .orderBy('createdAt', descending: true)
// //             .snapshots(),
// //         builder: (context, snapshot) {
// //           if (snapshot.connectionState == ConnectionState.waiting) {
// //             return const Center(child: CircularProgressIndicator());
// //           }

// //           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// //             return const Center(child: Text('No bookings available.'));
// //           }

// //           final docs = snapshot.data!.docs;

// //           return ListView.builder(
// //             padding: const EdgeInsets.all(12),
// //             itemCount: docs.length,
// //             itemBuilder: (context, index) {
// //               final data = docs[index].data() as Map<String, dynamic>;
// //               final bookingId = docs[index].id;

// //               final status = (data['status'] ?? 'pending').toString().toLowerCase();
// //               final color = {
// //                 'confirmed': Colors.green,
// //                 'cancelled': Colors.red,
// //                 'pending': Colors.orange,
// //               }[status] ?? Colors.grey;

// //               final checkIn = (data['checkIn'] as Timestamp?)?.toDate();
// //               final checkOut = (data['checkOut'] as Timestamp?)?.toDate();
// //               final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

// //               // Relative time ("x hours ago")
// //               String relativeTime() {
// //                 if (createdAt == null) return '';
// //                 final diff = DateTime.now().difference(createdAt);
// //                 if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
// //                 if (diff.inHours < 24) return '${diff.inHours} hr ago';
// //                 return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
// //               }

// //               return Card(
// //                 elevation: 4,
// //                 margin: const EdgeInsets.symmetric(vertical: 8),
// //                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //                 child: Padding(
// //                   padding: const EdgeInsets.all(14),
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       // ---- Header (Status + Time)
// //                       Row(
// //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                         children: [
// //                           Chip(
// //                             label: Text(
// //                               status.toUpperCase(),
// //                               style: const TextStyle(color: Colors.white),
// //                             ),
// //                             backgroundColor: color,
// //                           ),
// //                           Text(relativeTime(),
// //                               style: const TextStyle(
// //                                   fontSize: 12, color: Colors.grey)),
// //                         ],
// //                       ),

// //                       const SizedBox(height: 6),
// //                       Text(
// //                         data['serviceName'] ?? 'Unknown Service',
// //                         style: Theme.of(context)
// //                             .textTheme
// //                             .titleLarge
// //                             ?.copyWith(fontWeight: FontWeight.bold),
// //                       ),

// //                       const SizedBox(height: 6),

// //                       Text(
// //                         'User ID: ${data['userId'] ?? 'N/A'}',
// //                         style: const TextStyle(fontSize: 12, color: Colors.grey),
// //                       ),

// //                       const SizedBox(height: 8),

// //                       // ---- Booking details
// //                       Text('Check-in: ${checkIn != null ? dateFmt.format(checkIn) : '-'}'),
// //                       Text('Check-out: ${checkOut != null ? dateFmt.format(checkOut) : '-'}'),
// //                       Text('Guests: ${data['guestCount'] ?? 0}'),
// //                       Text('Total: ${currency.format(data['priceSnapshot'] ?? 0)}'),

// //                       const Divider(height: 20),

// //                       // ---- Action buttons
// //                       Row(
// //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                         children: [
// //                           if (status == 'pending') ...[
// //                             ElevatedButton.icon(
// //                               icon: const Icon(Icons.check_circle),
// //                               style: ElevatedButton.styleFrom(
// //                                 backgroundColor: Colors.green,
// //                               ),
// //                               label: const Text('Approve'),
// //                               onPressed: () async {
// //                                 await FirebaseFirestore.instance
// //                                     .collection('bookings')
// //                                     .doc(bookingId)
// //                                     .update({'status': 'confirmed'});

// //                                 ScaffoldMessenger.of(context).showSnackBar(
// //                                   const SnackBar(
// //                                       content: Text('Booking approved successfully!')),
// //                                 );
// //                               },
// //                             ),
// //                             ElevatedButton.icon(
// //                               icon: const Icon(Icons.cancel),
// //                               style: ElevatedButton.styleFrom(
// //                                 backgroundColor: Colors.red,
// //                               ),
// //                               label: const Text('Cancel'),
// //                               onPressed: () async {
// //                                 await FirebaseFirestore.instance
// //                                     .collection('bookings')
// //                                     .doc(bookingId)
// //                                     .update({'status': 'cancelled'});

// //                                 ScaffoldMessenger.of(context).showSnackBar(
// //                                   const SnackBar(
// //                                       content: Text('Booking cancelled successfully!')),
// //                                 );
// //                               },
// //                             ),
// //                           ] else
// //                             Text(
// //                               status == 'confirmed'
// //                                   ? '✅ Confirmed'
// //                                   : '❌ Cancelled',
// //                               style: TextStyle(
// //                                   fontWeight: FontWeight.bold,
// //                                   color: color),
// //                             ),
// //                         ],
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               );
// //             },
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import '../models/booking_model.dart';
// // import '../models/service_model.dart';

// class AdminDashboardScreen extends StatefulWidget {
//   const AdminDashboardScreen({super.key});

//   @override
//   State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
// }

// class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
//   final _dateFmt = DateFormat('MMM d, yyyy');
//   final _currency = NumberFormat.currency(symbol: '\$');
//   String _selectedFilter = 'All';

//   Stream<QuerySnapshot<Map<String, dynamic>>> _bookingsStream() {
//     var query = FirebaseFirestore.instance
//         .collection('bookings')
//         .orderBy('createdAt', descending: true);
//     return query.snapshots();
//   }

//   Future<void> _updateStatus(String id, String status) async {
//     await FirebaseFirestore.instance
//         .collection('bookings')
//         .doc(id)
//         .update({'status': status});
//   }

//   Color _statusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'confirmed':
//         return Colors.green;
//       case 'cancelled':
//         return Colors.red;
//       case 'pending':
//         return Colors.orange;
//       default:
//         return Colors.grey;
//     }
//   }

//   String _relativeTime(DateTime? createdAt) {
//     if (createdAt == null) return '';
//     final diff = DateTime.now().difference(createdAt);
//     if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
//     if (diff.inHours < 24) return '${diff.inHours} hr ago';
//     return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
//   }

//   // 🧾 Compute summary statistics
//   Map<String, dynamic> _computeSummary(List<BookingModel> bookings) {
//     double totalRevenue = 0;
//     int total = bookings.length;
//     int pending = 0, confirmed = 0, cancelled = 0;

//     for (var b in bookings) {
//       totalRevenue += b.priceSnapshot;
//       switch (b.status.toLowerCase()) {
//         case 'pending':
//           pending++;
//           break;
//         case 'confirmed':
//           confirmed++;
//           break;
//         case 'cancelled':
//           cancelled++;
//           break;
//       }
//     }

//     return {
//       'total': total,
//       'pending': pending,
//       'confirmed': confirmed,
//       'cancelled': cancelled,
//       'revenue': totalRevenue,
//     };
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Dashboard'),
//         backgroundColor: Colors.brown[700],
//         actions: [
//           PopupMenuButton<String>(
//             onSelected: (val) {
//               setState(() => _selectedFilter = val);
//             },
//             itemBuilder: (ctx) => [
//               const PopupMenuItem(value: 'All', child: Text('All')),
//               const PopupMenuItem(value: 'Pending', child: Text('Pending')),
//               const PopupMenuItem(value: 'Confirmed', child: Text('Confirmed')),
//               const PopupMenuItem(value: 'Cancelled', child: Text('Cancelled')),
//             ],
//             icon: const Icon(Icons.filter_alt),
//           )
//         ],
//       ),
//       body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//         stream: _bookingsStream(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No bookings found.'));
//           }

//           final bookings = snapshot.data!.docs.map((doc) {
//             return BookingModel.fromFirestore(doc.data(), doc.id);
//           }).where((b) {
//             if (_selectedFilter == 'All') return true;
//             return b.status.toLowerCase() == _selectedFilter.toLowerCase();
//           }).toList();

//           final summary = _computeSummary(bookings);

//           return Column(
//             children: [
//               // ---------------------- SUMMARY BAR ----------------------
//               Container(
//                 color: Colors.brown[50],
//                 padding: const EdgeInsets.all(12),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _summaryItem('Total', summary['total'].toString(),
//                         Icons.event_note, Colors.blue),
//                     _summaryItem('Pending', summary['pending'].toString(),
//                         Icons.hourglass_bottom, Colors.orange),
//                     _summaryItem('Confirmed', summary['confirmed'].toString(),
//                         Icons.check_circle, Colors.green),
//                     _summaryItem('Cancelled', summary['cancelled'].toString(),
//                         Icons.cancel, Colors.red),
//                   ],
//                 ),
//               ),

//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Text(
//                   'Revenue: ${_currency.format(summary['revenue'])}',
//                   style: const TextStyle(
//                       fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//               ),

//               const Divider(height: 0),

//               // ---------------------- BOOKINGS LIST ----------------------
//               Expanded(
//                 child: ListView.builder(
//                   padding: const EdgeInsets.all(12),
//                   itemCount: bookings.length,
//                   itemBuilder: (context, i) {
//                     final b = bookings[i];
//                     final color = _statusColor(b.status);
//                     return Card(
//                       elevation: 3,
//                       margin: const EdgeInsets.symmetric(vertical: 8),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                       child: Padding(
//                         padding: const EdgeInsets.all(14),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // ---------- Header ----------
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Chip(
//                                   label: Text(
//                                     b.status.toUpperCase(),
//                                     style: const TextStyle(color: Colors.white),
//                                   ),
//                                   backgroundColor: color,
//                                 ),
//                                 Text(
//                                   _relativeTime(b.createdAt),
//                                   style: const TextStyle(
//                                       fontSize: 12, color: Colors.grey),
//                                 ),
//                               ],
//                             ),

//                             const SizedBox(height: 6),
//                             Text(
//                               b.serviceName,
//                               style: const TextStyle(
//                                   fontWeight: FontWeight.bold, fontSize: 17),
//                             ),

//                             const SizedBox(height: 4),
//                             Text(
//                               '${_dateFmt.format(b.checkIn)} → ${_dateFmt.format(b.checkOut)}',
//                               style: const TextStyle(fontSize: 13),
//                             ),
//                             Text(
//                               '${b.durationInDays} night${b.durationInDays > 1 ? 's' : ''} • ${b.guestCount} guests',
//                               style: const TextStyle(fontSize: 13),
//                             ),
//                             const SizedBox(height: 8),

//                             Text('User ID: ${b.userId ?? "N/A"}',
//                                 style: const TextStyle(
//                                     fontSize: 12, color: Colors.grey)),
//                             const SizedBox(height: 8),

//                             Text('Total: ${_currency.format(b.priceSnapshot)}',
//                                 style: const TextStyle(
//                                     fontWeight: FontWeight.bold, fontSize: 15)),
//                             const Divider(height: 18),

//                             // ---------- Actions ----------
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 if (b.status.toLowerCase() == 'pending') ...[
//                                   ElevatedButton.icon(
//                                     icon: const Icon(Icons.check),
//                                     label: const Text('Approve'),
//                                     style: ElevatedButton.styleFrom(
//                                         backgroundColor: Colors.green),
//                                     onPressed: () async {
//                                       final ok = await _confirmDialog(
//                                           context,
//                                           'Approve booking for ${b.serviceName}?');
//                                       if (ok) {
//                                         await _updateStatus(b.id, 'confirmed');
//                                         if (!mounted) return;
//                                         ScaffoldMessenger.of(context)
//                                             .showSnackBar(const SnackBar(
//                                                 content: Text(
//                                                     'Booking approved!')));
//                                       }
//                                     },
//                                   ),
//                                   ElevatedButton.icon(
//                                     icon: const Icon(Icons.cancel),
//                                     label: const Text('Cancel'),
//                                     style: ElevatedButton.styleFrom(
//                                         backgroundColor: Colors.red),
//                                     onPressed: () async {
//                                       final ok = await _confirmDialog(
//                                           context,
//                                           'Cancel booking for ${b.serviceName}?');
//                                       if (ok) {
//                                         await _updateStatus(b.id, 'cancelled');
//                                         if (!mounted) return;
//                                         ScaffoldMessenger.of(context)
//                                             .showSnackBar(const SnackBar(
//                                                 content: Text(
//                                                     'Booking cancelled!')));
//                                       }
//                                     },
//                                   ),
//                                 ] else
//                                   Text(
//                                     b.status == 'confirmed'
//                                         ? '✅ Confirmed'
//                                         : '❌ Cancelled',
//                                     style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: color),
//                                   ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _summaryItem(
//       String label, String value, IconData icon, Color color) {
//     return Column(
//       children: [
//         Icon(icon, color: color, size: 24),
//         const SizedBox(height: 4),
//         Text(value,
//             style: TextStyle(
//                 fontWeight: FontWeight.bold, fontSize: 15, color: color)),
//         Text(label, style: const TextStyle(fontSize: 12)),
//       ],
//     );
//   }

//   Future<bool> _confirmDialog(BuildContext context, String message) async {
//     return await showDialog<bool>(
//           context: context,
//           builder: (ctx) => AlertDialog(
//             title: const Text('Confirm Action'),
//             content: Text(message),
//             actions: [
//               TextButton(
//                   onPressed: () => Navigator.pop(ctx, false),
//                   child: const Text('No')),
//               ElevatedButton(
//                   onPressed: () => Navigator.pop(ctx, true),
//                   child: const Text('Yes')),
//             ],
//           ),
//         ) ??
//         false;
//   }
// }
