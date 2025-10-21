import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/service_model.dart';

class BookingSheet extends StatefulWidget {
  final ServiceModel initialService;
  final double Function(ServiceModel, int, int) computeTotal;
  final Future<String?> Function(String?, String) resolveImageUrl;
  final NumberFormat currencyFormat;

  const BookingSheet({
    super.key,
    required this.initialService,
    required this.computeTotal,
    required this.resolveImageUrl,
    required this.currencyFormat,
  });

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  final _fmt = DateFormat('EEE, MMM d, yyyy');
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _guests = 1;
  bool _loading = true;
  bool _submitting = false;
  late final ServiceModel _service;

  final Set<DateTime> _blockedDays = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  bool get _isDayPass => _service.isDaypass;
  bool get _isWeekendGetaway => _service.isWeekendGetaway;

  DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);
  DateTime _nextWeekday(DateTime from, int weekday) {
    var d = _d(from);
    while (d.weekday != weekday) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  DateTime _nextFriday(DateTime from) => _nextWeekday(from, DateTime.friday);
  DateTime _mondayFromFriday(DateTime friday) =>
      _d(friday).add(const Duration(days: 3));

  bool _isBooked(DateTime date) => _blockedDays.contains(_d(date));

  bool _rangeHasBlock(DateTime start, DateTime end) {
    var d = _d(start);
    while (!d.isAfter(end)) {
      if (_blockedDays.contains(d)) return true;
      d = d.add(const Duration(days: 1));
    }
    return false;
  }

  DateTime _firstFreeAfter(DateTime start) {
    var d = _d(start).add(const Duration(days: 1));
    while (_blockedDays.contains(d)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  int _nights() {
    if (_isDayPass) return 0;
    if (_checkIn == null || _checkOut == null) return 1;
    final diff = _checkOut!.difference(_checkIn!).inDays;
    return diff <= 0 ? 1 : diff;
  }

  // ---------- Overlay Toast Message ----------
  void _showOverlayMessage(String message) {
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.2,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.brown.shade700,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  // ---------- Listen for blocked days ----------
  Future<void> _listenBlockedDays() async {
    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceId', isEqualTo: _service.id)
        .where('status', whereIn: ['pending', 'confirmed'])
        .snapshots()
        .listen((snap) {
      final blocked = <DateTime>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final ci = (data['checkIn'] as Timestamp).toDate();
        final co = (data['checkOut'] as Timestamp).toDate();
        var d = _d(ci);
        final end = _d(co);
        while (!d.isAfter(end)) {
          blocked.add(d);
          d = d.add(const Duration(days: 1));
        }
      }
      if (!mounted) return;
      setState(() {
        _blockedDays
          ..clear()
          ..addAll(blocked);
        _loading = false;
      });
    }, onError: (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  // ---------- Lifecycle ----------
  @override
  void initState() {
    super.initState();
    _service = widget.initialService;

    final minG = _service.minGuests > 0 ? _service.minGuests : 1;
    final maxG = _service.maxGuests >= minG ? _service.maxGuests : minG;
    _guests = minG.clamp(minG, maxG);

    final today = _d(DateTime.now());
    if (_isWeekendGetaway) {
      final fri = _nextFriday(today);
      _checkIn = fri;
      _checkOut = _mondayFromFriday(fri);
    } else if (_isDayPass) {
      _checkIn = today;
      _checkOut = today;
    } else {
      _checkIn = today;
      _checkOut = today.add(const Duration(days: 1));
    }

    _listenBlockedDays();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ---------- PICK CHECK-IN ----------
  Future<void> _pickCheckIn() async {
    final now = DateTime.now();
    final first = _d(now);
    final last = first.add(const Duration(days: 365));

    var desiredInitial = _checkIn ?? first;

    if (_isWeekendGetaway && desiredInitial.weekday != DateTime.friday) {
      desiredInitial = _nextFriday(now);
    }

    bool selectable(DateTime day) {
      final d = _d(day);
      if (_isWeekendGetaway) {
        if (d.weekday != DateTime.friday) return false;
        final monday = _mondayFromFriday(d);
        return !_rangeHasBlock(d, monday);
      }
      return !_isBooked(d);
    }

    DateTime safeInitial = desiredInitial;
    int counter = 0;
    while (!selectable(safeInitial) && safeInitial.isBefore(last) && counter < 60) {
      safeInitial = safeInitial.add(const Duration(days: 1));
      counter++;
    }
    if (!selectable(safeInitial)) safeInitial = first;

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: first,
      lastDate: last,
      selectableDayPredicate: selectable,
      helpText: _isWeekendGetaway
          ? 'Pick a Friday (Fri→Mon auto)'
          : (_isDayPass ? 'Pick your day pass date' : 'Pick check-in date'),
    );

    if (picked == null) return;

    setState(() {
      _checkIn = _d(picked);

      if (_isWeekendGetaway) {
        _checkOut = _mondayFromFriday(_checkIn!);
      } else if (_isDayPass) {
        _checkOut = _checkIn;
      } else {
        if (_checkOut == null || !_checkOut!.isAfter(_checkIn!)) {
          var candidate = _checkIn!.add(const Duration(days: 1));
          while (_isBooked(candidate)) {
            candidate = candidate.add(const Duration(days: 1));
          }
          _checkOut = _d(candidate);
        }

        if (_rangeHasBlock(_checkIn!, _checkOut!)) {
          final next = _firstFreeAfter(_checkIn!);
          _checkOut = next;
          _showOverlayMessage(
            'Selected dates are unavailable. Next available check-out: ${_fmt.format(next)}',
          );
        }
      }
    });
  }

  // ---------- PICK CHECK-OUT ----------
  Future<void> _pickCheckOut() async {
    if (_checkIn == null) {
      _showOverlayMessage('Pick your check-in date first.');
      return;
    }
    if (_isWeekendGetaway) {
      _showOverlayMessage('Weekend Getaway has fixed Monday check-out.');
      return;
    }
    if (_isDayPass) {
      _showOverlayMessage('Day Pass is same-day only.');
      return;
    }

    final first = _checkIn!.add(const Duration(days: 1));
    final last = first.add(const Duration(days: 365));
    var init = (_checkOut != null && _checkOut!.isAfter(_checkIn!))
        ? _checkOut!
        : first;

    bool selectable(DateTime day) {
      final d = _d(day);
      if (!d.isAfter(_checkIn!)) return false;
      if (_rangeHasBlock(_checkIn!, d)) return false;
      return true;
    }

    DateTime safeInit = init;
    int counter = 0;
    while (!selectable(safeInit) && safeInit.isBefore(last) && counter < 60) {
      safeInit = safeInit.add(const Duration(days: 1));
      counter++;
    }

    if (!selectable(safeInit)) {
      _showOverlayMessage('No available check-out dates found.');
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInit,
      firstDate: first,
      lastDate: last,
      selectableDayPredicate: selectable,
      helpText: 'Pick check-out date',
    );

    if (picked == null) return;

    if (!picked.isAfter(_checkIn!)) {
      _showOverlayMessage('Check-out must be after check-in.');
      return;
    }

    if (_rangeHasBlock(_checkIn!, picked)) {
      final next = _firstFreeAfter(_checkIn!);
      _showOverlayMessage(
        'Selected dates are unavailable. Next available check-out: ${_fmt.format(next)}',
      );
      return;
    }

    setState(() => _checkOut = _d(picked));
  }

  // ---------- Confirm Dialog ----------
  Future<bool> _showConfirmDialog() async {
    final nights = _nights();
    final total = widget.computeTotal(_service, _guests, nights);

    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Review & Confirm'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_service.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Check-in:  ${_fmt.format(_checkIn!)}'),
                Text('Check-out: ${_fmt.format(_checkOut!)}'),
                Text('Guests:    $_guests'),
                if (!_isDayPass) Text('Nights:    $nights'),
                const SizedBox(height: 10),
                Text(
                  'Total: ${widget.currencyFormat.format(total)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.check),
                label: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ---------- Submit ----------
  Future<void> _submit() async {
    if (_checkIn == null || _checkOut == null) {
      _showOverlayMessage('Please select your dates first.');
      return;
    }

    if (_rangeHasBlock(_checkIn!, _checkOut!)) {
      _showOverlayMessage('Your selected dates conflict with an existing booking.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showOverlayMessage('Please sign in to continue.');
      return;
    }

    final ok = await _showConfirmDialog();
    if (!ok) return;

    setState(() => _submitting = true);

    try {
      final nights = _nights();
      final total = widget.computeTotal(_service, _guests, nights);

      await FirebaseFirestore.instance.collection('bookings').add({
        'serviceId': _service.id,
        'serviceName': _service.name,
        'serviceImageUrl': _service.imageUrl ?? '',
        'serviceImageUrls': _service.imageUrls,
        'checkIn': Timestamp.fromDate(_checkIn!),
        'checkOut': Timestamp.fromDate(_checkOut!),
        'guestCount': _guests,
        'nights': nights,
        'priceSnapshot': total,
        'status': 'pending',
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      _showOverlayMessage('Booking submitted for approval.');
    } catch (e) {
      _showOverlayMessage('Failed to submit booking: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final s = _service;
    final nights = _nights();
    final total = widget.computeTotal(s, _guests, nights);

    final ciEarliest = s.bookingRules.checkInEarliest ?? '--';
    final ciLatest = s.bookingRules.checkInLatest ?? '--';
    final coLatest = s.bookingRules.checkOutLatest ?? '--';

    return Padding(
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
      child: _loading
          ? const SizedBox(
              height: 260,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Book ${s.name}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _legendSwatches(),
                const SizedBox(height: 10),
                _availabilityInfo(ciEarliest, ciLatest, coLatest),
                const SizedBox(height: 10),
                _buildDateFields(),
                const SizedBox(height: 12),
                _guestAndTotalRow(total, nights),
                const SizedBox(height: 16),
                _submitButton(),
                const SizedBox(height: 8),
              ],
            ),
    );
  }

  // ---------- UI Helpers ----------
  Widget _legendSwatches() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _legendSwatch(Colors.green.shade100, 'Available'),
        _legendSwatch(Colors.grey.shade300, 'Unavailable'),
        _legendSwatch(Colors.red.shade300, 'Booked'),
      ],
    );
  }

  Widget _availabilityInfo(String ciEarliest, String ciLatest, String coLatest) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.brown.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Time & Availability',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            _isWeekendGetaway
                ? 'Weekend Getaway: Friday (check-in) → Monday (check-out) automatically.'
                : (_isDayPass
                    ? 'Day Pass: same-day check-in/out.'
                    : 'Overnight: choose check-in & check-out; booked days are disabled.'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            'Check-in: $ciEarliest – $ciLatest  •  Check-out by $coLatest',
            style: TextStyle(fontSize: 12, color: Colors.brown.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFields() {
    return Column(
      children: [
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: _isWeekendGetaway
                ? 'Check-in (Fridays only)'
                : (_isDayPass ? 'Date' : 'Check-in'),
            prefixIcon: const Icon(Icons.calendar_today),
          ),
          controller: TextEditingController(
            text: _checkIn == null ? '' : _fmt.format(_checkIn!),
          ),
          onTap: _pickCheckIn,
        ),
        const SizedBox(height: 10),
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: _isWeekendGetaway
                ? 'Check-out (fixed Monday)'
                : (_isDayPass ? 'Check-out (same day)' : 'Check-out'),
            prefixIcon:
                Icon(_isWeekendGetaway || _isDayPass ? Icons.lock : Icons.logout),
          ),
          controller: TextEditingController(
            text: _checkOut == null ? '' : _fmt.format(_checkOut!),
          ),
          onTap: (_isWeekendGetaway || _isDayPass) ? null : _pickCheckOut,
        ),
      ],
    );
  }

  Widget _guestAndTotalRow(double total, int nights) {
    return Column(
      children: [
        Row(
          children: [
            const Text('Guests:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed:
                  _guests > _service.minGuests ? () => setState(() => _guests--) : null,
            ),
            Text('$_guests', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed:
                  _guests < _service.maxGuests ? () => setState(() => _guests++) : null,
            ),
            const Spacer(),
            if (!_isDayPass) Text('Nights: $nights'),
          ],
        ),
        const SizedBox(height: 12),
        if (_checkIn != null && _checkOut != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                widget.currencyFormat.format(total),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
      ],
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _submitting ? null : _submit,
        icon: _submitting
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.check),
        label: Text(_submitting ? 'Submitting...' : 'Review & Confirm'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _legendSwatch(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black12),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
