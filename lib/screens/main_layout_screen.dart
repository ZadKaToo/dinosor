import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart'; // ✅ แก้ package0 เป็น package:
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/app_constants.dart';
import '../models/badge_def.dart';
import '../widgets/google_fonts_shim.dart';
import '../widgets/app_toast.dart';
import 'it_center_dashboard_screen.dart';
import 'ai_mentor_chat_screen.dart';
import 'it_tracks_screen.dart';
import 'career_roadmap_screen.dart';
import 'live_sandbox_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';


class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _goTo(int i) => setState(() => _currentIndex = i);

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final s = context.read<AppState>();
        return AlertDialog(
          backgroundColor: s.cardColor,
          title: Text('ออกจากระบบ?', style: GoogleFonts.prompt(color: s.textPrimary, fontWeight: FontWeight.bold)),
          content: Text('คุณต้องการออกจากระบบใช่หรือไม่?',
              style: GoogleFonts.prompt(color: s.textSecondary, fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('ยกเลิก', style: GoogleFonts.prompt(color: const Color(0xFF94A3B8))),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await s.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: Text('ออกจากระบบ', style: GoogleFonts.prompt(color: const Color(0xFFF87171), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final s = context.read<AppState>();
        return AlertDialog(
          backgroundColor: s.cardColor,
          title: Text('รีเซ็ตความคืบหน้า?', style: GoogleFonts.prompt(color: s.textPrimary, fontWeight: FontWeight.bold)),
          content: Text('ล้างความคืบหน้าทั้งหมดเพื่อเริ่มใหม่หรือไม่?',
              style: GoogleFonts.prompt(color: s.textSecondary, fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('ยกเลิก', style: GoogleFonts.prompt(color: const Color(0xFF94A3B8))),
            ),
            TextButton(
              onPressed: () {
                context.read<AppState>().resetProgress();
                Navigator.of(ctx).pop();
                showAppToast(context, 'รีเซ็ตความคืบหน้าเรียบร้อยแล้ว', type: ToastType.info);
              },
              child: Text('รีเซ็ต', style: GoogleFonts.prompt(color: const Color(0xFFF87171), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    bool isWide = MediaQuery.of(context).size.width >= 800;

    final tabs = [
      ITCenterDashboardScreen(onNavigate: _goTo),
      AIMentorChatScreen(), // ✅ เรียกใช้แบบปกติ
      const ITTracksScreen(),
      const CareerRoadmapScreen(),
      const LiveSandboxScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: state.bgColor,
      body: Row(
        children: [
          if (isWide) _buildDesktopSidebar(context, state),
          Expanded(child: tabs[_currentIndex]),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _goTo,
        backgroundColor: state.sidebarColor,
        indicatorColor: state.accentColor.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: state.textMuted),
            selectedIcon: Icon(Icons.home_rounded, color: state.accentColor),
            label: 'หลัก',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined, color: state.textMuted),
            selectedIcon: Icon(Icons.smart_toy_rounded, color: state.accentColor),
            label: 'AI Mentor',
          ),
          NavigationDestination(
            icon: Icon(Icons.alt_route_outlined, color: state.textMuted),
            selectedIcon: Icon(Icons.alt_route_rounded, color: state.accentColor),
            label: 'Tracks',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined, color: state.textMuted),
            selectedIcon: Icon(Icons.show_chart_rounded, color: state.accentColor),
            label: 'Career',
          ),
          NavigationDestination(
            icon: Icon(Icons.terminal_outlined, color: state.textMuted),
            selectedIcon: Icon(Icons.terminal_rounded, color: state.accentColor),
            label: 'Code',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: state.textMuted),
            selectedIcon: Icon(Icons.settings_rounded, color: state.accentColor),
            label: 'ตั้งค่า',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, AppState state) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: state.sidebarColor,
        border: Border(right: BorderSide(color: state.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: state.accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text('Skillpass',
                    style: GoogleFonts.prompt(
                        color: state.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),

          // ── Nav items ────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sidebarItem(context, state, Icons.home_rounded, 'หน้าหลัก', 0),
                  _sidebarItem(context, state, Icons.smart_toy_rounded, 'AI Mentor', 1),
                  _sidebarItem(context, state, Icons.menu_book_rounded, 'เรียนรู้', 2),
                  _sidebarItem(context, state, Icons.show_chart_rounded, 'Career', 3),
                  _sidebarItem(context, state, Icons.terminal_rounded, 'เขียนโค้ด', 4),
                  InkWell(
                    onTap: () => _showAchievementsDialog(context, state),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      child: Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 18, color: state.textMuted),
                          const SizedBox(width: 12),
                          Text('Skill Passport',
                              style: GoogleFonts.prompt(color: state.textMuted, fontSize: 13)),
                          const Spacer(),
                          Text('${state.earnedBadges.length}/${kBadges.length}',
                              style: GoogleFonts.prompt(
                                  color: state.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── compact progress card (Level / XP / Reset) ──
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [state.accentColor.withValues(alpha: 0.14), state.accentColor.withValues(alpha: 0.04)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: state.accentColor.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('เป้าหมายเงินเดือน',
                                style: GoogleFonts.prompt(
                                    color: state.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                            Row(
                              children: [
                                const Icon(Icons.local_fire_department, color: Colors.orange, size: 13),
                                Text(' ${state.streakDays} วัน',
                                    style: GoogleFonts.prompt(
                                        color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('฿${formatMoney(state.currentSalary)}/เดือน',
                            style: GoogleFonts.prompt(
                                color: state.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: state.xpIntoLevel / 100.0,
                            minHeight: 6,
                            backgroundColor: state.borderColor,
                            valueColor: AlwaysStoppedAnimation<Color>(state.accentColor),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Lv.${state.level} · ${state.totalXP} XP',
                                style: GoogleFonts.prompt(color: state.textMuted, fontSize: 10)),
                            InkWell(
                              onTap: () => _confirmReset(context),
                              child: Text('รีเซ็ต',
                                  style: GoogleFonts.prompt(
                                      color: state.textMuted, fontSize: 10, decoration: TextDecoration.underline)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── Footer: profile / settings / logout ─
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: state.borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: state.accentColor.withValues(alpha: 0.15),
                        child: Icon(Icons.person_rounded, color: state.accentColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(state.fullName,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.prompt(
                                    color: state.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('มุ่งสู่ ${state.currentRole}',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.prompt(color: state.textMuted, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _sidebarItem(context, state, Icons.settings_outlined, 'ตั้งค่า', 5),
                InkWell(
                  onTap: () => _confirmLogout(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 18, color: state.textMuted),
                        const SizedBox(width: 12),
                        Text('ออกจากระบบ',
                            style: GoogleFonts.prompt(color: state.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(BuildContext context, AppState state, IconData icon, String label, int index) {
    final active = _currentIndex == index;
    return InkWell(
      onTap: () => _goTo(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: active ? state.accentColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: active ? state.accentColor : state.textMuted),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.prompt(
                    color: active ? state.accentColor : state.textMuted,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  void _showAchievementsDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: state.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: state.borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460, maxHeight: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Achievements',
                        style: GoogleFonts.prompt(color: state.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 18),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                Text('ปลดล็อกแล้ว ${state.earnedBadges.length} จากทั้งหมด ${kBadges.length} เหรียญตรา',
                    style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 12)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: kBadges.isEmpty ? 0 : state.earnedBadges.length / kBadges.length,
                    minHeight: 6,
                    backgroundColor: Colors.black26,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC084FC)),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: kBadges.map((b) {
                        final earned = state.earnedBadges.contains(b.id);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: earned ? const Color(0xFF1E293B) : const Color(0xFF0A0F1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: earned ? const Color(0xFF334155) : const Color(0xFF1E293B)),
                          ),
                          child: Row(
                            children: [
                              Opacity(
                                opacity: earned ? 1 : 0.35,
                                child: Icon(b.icon, size: 24,
                                    color: earned ? const Color(0xFF34D399) : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.name,
                                        style: GoogleFonts.prompt(
                                            color: earned ? Colors.white : const Color(0xFF64748B),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold)),
                                    Text(b.desc,
                                        style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 11)),
                                  ],
                                ),
                              ),
                              Icon(
                                earned ? Icons.check_circle : Icons.lock_outline,
                                color: earned ? const Color(0xFF34D399) : const Color(0xFF475569),
                                size: 18,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeShelf(AppState state) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: kBadges.map((b) {
        final earned = state.earnedBadges.contains(b.id);
        return Tooltip(
          message: earned ? '${b.name}: ${b.desc}' : 'ยังไม่ได้รับ',
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: earned ? state.cardAltColor : state.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: earned ? state.borderColorSoft : state.borderColor),
            ),
            child: Opacity(
              opacity: earned ? 1 : 0.45,
              child: Icon(b.icon, size: 15, color: earned ? const Color(0xFF34D399) : const Color(0xFF64748B)),
            ),
          ),
        );
      }).toList(),
    );
  }

}

// ==========================================
// DAILY COUNTDOWN WIDGET
// ==========================================
class DailyCountdown extends StatefulWidget {
  const DailyCountdown({super.key});

  @override
  State<DailyCountdown> createState() => _DailyCountdownState();
}

class _DailyCountdownState extends State<DailyCountdown> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final nextReset = DateTime(now.year, now.month, now.day + 1);
    if (mounted) {
      setState(() {
        _timeLeft = nextReset.difference(now);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Text(
      '$hours:$minutes:$seconds',
      style: GoogleFonts.prompt(
        color: const Color(0xFF10B981),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }
}