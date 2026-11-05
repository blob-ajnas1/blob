import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Resolution-independent BLOB mark for light or dark backgrounds.
class BlobLogoMark extends StatelessWidget {
  const BlobLogoMark({super.key, this.size = 84, this.onDark = false})
    : assert(size >= 0);

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'BLOB logo',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _BlobLogoPainter(onDark: onDark)),
      ),
    );
  }
}

class _BlobLogoPainter extends CustomPainter {
  const _BlobLogoPainter({required this.onDark});

  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    // The original 200 x 200 design, including its 7-unit horizontal offset,
    // is centred even if a parent constrains this widget to a non-square box.
    final scale = math.min(size.width, size.height) / 200;
    canvas.save();
    canvas.translate(
      (size.width - 200 * scale) / 2,
      (size.height - 200 * scale) / 2,
    );
    canvas.scale(scale);
    canvas.translate(7, 0);

    final stem = RRect.fromRectAndRadius(
      const Rect.fromLTWH(40, 38, 28, 124),
      const Radius.circular(14),
    );
    const topCenter = Offset(102, 74);
    const bottomCenter = Offset(106, 122);

    canvas.drawRRect(
      stem,
      Paint()..color = onDark ? AppColors.brandCream : AppColors.brandInk,
    );
    canvas.drawCircle(
      topCenter,
      36,
      Paint()
        ..color = onDark ? AppColors.brandGreenOnDark : AppColors.brandGreen,
    );
    canvas.drawCircle(
      bottomCenter,
      40,
      Paint()..color = onDark ? AppColors.brandBlueOnDark : AppColors.brandBlue,
    );

    final topCircle = Path()
      ..addOval(Rect.fromCircle(center: topCenter, radius: 36));
    canvas.save();
    canvas.clipPath(topCircle);
    canvas.drawCircle(bottomCenter, 40, Paint()..color = AppColors.brandGold);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BlobLogoPainter oldDelegate) =>
      oldDelegate.onDark != onDark;
}
