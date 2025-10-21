import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/profile_avatar.dart';
import '../core/theme_controller.dart'; // ✅ For dark mode toggle

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    photoUrl = _user?.photoURL;
  }

  // --------------------- PROFILE PHOTO UPLOAD ---------------------
  Future<void> uploadProfilePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final file = File(pickedFile.path);
    final ref = FirebaseStorage.instance.ref().child('profile_photos/${user.uid}.jpg');

    try {
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await user.updatePhotoURL(url);

      if (!mounted) return;
      setState(() {
        _user = user;
        photoUrl = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  // --------------------- UPDATE DISPLAY NAME ---------------------
  Future<void> updateDisplayName() async {
    final currentName = FirebaseAuth.instance.currentUser?.displayName ?? '';
    final controller = TextEditingController(text: currentName);

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ThemeController.themeNotifier.value == ThemeMode.dark
            ? Colors.grey[900]
            : Colors.white,
        title: const Text('Update Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter your new display name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final newName = controller.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.updateDisplayName(newName);
      if (!mounted) return;
      setState(() => _user = user);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  // --------------------- LOGOUT ---------------------
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have been logged out.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?.displayName ?? 'Guest';
    final email = _user?.email ?? 'No email';
    final isDark = ThemeController.themeNotifier.value == ThemeMode.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAF3E0),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: isDark ? Colors.grey[900] : primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // --------------------- PROFILE CARD ---------------------
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ProfileAvatar(photoUrl: photoUrl, name: name),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.brown[800],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.grey[400] : Colors.brown[400],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --------------------- ACTION BUTTONS ---------------------
            Card(
              color: isDark ? Colors.grey[850] : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: isDark ? 0 : 4,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.teal),
                    title: const Text('Edit Display Name'),
                    onTap: updateDisplayName,
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.photo_camera, color: Colors.indigo),
                    title: const Text('Change Profile Photo'),
                    onTap: uploadProfilePhoto,
                  ),
                  const Divider(height: 0),
                  SwitchListTile(
                    value: isDark,
                    onChanged: (value) => ThemeController.toggleTheme(value),
                    secondary: const Icon(Icons.dark_mode, color: Colors.amber),
                    title: const Text('Dark Mode'),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('Logout'),
                    onTap: logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
