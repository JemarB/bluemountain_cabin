import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app.dart'; // for navigatorKey and AuthGate
import 'package:blue_mountain_app/screens/auth_gate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showBanner = false;
  bool _showWelcome = false;
  bool _showButtons = false;
  bool _showServices = false;
  final List<Timer> _timers = [];
  GoogleMapController? _mapController;

  // Blue Mountain Cabin coordinates
  final LatLng _cabinLocation = const LatLng(18.0665, -76.5950);

  @override
  void initState() {
    super.initState();
    _triggerAnimations();
  }

  void _triggerAnimations() {
    _timers.add(Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showBanner = true);
    }));
    _timers.add(Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showWelcome = true);
    }));
    _timers.add(Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showButtons = true);
    }));
    _timers.add(Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showServices = true);
    }));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _mapController?.dispose();
    super.dispose();
  }

  // ✅ Helper to switch tab
  void _switchTab(int index) {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AuthGate(initialTab: index)),
      (route) => false,
    );
  }

  // ✅ Helper to open Google Maps app
  Future<void> _openCabinLocation() async {
    const url = 'https://www.google.com/maps/place/Blue+Mountain+Peak,+Jamaica';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;
    final headingStyle = textTheme.titleLarge;
    final bodyStyle = textTheme.bodyMedium;
    final subtitleStyle = textTheme.titleMedium;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Blue Mountain Cabin',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(offset: Offset(1, 1), blurRadius: 4, color: Colors.black54)],
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.network(
            'https://firebasestorage.googleapis.com/v0/b/bluemountain-a76eb.firebasestorage.app/o/homepage.jpg?alt=media&token=f500b9d3-bf94-4f7f-945d-e99c58f38b72',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.35)),

          // Content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),

                // Banner
                AnimatedOpacity(
                  opacity: _showBanner ? 1 : 0,
                  duration: const Duration(milliseconds: 800),
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 800),
                    offset: _showBanner ? Offset.zero : const Offset(0, -0.3),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      child: Image.network(
                        'https://firebasestorage.googleapis.com/v0/b/bluemountain-a76eb.firebasestorage.app/o/blue%20mountain%20banner.jpg?alt=media&token=7891b77c-19eb-44f7-b4e0-b30878a6f304',
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Welcome
                AnimatedOpacity(
                  opacity: _showWelcome ? 1 : 0,
                  duration: const Duration(milliseconds: 800),
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 800),
                    offset: _showWelcome ? Offset.zero : const Offset(0, 0.3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.cabin, size: 80, color: primaryColor),
                          const SizedBox(height: 10),
                          Text(
                            'Welcome to Blue Mountain Cabin',
                            style: headingStyle?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Where scenic tranquility meets comfort — your getaway begins here.',
                            style: subtitleStyle?.copyWith(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Buttons
                AnimatedOpacity(
                  opacity: _showButtons ? 1 : 0,
                  duration: const Duration(milliseconds: 800),
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 800),
                    offset: _showButtons ? Offset.zero : const Offset(0, 0.2),
                    child: Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Book Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal[700],
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            ),
                            onPressed: () => _switchTab(1),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal[700],
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            ),
                            onPressed: () => _switchTab(2),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.location_on),
                            label: const Text('View Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 228, 114, 114),
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            ),
                            onPressed: _openCabinLocation,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ Google Map Preview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 200,
                      child: GoogleMap(
                        mapType: MapType.terrain,
                        onMapCreated: (controller) => _mapController = controller,
                        initialCameraPosition: CameraPosition(
                          target: _cabinLocation,
                          zoom: 12.5,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('blue_mountain_cabin'),
                            position: _cabinLocation,
                            infoWindow: const InfoWindow(
                              title: 'Blue Mountain Cabin',
                              snippet: 'Your scenic getaway awaits!',
                            ),
                          ),
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        compassEnabled: false,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Services
                AnimatedOpacity(
                  opacity: _showServices ? 1 : 0,
                  duration: const Duration(milliseconds: 900),
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 900),
                    offset: _showServices ? Offset.zero : const Offset(0, 0.2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Featured Services',
                            style: headingStyle?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Icon(Icons.star, color: primaryColor),
                                  title: Text('Scenic Cabin Stay', style: bodyStyle),
                                  subtitle: Text('Enjoy breathtaking views and cozy comfort.',
                                      style: subtitleStyle),
                                ),
                                const Divider(height: 0),
                                ListTile(
                                  leading: Icon(Icons.star, color: primaryColor),
                                  title: Text('Weekend Getaway', style: bodyStyle),
                                  subtitle: Text('Perfect for couples and small groups.',
                                      style: subtitleStyle),
                                ),
                                const Divider(height: 0),
                                ListTile(
                                  leading: Icon(Icons.pool, color: primaryColor),
                                  title: Text('Luxury Pool Access', style: bodyStyle),
                                  subtitle: Text('Relax and unwind in our heated mountain pool.',
                                      style: subtitleStyle),
                                ),
                                const Divider(height: 0),
                                ListTile(
                                  leading: Icon(Icons.restaurant, color: primaryColor),
                                  title: Text('Complimentary Breakfast', style: bodyStyle),
                                  subtitle: Text('Start your day with local and fresh cuisine.',
                                      style: subtitleStyle),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
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
  }
}
