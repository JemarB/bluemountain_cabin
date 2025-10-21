
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show consolidateHttpClientResponseBytes;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:intl/intl.dart';
import '../models/gallery_model.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<GalleryModel> galleryItems = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    fetchGallery();
  }

  // ------------------- FETCH GALLERY -------------------
  Future<void> fetchGallery() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('gallery')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      final items = snapshot.docs
          .map((doc) => GalleryModel.fromFirestore(doc.data(), doc.id))
          .toList();

      if (!mounted) return;
      setState(() => galleryItems = items);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load gallery: $e')));
    }
  }

  // ------------------- UPLOAD IMAGE -------------------
  Future<void> uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nameController = TextEditingController();
    final captionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Image Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Image Name')),
            const SizedBox(height: 10),
            TextField(controller: captionController, decoration: const InputDecoration(labelText: 'Caption'), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Upload')),
        ],
      ),
    );

    if (result != true) return;

    final name = nameController.text.trim().isEmpty ? 'Untitled' : nameController.text.trim();
    final caption = captionController.text.trim().isEmpty ? 'No caption' : captionController.text.trim();

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final file = File(pickedFile.path);
      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('gallery/$fileName');
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('gallery').add({
        'userId': user.uid,
        'imageUrl': imageUrl,
        'name': name,
        'caption': caption,
        'timestamp': DateTime.now(),
      });

      await fetchGallery();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ------------------- EDIT IMAGE DETAILS -------------------
  Future<void> editImage(GalleryModel item) async {
    final nameController = TextEditingController(text: item.name);
    final captionController = TextEditingController(text: item.caption);

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Image Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Image Name')),
            const SizedBox(height: 10),
            TextField(controller: captionController, decoration: const InputDecoration(labelText: 'Caption'), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (result != true) return;

    try {
      await FirebaseFirestore.instance.collection('gallery').doc(item.id).update({
        'name': nameController.text.trim(),
        'caption': captionController.text.trim(),
      });
      await fetchGallery();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  // ------------------- DELETE IMAGE -------------------
  Future<void> deleteImage(String id, String imageUrl) async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance.collection('gallery').doc(id).delete();
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      await fetchGallery();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ------------------- SHARE IMAGE -------------------
  Future<void> shareImageFile(String imageUrl, String caption, String name) async {
    setState(() => _loading = true);

    try {
      final uri = Uri.parse(imageUrl);
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(uri);
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/shared_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '$name\n\n$caption\n\nShared via Blue Mountain Cabin 🏔️',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ------------------- FULLSCREEN VIEW -------------------
  void openFullScreen(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenGalleryViewer(
          galleryItems: galleryItems,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  // ------------------- UI -------------------
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • hh:mm a');
    final textTheme = Theme.of(context).textTheme;
    final bodyStyle = textTheme.bodyMedium;
    final titleStyle = textTheme.titleMedium;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      floatingActionButton: FloatingActionButton(
        onPressed: uploadImage,
        backgroundColor: primaryColor,
        child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.add_a_photo),
      ),
      body: _loading && galleryItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : galleryItems.isEmpty
              ? Center(child: Text('No images uploaded yet', style: bodyStyle))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: galleryItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final item = galleryItems[index];
                    return GestureDetector(
                      onTap: () => openFullScreen(index),
                      onLongPress: () => showModalBottomSheet(
                        context: context,
                        builder: (_) => Wrap(
                          children: [
                            ListTile(
                              leading: Icon(Icons.edit, color: primaryColor),
                              title: Text('Edit Details', style: titleStyle),
                              onTap: () {
                                Navigator.pop(context);
                                editImage(item);
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.share, color: primaryColor),
                              title: Text('Share Image', style: titleStyle),
                              onTap: () {
                                Navigator.pop(context);
                                shareImageFile(item.imageUrl, item.caption, item.name);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete, color: Colors.red),
                              title: Text('Delete', style: titleStyle),
                              onTap: () {
                                Navigator.pop(context);
                                deleteImage(item.id, item.imageUrl);
                              },
                            ),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Hero(
                              tag: item.id,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(item.imageUrl, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(item.name, style: titleStyle?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          Text(item.caption, style: bodyStyle, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                          Text(
                            dateFormat.format(item.timestamp),
                            style: bodyStyle?.copyWith(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ------------------- FULLSCREEN VIEWER -------------------

class FullscreenGalleryViewer extends StatefulWidget {
  final List<GalleryModel> galleryItems;
  final int initialIndex;

  const FullscreenGalleryViewer({
    super.key,
    required this.galleryItems,
    required this.initialIndex,
  });

  @override
  State<FullscreenGalleryViewer> createState() => _FullscreenGalleryViewerState();
}

class _FullscreenGalleryViewerState extends State<FullscreenGalleryViewer> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final newIndex = _pageController.page?.round() ?? _currentIndex;
    if (newIndex != _currentIndex) {
      setState(() => _currentIndex = newIndex);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • hh:mm a');
    final currentItem = widget.galleryItems[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: widget.galleryItems.length,
            pageController: _pageController,
            builder: (context, index) {
              final item = widget.galleryItems[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(item.imageUrl),
                heroAttributes: PhotoViewHeroAttributes(tag: item.id),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),

          // Close button
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Overlay info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentItem.name,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(currentItem.caption,
                      style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(dateFormat.format(currentItem.timestamp),
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
