import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'blob_logo.dart';

/// Compatibility wrapper for existing mark placements and their sizes.
class BlobMark extends StatelessWidget {
  final double size;
  final bool onDark;

  /// Retained for callers of the old rounded-tile mark. The new mark is drawn
  /// directly against its background and does not need a tile.
  final double? radius;

  const BlobMark({super.key, this.size = 84, this.onDark = false, this.radius});

  @override
  Widget build(BuildContext context) => BlobLogoMark(size: size, onDark: onDark);
}

/// Badge + wordmark, for splash / welcome hero use.
class BlobLockup extends StatelessWidget {
  final double width;
  const BlobLockup({super.key, this.width = 180});

  @override
  Widget build(BuildContext context) {
    // Preserve the previous artwork's 441:527 width-to-height relationship.
    return SizedBox(
      width: width,
      height: width * 527 / 441,
      child: Column(
        children: [
          Expanded(child: Center(child: BlobLogoMark(size: width))),
          SizedBox(
            width: width,
            height: width * 86 / 441,
            child: const FittedBox(
              fit: BoxFit.contain,
              child: Text(
                'Blob',
                style: TextStyle(
                  color: AppColors.brandInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small mark + "BLOB" text, sized for app bar titles.
class BrandAppBarTitle extends StatelessWidget {
  final String? title;
  const BrandAppBarTitle({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BlobMark(size: 34),
        const SizedBox(width: 9),
        Text(title ?? 'BLOB'),
      ],
    );
  }
}
