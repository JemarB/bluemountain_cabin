import 'package:flutter/material.dart';

class ServiceImage extends StatelessWidget {
  final List<String>? imageUrls;
  final String? imageUrl;
  final double height;
  final double? width; // ✅ Added
  final double borderRadius;
  final BoxFit fit;
  final int maxThumbnails; // ✅ Added

  const ServiceImage({
    super.key,
    this.imageUrls,
    this.imageUrl,
    this.height = 110,
    this.width, // ✅ Added
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
    this.maxThumbnails = 3, // ✅ Added
  });

  String? get _pickUrl {
    if (imageUrls != null && imageUrls!.isNotEmpty) {
      final first =
          imageUrls!.firstWhere((s) => s.trim().isNotEmpty, orElse: () => '');
      if (first.isNotEmpty) return first;
    }
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) return imageUrl;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ If there are multiple valid images, show thumbnails
    if (imageUrls != null && imageUrls!.isNotEmpty) {
      final validUrls = imageUrls!
          .where((url) => url.trim().isNotEmpty)
          .take(maxThumbnails)
          .toList();

      if (validUrls.isNotEmpty) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: validUrls
              .map(
                (url) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: Image.network(
                      url,
                      height: height,
                      width: (width != null
                              ? width! / validUrls.length
                              : height) -
                          2,
                      fit: fit,
                      errorBuilder: (context, error, stack) => Container(
                        height: height,
                        width: height,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      }
    }

    // ✅ Fallback to single image or placeholder
    final url = _pickUrl;
    if (url == null) {
      return Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Center(
          child: Icon(Icons.photo, size: 48, color: Colors.grey),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        height: height,
        width: width ?? double.infinity,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: height,
            width: width ?? double.infinity,
            alignment: Alignment.center,
            color: Colors.grey.shade200,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      (progress.expectedTotalBytes ?? 1)
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stack) {
          return Container(
            height: height,
            width: width ?? double.infinity,
            color: Colors.grey.shade200,
            child:
                const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
          );
        },
      ),
    );
  }
}
