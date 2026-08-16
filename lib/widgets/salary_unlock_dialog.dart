import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/app_constants.dart';
import 'google_fonts_shim.dart';

void showSalaryUnlockDialog(BuildContext context, String missionName, int xpGained) {
  final state = context.read<AppState>();
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => _SalaryUnlockDialog(
      missionName: missionName,
      xpGained: xpGained,
      salary: state.currentSalary,
      role: state.currentRole,
      streakDays: state.streakDays,
    ),
  );
}

class _SalaryUnlockDialog extends StatefulWidget {
  final String missionName;
  final int xpGained;
  final int salary;
  final String role;
  final int streakDays;
  const _SalaryUnlockDialog({
    required this.missionName,
    required this.xpGained,
    required this.salary,
    required this.role,
    required this.streakDays,
  });

  @override
  State<_SalaryUnlockDialog> createState() => _SalaryUnlockDialogState();
}

class _SalaryUnlockDialogState extends State<_SalaryUnlockDialog> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(milliseconds: 1800));
    WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration, color: Color(0xFF34D399), size: 48),
                const SizedBox(height: 8),
                Text('MISSION COMPLETE!',
                    style: GoogleFonts.prompt(
                        color: const Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(widget.missionName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.prompt(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF065F46)),
                  ),
                  child: Column(
                    children: [
                      Text('เป้าหมายเงินเดือนที่ Unlock ได้',
                          style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 11)),
                      const SizedBox(height: 6),
                      Text('฿${formatMoney(widget.salary)}',
                          style: GoogleFonts.prompt(
                              color: const Color(0xFF34D399), fontSize: 30, fontWeight: FontWeight.bold)),
                      Text('/เดือน · ${widget.role}',
                          style: GoogleFonts.prompt(color: const Color(0xFF94A3B8), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    rewardPill('XP ได้รับ', '+${widget.xpGained} XP', const Color(0xFF1E3A8A), const Color(0xFF93C5FD)),
                    const SizedBox(width: 12),
                    rewardPill('Streak', '${widget.streakDays} วัน', const Color(0xFF78350F), const Color(0xFFFCD34D)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('ต่อไป Mission ถัดไป →',
                        style: GoogleFonts.prompt(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          IgnorePointer(
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 26,
              maxBlastForce: 18,
              minBlastForce: 6,
              gravity: 0.25,
              colors: const [
                Color(0xFF10B981),
                Color(0xFFFBBF24),
                Color(0xFF60A5FA),
                Color(0xFFF472B6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget rewardPill(String label, String value, Color bg, Color fg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(color: bg.withValues(alpha:0.6), borderRadius: BorderRadius.circular(10)),
    child: Column(
      children: [
        Text(label, style: GoogleFonts.prompt(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: GoogleFonts.prompt(color: fg, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
