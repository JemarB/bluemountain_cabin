import 'package:flutter/material.dart';
import '../models/gallery_model.dart';

class GalleryGrid extends StatelessWidget {
  final List<GalleryModel> items;
  final void Function(GalleryModel) onShare;
  final void Function(GalleryModel) onDelete;

  const GalleryGrid({
    super.key,
    required this.items,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No images uploaded yet',
          style: TextStyle(fontSize: 16, color: Colors.brown),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return GestureDetector(
          onLongPress: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (_) => SafeArea(
                child: Wrap(
                  children: [
                    ListTile(
                      leading: Icon(Icons.share, color: primaryColor),
                      title: Text('Share', style: textTheme.titleMedium),
                      onTap: () {
                        Navigator.pop(context);
                        onShare(item);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: textTheme.titleMedium),
                      onTap: () {
                        Navigator.pop(context);
                        onDelete(item);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      // optional small overlay icon for sharing/deleting (can remove if not needed)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (_) => SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: Icon(Icons.share, color: primaryColor),
                                    title: Text('Share', style: textTheme.titleMedium),
                                    onTap: () {
                                      Navigator.pop(context);
                                      onShare(item);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete, color: Colors.red),
                                    title: Text('Delete', style: textTheme.titleMedium),
                                    onTap: () {
                                      Navigator.pop(context);
                                      onDelete(item);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    item.caption,
                    style: textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
