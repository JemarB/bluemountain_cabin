import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'booking_screen.dart';
import 'gallery_screen.dart';
import 'profile_screen.dart';
import 'my_bookings_screen.dart';
import 'auth/login_screen.dart';
import '../widgets/bottom_nav_bar.dart';

class AuthGate extends StatefulWidget {
  final int initialTab;
  const AuthGate({super.key, this.initialTab = 0});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    BookingScreen(),
    GalleryScreen(),
    ProfileScreen(),
    MyBookingsScreen(),
  ];

  void _onItemTapped(int index) {
    if (index < 0 || index >= _screens.length) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return Scaffold(
            body: _screens[_selectedIndex],
            bottomNavigationBar: BottomNavBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

