import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/match_model.dart';

/// ويدجت الكرونومتر المباشر التفاعلي للمباراة (Live Chronometer)
/// يحدث تلقائياً كل 10 ثوانٍ ليعكس الدقيقة المباشرة بدقة فورية
class LiveChronometerWidget extends StatefulWidget {
  final MatchModel match;
  final bool compact;
  final TextStyle? textStyle;
  final bool showBackground;

  const LiveChronometerWidget({
    super.key,
    required this.match,
    this.compact = false,
    this.textStyle,
    this.showBackground = true,
  });

  @override
  State<LiveChronometerWidget> createState() => _LiveChronometerWidgetState();
}

class _LiveChronometerWidgetState extends State<LiveChronometerWidget>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // تحديث دوري للعداد الزمني
    _startTickerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant LiveChronometerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.match.isLive != oldWidget.match.isLive) {
      _startTickerIfNeeded();
    }
  }

  void _startTickerIfNeeded() {
    _ticker?.cancel();
    if (widget.match.isLive) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final isLive = match.isLive;
    final isHalfTime = match.isHalfTime;
    final isFinished = match.isFinished;
    final chrono = match.chronometerDisplay;

    if (isLive && !isHalfTime) {
      final child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _pulseAnimation,
            child: Container(
              width: widget.compact ? 6 : 7,
              height: widget.compact ? 6 : 7,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFEF4444),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            chrono,
            style: widget.textStyle ??
                TextStyle(
                  color: const Color(0xFFEF4444),
                  fontSize: widget.compact ? 11 : 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
          ),
        ],
      );

      if (!widget.showBackground) return child;

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 8 : 10,
          vertical: widget.compact ? 3 : 4.5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.55), width: 1),
        ),
        child: child,
      );
    }

    if (isHalfTime) {
      final child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pause_circle_rounded, size: 12, color: Color(0xFFF59E0B)),
          const SizedBox(width: 4),
          Text(
            'استراحة 45\'',
            style: widget.textStyle ??
                TextStyle(
                  color: const Color(0xFFF59E0B),
                  fontSize: widget.compact ? 10.5 : 11.5,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      );

      if (!widget.showBackground) return child;

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 8 : 10,
          vertical: widget.compact ? 3 : 4.5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withOpacity(0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5), width: 1),
        ),
        child: child,
      );
    }

    if (isFinished) {
      final child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF0F766E)),
          const SizedBox(width: 4),
          Text(
            'انتهت • FT',
            style: widget.textStyle ??
                TextStyle(
                  fontSize: widget.compact ? 10 : 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F766E),
                ),
          ),
        ],
      );

      if (!widget.showBackground) return child;

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 8 : 10,
          vertical: widget.compact ? 3 : 4.5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0F766E).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0F766E).withOpacity(0.35), width: 1),
        ),
        child: child,
      );
    }

    // للمباريات المبرمجة / لم تبدأ
    final timeStr = match.time.isNotEmpty && match.time != '00:00' ? match.time : 'لم تبدأ';
    final child = Text(
      timeStr,
      style: widget.textStyle ??
          TextStyle(
            fontSize: widget.compact ? 10.5 : 11.5,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
    );

    if (!widget.showBackground) return child;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 8 : 10,
        vertical: widget.compact ? 3 : 4.5,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.25), width: 1),
      ),
      child: child,
    );
  }
}
