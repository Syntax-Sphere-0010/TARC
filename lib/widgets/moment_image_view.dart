import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MomentImageView extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final String category;
  final double? width;
  final double? height;

  const MomentImageView({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.category = 'General',
    this.width,
    this.height,
  });

  bool get _isNetworkImage =>
      imageUrl.startsWith('http://') ||
      imageUrl.startsWith('https://') ||
      imageUrl.startsWith('blob:');

  bool get _isBase64Image =>
      imageUrl.startsWith('data:image/') ||
      imageUrl.startsWith('data:application/') ||
      (imageUrl.length > 80 && !imageUrl.contains(' ') && !imageUrl.startsWith('http') && !imageUrl.startsWith('assets/'));

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.trim();
    if (cleanUrl.isEmpty) {
      return _buildFallback(context);
    }

    // 1. Base64 encoded image (data:image/... or raw base64 bytes)
    if (_isBase64Image) {
      try {
        final commaIdx = cleanUrl.indexOf(',');
        final base64Data = commaIdx != -1 ? cleanUrl.substring(commaIdx + 1) : cleanUrl;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (ctx, err, stack) => _buildFallback(context),
        );
      } catch (_) {
        return _buildFallback(context);
      }
    }

    // 2. Network Image (http, https, blob URL)
    if (_isNetworkImage) {
      return Image.network(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, err, stack) => _buildFallback(context),
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFFF7ECE1),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ),
          );
        },
      );
    }

    // 3. Asset Image
    if (cleanUrl.startsWith('assets/')) {
      return Image.asset(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, err, stack) => _buildFallback(context),
      );
    }

    // 4. Local file path from Gallery / Camera (only on non-web platforms)
    if (!kIsWeb) {
      try {
        final file = File(cleanUrl);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (ctx, err, stack) => _buildFallback(context),
          );
        }
      } catch (_) {
        return _buildFallback(context);
      }
    }

    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    IconData icon;
    switch (category.toLowerCase()) {
      case 'fitness':
        icon = Icons.fitness_center_rounded;
        break;
      case 'nature':
        icon = Icons.terrain_rounded;
        break;
      case 'mindset':
        icon = Icons.self_improvement_rounded;
        break;
      case 'work':
        icon = Icons.work_outline_rounded;
        break;
      case 'study':
      default:
        icon = Icons.menu_book_rounded;
        break;
    }

    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFDFC7), Color(0xFFF0BD96)],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: AppTheme.primaryOrange.withValues(alpha: 0.7),
          size: 32,
        ),
      ),
    );
  }
}
