import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/google_fonts_shim.dart';
import '../widgets/daily_countdown.dart';

class ITCenterDashboardScreen extends StatelessWidget {
  final void Function(int) onNavigate;
  const ITCenterDashboardScreen({super.key, required this.onNavigate});

  static const _categories = [
    'ทั้งหมด',
    'Software Dev',
    'Data & AI',
    'Cloud & DevOps',
    'Cybersecurity',
    'Career Path',
    'Missions',
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: state.bgColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero (Discovery style) ─────────────────────────
            _buildHero(context, state),
            const SizedBox(height: 24),

            // ── Category chips ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('หมวดหมู่การเรียนรู้',
                      style: GoogleFonts.prompt(
                          color: state.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => onNavigate(2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('ดูทุกหมวดหมู่',
                            style: GoogleFonts.prompt(
                                color: state.accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Icon(Icons.arrow_forward, size: 16, color: state.accentColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final selected = i == 0;
                  return InkWell(
                    onTap: () {
                      if (i == 1) onNavigate(2);
                      if (i == 2) onNavigate(2);
                      if (i == 3) onNavigate(2);
                      if (i == 4) onNavigate(2);
                      if (i == 5) onNavigate(3);
                      if (i == 6) onNavigate(4);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? state.accentColor : state.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected ? state.accentColor : state.borderColor,
                        ),
                        boxShadow: selected
                            ? [
                          BoxShadow(
                            color: state.accentColor.withValues(alpha: 0.25),
                            blurRadius: 10,
                          )
                        ]
                            : null,
                      ),
                      child: Text(
                        _categories[i],
                        style: GoogleFonts.prompt(
                          color: selected
                              ? (state.isLightTheme ? Colors.white : const Color(0xFF042F2E))
                              : state.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // ── Daily Challenge strip ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildDailyChallenge(context, state),
            ),
            const SizedBox(height: 28),

            // ── Salary tiers (Discovery cards) ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: state.accentColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: state.accentColor.withValues(alpha: 0.45),
                          blurRadius: 8,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('ประมาณการเงินเดือนสายงาน IT',
                      style: GoogleFonts.prompt(
                          color: state.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth > 700;
                final tiers = [
                  {
                    'label': 'Junior IT / Dev',
                    'range': '฿20–35K',
                    'minXP': 0,
                    'color': const Color(0xFF34D399),
                    'icon': Icons.rocket_launch_outlined,
                    'tag': 'Entry'
                  },
                  {
                    'label': 'Mid-Level Specialist',
                    'range': '฿40–80K',
                    'minXP': 180,
                    'color': const Color(0xFF60A5FA),
                    'icon': Icons.layers_outlined,
                    'tag': 'Growth'
                  },
                  {
                    'label': 'Senior Expert',
                    'range': '฿85–150K',
                    'minXP': 400,
                    'color': const Color(0xFFC084FC),
                    'icon': Icons.workspace_premium_outlined,
                    'tag': 'Expert'
                  },
                  {
                    'label': 'Tech Lead / CTO',
                    'range': '฿180K+',
                    'minXP': 700,
                    'color': const Color(0xFFFBBF24),
                    'icon': Icons.emoji_events_outlined,
                    'tag': 'Lead'
                  },
                ];
                return GridView.count(
                  crossAxisCount: wide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: wide ? 1.15 : 1.05,
                  children: tiers.map((t) {
                    final unlocked = state.totalXP >= (t['minXP'] as int);
                    final color = t['color'] as Color;
                    return Container(
                      decoration: BoxDecoration(
                        color: state.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: unlocked
                              ? color.withValues(alpha: 0.4)
                              : state.borderColor,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: state.isLightTheme ? 0.04 : 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Opacity(
                        opacity: unlocked ? 1 : 0.5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(t['icon'] as IconData, color: color, size: 18),
                                ),
                                const Spacer(),
                                if (!unlocked)
                                  Icon(Icons.lock, color: state.textMuted, size: 14)
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(t['tag'] as String,
                                        style: GoogleFonts.prompt(
                                            color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            Text(t['label'] as String,
                                style: GoogleFonts.prompt(
                                    color: state.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(t['range'] as String,
                                style: GoogleFonts.prompt(
                                    color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ),
            const SizedBox(height: 28),

            // ── Missions as Discovery cards ────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: state.accentColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('ภารกิจแนะนำยอดนิยม',
                      style: GoogleFonts.prompt(
                          color: state.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth > 700;
                final missions = [
                  {
                    'index': 1,
                    'title': 'Greeting Automation Script',
                    'desc': 'เขียน Script ตอบรับและแสดงผลการทักทายผู้ใช้งานระบบอัตโนมัติ',
                    'xp': 40,
                    'hours': '0.5 ชม.',
                    'tag': 'Beginner',
                    'locked': false,
                    'done': state.missionsDone >= 1,
                    'color': const Color(0xFF3B82F6),
                    'icon': Icons.waving_hand_outlined,
                  },
                  {
                    'index': 2,
                    'title': 'System Metric Calculator',
                    'desc': 'สร้างระบบคำนวณและประมวลผลทรัพยากรของเครื่องเซิร์ฟเวอร์',
                    'xp': 60,
                    'hours': '1 ชม.',
                    'tag': 'Intermediate',
                    'locked': state.missionsDone < 1,
                    'done': state.missionsDone >= 2,
                    'color': const Color(0xFF10B981),
                    'icon': Icons.monitor_heart_outlined,
                  },
                  {
                    'index': 3,
                    'title': 'API Data Integration',
                    'desc': 'เชื่อมต่อ REST API ดึงข้อมูลและจัดการแสดงผลแบบ JSON',
                    'xp': 80,
                    'hours': '1.5 ชม.',
                    'tag': 'Intermediate',
                    'locked': state.missionsDone < 2,
                    'done': state.missionsDone >= 3,
                    'color': const Color(0xFFA855F7),
                    'icon': Icons.api_outlined,
                  },
                ];
                return GridView.count(
                  crossAxisCount: wide ? 3 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: wide ? 0.95 : 2.2,
                  children: missions.map((m) {
                    return _missionDiscoveryCard(
                      context: context,
                      state: state,
                      title: m['title'] as String,
                      desc: m['desc'] as String,
                      xp: m['xp'] as int,
                      hours: m['hours'] as String,
                      tag: m['tag'] as String,
                      locked: m['locked'] as bool,
                      done: m['done'] as bool,
                      color: m['color'] as Color,
                      icon: m['icon'] as IconData,
                      onTap: (m['locked'] as bool) ? null : () => onNavigate(4),
                    );
                  }).toList(),
                );
              }),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, AppState state) {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: state.isLightTheme
              ? [const Color(0xFF1E3A8A), const Color(0xFF1D4ED8), const Color(0xFF0EA5E9)]
              : [const Color(0xFF0B1220), const Color(0xFF0F172A), const Color(0xFF064E3B)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // soft circles decor
          Positioned(
            right: -40,
            top: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: 40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state.accentColor.withValues(alpha: 0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: state.accentColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: state.accentColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text('เส้นทางแนะนำประจำสัปดาห์ • อัปเดตใหม่',
                          style: GoogleFonts.prompt(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'ยกระดับทักษะ IT\nสู่การทำงานจริงในอุตสาหกรรม',
                  style: GoogleFonts.prompt(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'เงินเดือนเริ่มต้น ฿20,000–35,000 เติบโตสู่ Senior/Lead ได้ถึง ฿180,000+ ในไทย',
                  style: GoogleFonts.prompt(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _heroChip('Software & Web', state),
                    _heroChip('Data & AI', state),
                    _heroChip('DevOps', state),
                    _heroChip('ระดับเริ่มต้น', state, muted: true),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => onNavigate(1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('ปรึกษา AI Mentor',
                              style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => onNavigate(4),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('เริ่ม Mission',
                          style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroChip(String label, AppState state, {bool muted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: muted
              ? Colors.white.withValues(alpha: 0.2)
              : state.accentColor.withValues(alpha: 0.45),
        ),
      ),
      child: Text(label,
          style: GoogleFonts.prompt(
            color: muted ? Colors.white70 : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          )),
    );
  }

  Widget _buildDailyChallenge(BuildContext context, AppState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: state.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: state.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: state.isLightTheme ? 0.04 : 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.local_fire_department, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('DAILY CHALLENGE',
                          style: GoogleFonts.prompt(
                              color: const Color(0xFFFBBF24),
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    const DailyCountdown(),
                  ],
                ),
                const SizedBox(height: 6),
                Text('IT Problem Solving & Automation',
                    style: GoogleFonts.prompt(
                        color: state.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                Text('เขียน Script ตรวจสอบระบบอัตโนมัติ · +75 XP',
                    style: GoogleFonts.prompt(color: state.textMuted, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => onNavigate(4),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFBBF24),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('รับ Challenge',
                style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _missionDiscoveryCard({
    required BuildContext context,
    required AppState state,
    required String title,
    required String desc,
    required int xp,
    required String hours,
    required String tag,
    required bool locked,
    required bool done,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: state.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: done ? const Color(0xFF10B981).withValues(alpha: 0.45) : state.borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: state.isLightTheme ? 0.04 : 0.18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Opacity(
          opacity: locked ? 0.55 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // thumbnail-like header
              Container(
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.85),
                      color.withValues(alpha: 0.45),
                      state.cardAltColor,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Icon(icon, size: 90, color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  done ? 'Completed' : (locked ? 'Locked' : tag),
                                  style: GoogleFonts.prompt(
                                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Spacer(),
                              if (locked)
                                const Icon(Icons.lock, color: Colors.white70, size: 16)
                              else if (done)
                                const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 18),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFFBBF24), size: 14),
                              Text(' 4.${8 + (xp % 2)}',
                                  style: GoogleFonts.prompt(
                                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                              const Icon(Icons.schedule, color: Colors.white70, size: 14),
                              Text(' $hours',
                                  style: GoogleFonts.prompt(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.prompt(
                              color: state.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.prompt(color: state.textMuted, fontSize: 11, height: 1.35)),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.workspace_premium_outlined, size: 14, color: state.accentColor),
                          const SizedBox(width: 4),
                          Text('+$xp XP',
                              style: GoogleFonts.prompt(
                                  color: state.accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: state.cardAltColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.play_arrow, size: 16, color: state.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// TAB 2: AI MENTOR CHAT
// ==========================================
