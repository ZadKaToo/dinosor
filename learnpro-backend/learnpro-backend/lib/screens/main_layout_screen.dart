import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
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
      const AIMentorChatScreen(),
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
      width: 264,
      color: state.sidebarColor,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade800,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.laptop, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 18),
                        children: [
                          TextSpan(text: 'Learn', style: TextStyle(color: state.textPrimary)),
                          const TextSpan(text: 'Pro', style: TextStyle(color: Color(0xFF10B981))),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade900.withValues(alpha:0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade700, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                      Text(
                        ' ${state.streakDays} วัน',
                        style: GoogleFonts.prompt(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF047857)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('เงินเดือนเป้าหมาย IT',
                      style: GoogleFonts.prompt(color: const Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '฿${formatMoney(state.currentSalary)}/เดือน',
                    style: GoogleFonts.prompt(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(state.currentRole, style: GoogleFonts.prompt(color: const Color(0xFFA7F3D0), fontSize: 10)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (state.currentSalary / 180000).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.black26,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildNavButton(context, 0, Icons.home_rounded, 'หน้าหลัก IT Center'),
            _buildNavButton(context, 1, Icons.smart_toy_rounded, 'AI Mentor Chat'),
            _buildNavButton(context, 2, Icons.alt_route_rounded, 'IT Tracks & Fields'),
            _buildNavButton(context, 3, Icons.show_chart_rounded, 'Career Roadmap'),
            _buildNavButton(context, 4, Icons.terminal_rounded, 'Live Sandbox'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: state.borderColor, height: 1),
            ),
            _buildNavButton(context, 5, Icons.settings_rounded, 'ตั้งค่า'),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showAchievementsDialog(context, state),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ACHIEVEMENTS',
                      style: GoogleFonts.prompt(
                          color: state.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  Text('${state.earnedBadges.length}/${kBadges.length} ดูทั้งหมด →',
                      style: GoogleFonts.prompt(color: const Color(0xFF3B82F6), fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildBadgeShelf(state),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: state.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: state.borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Level ${state.level}',
                          style: GoogleFonts.prompt(color: state.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('${state.totalXP} XP', style: GoogleFonts.prompt(color: Colors.lightBlueAccent, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: state.xpIntoLevel / 100.0,
                      minHeight: 8,
                      backgroundColor: Colors.black26,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => _confirmReset(context),
                        child: Row(
                          children: [
                            const Icon(Icons.restart_alt, color: Color(0xFF64748B), size: 14),
                            const SizedBox(width: 4),
                            Text('รีเซ็ต', style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 10)),
                          ],
                        ),
                      ),
                      Text('${state.missionsDone}/${kSandboxMissions.length} Missions',
                          style: GoogleFonts.prompt(color: const Color(0xFF475569), fontSize: 10)),
                    ],
                  ),
                ],
              ),
            )
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

  Widget _buildNavButton(BuildContext context, int index, IconData icon, String label) {
    bool isActive = _currentIndex == index;
    final state = context.watch<AppState>();
    return InkWell(
      onTap: () => _goTo(index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.white : state.textSecondary, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.prompt(
                color: isActive ? Colors.white : state.textSecondary,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// DAILY COUNTDOWN (real ticking timer, replaces JS setInterval countdown)
// ==========================================
