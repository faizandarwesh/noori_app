import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../i18n/app_lang.dart';
import '../theme/app_theme.dart';

enum BubbleTail { left, right, down }

/// Noori's speech bubble. Pops in with an elastic scale whenever [text]
/// changes and floats gently while shown. Voice comes first; this text is
/// secondary for children who cannot read yet.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    required this.lang,
    this.tail = BubbleTail.left,
    this.maxWidth = AppSizes.bubbleMaxWidth,
  });

  final String text;
  final AppLang lang;
  final BubbleTail tail;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final origin = switch (tail) {
      BubbleTail.left => Alignment.centerLeft,
      BubbleTail.right => Alignment.centerRight,
      BubbleTail.down => Alignment.bottomCenter,
    };

    return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: CustomPaint(
            painter: _BubblePainter(color: c.bubble, tail: tail),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSizes.space4 + (tail == BubbleTail.left ? _tailSize : 0),
                AppSizes.space3,
                AppSizes.space4 + (tail == BubbleTail.right ? _tailSize : 0),
                AppSizes.space3 + (tail == BubbleTail.down ? _tailSize : 0),
              ),
              child: Text(
                text,
                textDirection: lang.direction,
                textAlign: TextAlign.center,
                style: AppTypography.style(
                  lang,
                  role: TextRole.label,
                  color: c.onBubble,
                  weight: 600,
                ),
              ),
            ),
          ),
        )
        .animate(key: ValueKey('$text${lang.name}'))
        .fadeIn(duration: 150.ms)
        .scale(
          begin: const Offset(0.5, 0.5),
          alignment: origin,
          duration: AppMotion.bubblePop,
          curve: AppMotion.pop,
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -4, duration: 1600.ms, curve: AppMotion.soft);
  }
}

const _tailSize = 14.0;

class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.color, required this.tail});

  final Color color;
  final BubbleTail tail;

  @override
  void paint(Canvas canvas, Size size) {
    final body = switch (tail) {
      BubbleTail.left => Rect.fromLTRB(_tailSize, 0, size.width, size.height),
      BubbleTail.right => Rect.fromLTRB(
        0,
        0,
        size.width - _tailSize,
        size.height,
      ),
      BubbleTail.down => Rect.fromLTRB(
        0,
        0,
        size.width,
        size.height - _tailSize,
      ),
    };
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(AppSizes.radiusSm)),
      );
    final tailPath = switch (tail) {
      BubbleTail.left =>
        Path()
          ..moveTo(_tailSize + 2, body.center.dy - 10)
          ..lineTo(0, body.center.dy + 6)
          ..lineTo(_tailSize + 2, body.center.dy + 10),
      BubbleTail.right =>
        Path()
          ..moveTo(body.right - 2, body.center.dy - 10)
          ..lineTo(size.width, body.center.dy + 6)
          ..lineTo(body.right - 2, body.center.dy + 10),
      BubbleTail.down =>
        Path()
          ..moveTo(body.center.dx - 12, body.bottom - 2)
          ..lineTo(body.center.dx - 4, size.height)
          ..lineTo(body.center.dx + 12, body.bottom - 2),
    };
    path.addPath(tailPath..close(), Offset.zero);
    canvas
      ..drawShadow(path, AppPalette.shadow, 4, false)
      ..drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.color != color || old.tail != tail;
}
