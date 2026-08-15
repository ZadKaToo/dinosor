import 'dart:async';
import 'package:flutter/material.dart';
import 'google_fonts_shim.dart';

class DailyCountdown extends StatefulWidget {
  const DailyCountdown({super.key});

  @override
  State<DailyCountdown> createState() => _DailyCountdownState();
}

class _DailyCountdownState extends State<DailyCountdown> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (mounted) setState(() => _remaining = tomorrow.difference(now));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = _pad(_remaining.inHours);
    final m = _pad(_remaining.inMinutes % 60);
    final s = _pad(_remaining.inSeconds % 60);
    return Text('⏰ รีเซ็ตใน: $h:$m:$s',
        style: GoogleFonts.jetBrainsMono(color: const Color(0xFFFCD34D), fontSize: 11, fontWeight: FontWeight.bold));
  }
}

// ==========================================
// TAB 1: IT CENTER DASHBOARD
