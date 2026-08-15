import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:confetti/confetti.dart';
import 'package:webview_flutter/webview_flutter.dart';

// --------------------------------------------------
// Local GoogleFonts compatibility shim
// --------------------------------------------------
class GoogleFonts {
  static TextStyle prompt({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: 'Prompt',
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }

  static TextStyle jetBrainsMono({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: 'JetBrains Mono',
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }
}

// ==========================================
// SHARED CONSTANTS / DATA
// ==========================================
const String kMentorApiUrl = "https://open-garlics-poke.loca.lt/api/mentor";

class SalaryTier {
  final int xp;
  final int salary;
  final String role;
  const SalaryTier(this.xp, this.salary, this.role);
}

const List<SalaryTier> kSalaryTiers = [
  SalaryTier(0, 20000, "Junior IT Specialist (Entry)"),
  SalaryTier(40, 25000, "Junior IT / Developer"),
  SalaryTier(100, 35000, "Junior IT Specialist (Advanced)"),
  SalaryTier(180, 45000, "Mid-Level IT Specialist"),
  SalaryTier(300, 65000, "Mid-Level Engineer / Analyst"),
  SalaryTier(400, 90000, "Senior IT Specialist"),
  SalaryTier(500, 130000, "Senior Solution Architect"),
  SalaryTier(700, 180000, "Tech Lead / CTO"),
];

class BadgeDef {
  final String id;
  final String emoji;
  final String name;
  final String desc;
  const BadgeDef(this.id, this.emoji, this.name, this.desc);
}

const List<BadgeDef> kBadges = [
  BadgeDef('first_run', '▶️', 'First Run', 'รันโค้ดครั้งแรก'),
  BadgeDef('first_pass', '✅', 'Test Passer', 'ผ่าน Test แรก'),
  BadgeDef('streak3', '🔥', 'On Fire!', '3 วันติดต่อกัน'),
  BadgeDef('xp50', '⭐', 'Rising Star', 'สะสม 50 XP'),
  BadgeDef('xp100', '💯', 'Century Club', 'สะสม 100 XP'),
  BadgeDef('mission1', '🎯', 'Mission Pro', 'ผ่าน Mission 1'),
  BadgeDef('coder', '👨‍💻', 'IT Practitioner', 'ใช้งาน Sandbox 10 ครั้ง'),
  BadgeDef('xp200', '🚀', 'Rocket Dev', 'สะสม 200 XP'),
];

// --------------------------------------------------
// SANDBOX MISSIONS (multi-mission catalogue)
// --------------------------------------------------
class SandboxTestCase {
  final String input;
  final String expectedContains;
  final String label;
  const SandboxTestCase(this.input, this.expectedContains, this.label);

  String get expected => expectedContains;
}

class SandboxMission {
  final String id;
  final String title;
  final String description;
  final String starterCode;
  final int xpReward;
  final List<SandboxTestCase> tests;
  const SandboxMission({
    required this.id,
    required this.title,
    required this.description,
    required this.starterCode,
    required this.xpReward,
    required this.tests,
  });
}

const List<SandboxMission> kSandboxMissions = [
  SandboxMission(
    id: 'greeting',
    title: 'Greeting Automation Script',
    description: 'รับชื่อผู้ใช้งานผ่าน input() แล้ว print คำทักทายว่า "Hello, [ชื่อ]!"',
    starterCode: "",
    xpReward: 40,
    tests: [
      SandboxTestCase('John', 'Hello, John!', 'input "John" → "Hello, John!"'),
      SandboxTestCase('สมชาย', 'Hello, สมชาย!', 'input "สมชาย" → "Hello, สมชาย!"'),
    ],
  ),
  SandboxMission(
    id: 'even_odd',
    title: 'Server Health Even/Odd Checker',
    description: 'รับตัวเลขจาก input() แล้วตรวจสอบว่าเป็นเลขคู่หรือคี่ พิมพ์คำว่า "Even" หรือ "Odd" เพียงคำเดียว',
    starterCode:
    "num = int(input('Enter a number: '))\nif num % 2 == 0:\n    print('Even')\nelse:\n    print('Odd')",
    xpReward: 50,
    tests: [
      SandboxTestCase('4', 'Even', 'input "4" → "Even"'),
      SandboxTestCase('7', 'Odd', 'input "7" → "Odd"'),
    ],
  ),
  SandboxMission(
    id: 'sum_list',
    title: 'Log Uptime Summation',
    description:
    'รับตัวเลขคั่นด้วย comma จาก input() (เช่น "1,2,3") แล้วคำนวณผลรวม พิมพ์ผลลัพธ์ในรูปแบบ "Total: X"',
    starterCode:
    "data = input('Enter numbers (comma separated): ')\nnums = [int(x) for x in data.split(',')]\nprint(f\"Total: {sum(nums)}\")",
    xpReward: 60,
    tests: [
      SandboxTestCase('1,2,3', 'Total: 6', 'input "1,2,3" → "Total: 6"'),
      SandboxTestCase('10,20', 'Total: 30', 'input "10,20" → "Total: 30"'),
    ],
  ),
  SandboxMission(
    id: 'password_strength',
    title: 'Password Strength Auditor',
    description:
    'รับรหัสผ่านจาก input() หากความยาว >= 8 ตัวอักษร ให้พิมพ์ "Strong" ไม่เช่นนั้นพิมพ์ "Weak"',
    starterCode:
    "pwd = input('Enter password: ')\nif len(pwd) >= 8:\n    print('Strong')\nelse:\n    print('Weak')",
    xpReward: 70,
    tests: [
      SandboxTestCase('abc123', 'Weak', 'input "abc123" → "Weak"'),
      SandboxTestCase('abcd1234', 'Strong', 'input "abcd1234" → "Strong"'),
    ],
  ),
];

String formatMoney(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

// --------------------------------------------------
// TOAST NOTIFICATION (real functional replacement of JS showToast)
// --------------------------------------------------
enum ToastType { success, error, info, badge }

void showAppToast(BuildContext context, String message, {ToastType type = ToastType.success}) {
  IconData icon;
  Color iconColor;
  switch (type) {
    case ToastType.success:
      icon = Icons.check_circle;
      iconColor = const Color(0xFF34D399);
      break;
    case ToastType.error:
      icon = Icons.cancel;
      iconColor = const Color(0xFFF87171);
      break;
    case ToastType.info:
      icon = Icons.lightbulb;
      iconColor = const Color(0xFFFBBF24);
      break;
    case ToastType.badge:
      icon = Icons.military_tech;
      iconColor = const Color(0xFFC084FC);
      break;
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF0F172A),
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      content: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: GoogleFonts.prompt(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    ),
  );
}

// --------------------------------------------------
// SALARY UNLOCK OVERLAY (real functional replacement of #salary-overlay)
// --------------------------------------------------
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
                const Text('🎉', style: TextStyle(fontSize: 48)),
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
                    _rewardPill('XP ได้รับ', '+${widget.xpGained} XP', const Color(0xFF1E3A8A), const Color(0xFF93C5FD)),
                    const SizedBox(width: 12),
                    _rewardPill('Streak', '${widget.streakDays} วัน 🔥', const Color(0xFF78350F), const Color(0xFFFCD34D)),
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

Widget _rewardPill(String label, String value, Color bg, Color fg) {
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const LearnProApp(),
    ),
  );
}

// ==========================================
// STATE MANAGEMENT & DATA MODELS
// ==========================================
class AppState extends ChangeNotifier {
  int totalXP = 20;
  int streakDays = 3;
  int missionsDone = 0;
  int runCount = 0;
  String selectedTrack = 'swe';

  final Set<String> earnedBadges = {};
  final List<BadgeDef> pendingBadgeToasts = [];
  final Set<String> completedMissionIds = {};

  int get multiplier => streakDays >= 7 ? 3 : (streakDays >= 3 ? 2 : 1);

  SalaryTier get _tier {
    SalaryTier t = kSalaryTiers.first;
    for (final s in kSalaryTiers) {
      if (totalXP >= s.xp) {
        t = s;
      } else {
        break;
      }
    }
    return t;
  }

  int get currentSalary => _tier.salary;
  String get currentRole => _tier.role;
  int get level => (totalXP ~/ 100) + 1;
  int get xpIntoLevel => totalXP % 100;

  void addXP(int amount) {
    final gained = amount * multiplier;
    totalXP += gained;
    _checkBadges();
    notifyListeners();
  }

  void incrementRunCount() {
    runCount++;
    _checkBadges();
    notifyListeners();
  }

  void completeMission(int xp) {
    missionsDone++;
    addXP(xp);
  }

  void completeMissionById(String missionId, int xp) {
    if (!completedMissionIds.contains(missionId)) {
      completedMissionIds.add(missionId);
      missionsDone++;
    }
    addXP(xp);
  }

  void selectTrack(String track) {
    selectedTrack = track;
    notifyListeners();
  }

  List<BadgeDef> _checkBadges() {
    final newlyEarned = <BadgeDef>[];
    void mark(String id) {
      if (!earnedBadges.contains(id)) {
        earnedBadges.add(id);
        final def = kBadges.firstWhere((b) => b.id == id);
        newlyEarned.add(def);
      }
    }

    if (runCount >= 1) mark('first_run');
    if (runCount >= 10) mark('coder');
    if (totalXP >= 40) mark('first_pass');
    if (totalXP >= 50) mark('xp50');
    if (totalXP >= 100) mark('xp100');
    if (totalXP >= 200) mark('xp200');
    if (missionsDone >= 1) mark('mission1');
    if (streakDays >= 3) mark('streak3');
    return newlyEarned;
  }

  List<BadgeDef> checkBadgesAndReturnNew() {
    final n = _checkBadges();
    if (n.isNotEmpty) notifyListeners();
    return n;
  }

  void resetProgress() {
    totalXP = 20;
    missionsDone = 0;
    runCount = 0;
    earnedBadges.clear();
    completedMissionIds.clear();
    selectedTrack = 'swe';
    notifyListeners();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

// ==========================================
// MAIN APP ENTRY
// ==========================================
class LearnProApp extends StatelessWidget {
  const LearnProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LearnPro MAX — IT Career Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080C14),
        primaryColor: const Color(0xFF10B981),
      ),
      home: const MainLayoutScreen(),
    );
  }
}

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
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: Text('รีเซ็ตความคืบหน้า?', style: GoogleFonts.prompt(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('ล้างความคืบหน้าทั้งหมดเพื่อเริ่มใหม่หรือไม่?',
            style: GoogleFonts.prompt(color: const Color(0xFF94A3B8), fontSize: 13)),
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
      ),
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
    ];

    return Scaffold(
      body: Row(
        children: [
          if (isWide) _buildDesktopSidebar(context, state),
          Expanded(child: tabs[_currentIndex]),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _goTo,
        backgroundColor: const Color(0xFF0A0F1A),
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: const Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'หลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_rounded), label: 'AI Mentor'),
          BottomNavigationBarItem(icon: Icon(Icons.alt_route_rounded), label: 'Tracks'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart_rounded), label: 'Career'),
          BottomNavigationBarItem(icon: Icon(Icons.terminal_rounded), label: 'Code'),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, AppState state) {
    return Container(
      width: 264,
      color: const Color(0xFF0A0F1A),
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
                        children: const [
                          TextSpan(text: 'Learn', style: TextStyle(color: Colors.white)),
                          TextSpan(text: 'Pro', style: TextStyle(color: Color(0xFF10B981))),
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
                  Text('💰 เงินเดือนเป้าหมาย IT',
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
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showAchievementsDialog(context, state),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ACHIEVEMENTS',
                      style: GoogleFonts.prompt(
                          color: const Color(0xFF475569), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Level ${state.level}',
                          style: GoogleFonts.prompt(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF1E293B)),
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
                    Text('🏆 Achievements',
                        style: GoogleFonts.prompt(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
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
                                opacity: earned ? 1 : 0.3,
                                child: Text(b.emoji, style: const TextStyle(fontSize: 26)),
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
          message: earned ? '${b.name}: ${b.desc}' : '🔒 ยังไม่ได้รับ',
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: earned ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: earned ? const Color(0xFF334155) : const Color(0xFF1E293B)),
            ),
            child: Opacity(
              opacity: earned ? 1 : 0.25,
              child: Text(b.emoji, style: const TextStyle(fontSize: 15)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavButton(BuildContext context, int index, IconData icon, String label) {
    bool isActive = _currentIndex == index;
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
            Icon(icon, color: isActive ? Colors.white : const Color(0xFF94A3B8), size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.prompt(
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
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
// ==========================================
class ITCenterDashboardScreen extends StatelessWidget {
  final void Function(int) onNavigate;
  const ITCenterDashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF0C1A2E)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade900.withValues(alpha:0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🚀 เส้นทางเติบโตในสายงาน IT',
                      style: GoogleFonts.prompt(color: Colors.blue.shade300, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'ยกระดับทักษะ IT สู่การทำงานจริงในอุตสาหกรรม',
                    style: GoogleFonts.prompt(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'สายงาน IT มีเงินเดือนเริ่มต้น ฿20,000 - ฿35,000 และเติบโตสู่ Senior/Lead ได้ถึง ฿180,000+ ในไทย',
                    style: GoogleFonts.prompt(color: const Color(0xFF94A3B8), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => onNavigate(1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
                    label: Text('ปรึกษา AI Mentor',
                        style: GoogleFonts.prompt(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Daily Challenge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF78350F), Color(0xFF92400E)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha:0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(6)),
                        child: Text('DAILY CHALLENGE',
                            style: GoogleFonts.prompt(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      const DailyCountdown(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('🎯 "IT Problem Solving & Automation"',
                      style: GoogleFonts.prompt(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('เขียนโปรแกรมหรือ Script ตรวจสอบระบบอัตโนมัติ เพื่อเพิ่มความเร็วในการทำงาน',
                      style: GoogleFonts.prompt(color: const Color(0xFFFDE68A), fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => onNavigate(4),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('รับ Challenge (+75 XP)',
                            style: GoogleFonts.prompt(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('ประมาณการเงินเดือนสายงาน IT ในไทย',
                style: GoogleFonts.prompt(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth > 700;
              final tiers = [
                {'label': 'Junior IT / Dev', 'range': '฿20–35K', 'minXP': 0, 'color': const Color(0xFF34D399)},
                {'label': 'Mid-Level Specialist', 'range': '฿40–80K', 'minXP': 180, 'color': const Color(0xFF60A5FA)},
                {'label': 'Senior Expert', 'range': '฿85–150K', 'minXP': 400, 'color': const Color(0xFFC084FC)},
                {'label': 'Tech Lead / CTO', 'range': '฿180K+', 'minXP': 700, 'color': const Color(0xFFFBBF24)},
              ];
              return GridView.count(
                crossAxisCount: wide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.3,
                children: tiers.map((t) {
                  final unlocked = state.totalXP >= (t['minXP'] as int);
                  final color = t['color'] as Color;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha:0.35)),
                    ),
                    child: Opacity(
                      opacity: unlocked ? 1 : 0.45,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(t['label'] as String,
                                    style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              if (!unlocked) const Icon(Icons.lock, color: Color(0xFF475569), size: 12),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(t['range'] as String,
                              style: GoogleFonts.prompt(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 24),

            Text('ภารกิจพื้นฐาน (General IT Missions)',
                style: GoogleFonts.prompt(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _missionTile(
              context,
              index: 1,
              title: 'Greeting Automation Script',
              desc: 'เขียน Script ตอบรับและแสดงผลการทักทายผู้ใช้งานระบบอัตโนมัติ',
              xp: 40,
              money: 5000,
              locked: false,
              done: state.missionsDone >= 1,
              onTap: () => onNavigate(4),
            ),
            const SizedBox(height: 10),
            _missionTile(
              context,
              index: 2,
              title: 'System Metric Calculator',
              desc: 'สร้างระบบคำนวณและประมวลผลทรัพยากรของเครื่องเซิร์ฟเวอร์',
              xp: 60,
              money: 8000,
              locked: state.missionsDone < 1,
              done: state.missionsDone >= 2,
              onTap: state.missionsDone >= 1 ? () => onNavigate(4) : null,
            ),
            const SizedBox(height: 10),
            _missionTile(
              context,
              index: 3,
              title: 'API Data Integration',
              desc: 'เชื่อมต่อ REST API ดึงข้อมูลและจัดการแสดงผลแบบ JSON',
              xp: 80,
              money: 12000,
              locked: state.missionsDone < 2,
              done: state.missionsDone >= 3,
              onTap: state.missionsDone >= 2 ? () => onNavigate(4) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _missionTile(
      BuildContext context, {
        required int index,
        required String title,
        required String desc,
        required int xp,
        required int money,
        required bool locked,
        required bool done,
        VoidCallback? onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
              color: done
                  ? const Color(0xFF10B981)
                  : (locked ? const Color(0xFF334155) : const Color(0xFF3B82F6)),
              width: 3,
            ),
          ),
        ),
        child: Opacity(
          opacity: locked ? 0.5 : 1,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: locked ? const Color(0xFF0B1220) : const Color(0xFF1E3A8A).withValues(alpha:0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: done
                    ? const Icon(Icons.check, color: Color(0xFF34D399), size: 18)
                    : Text('0$index', style: GoogleFonts.jetBrainsMono(color: const Color(0xFF60A5FA), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(title, style: GoogleFonts.prompt(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                        if (locked) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.lock, color: Color(0xFF64748B), size: 12)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(desc, style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+$xp XP', style: GoogleFonts.prompt(color: const Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('+฿${formatMoney(money)}', style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 9)),
                ],
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
class AIMentorChatScreen extends StatefulWidget {
  const AIMentorChatScreen({super.key});

  @override
  State<AIMentorChatScreen> createState() => _AIMentorChatScreenState();
}

class _AIMentorChatScreenState extends State<AIMentorChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "สวัสดีครับ! ผมคือ **AI Mentor** ผู้ช่วยวางแผนเส้นทางอาชีพ IT ของคุณ วันนี้อยากปรึกษาเรื่องทักษะ คอร์สเรียน หรือจำลองการสัมภาษณ์งานดีครับ?",
      isUser: false,
    ),
  ];
  bool _isLoading = false;

  final List<String> _quickPrompts = const [
    'เตรียมพอร์ตยังไงให้ได้งานแรก',
    'ไม่ได้จบตรงสายเริ่มยังไง',
    'จำลองสัมภาษณ์งานตำแหน่ง Junior',
    'ทักษะที่ตลาดต้องการมากที่สุด',
    'ฐานเงินเดือนเริ่มต้นแต่ละสาย',
  ];

  final Map<String, String> _quickPromptFull = const {
    'เตรียมพอร์ตยังไงให้ได้งานแรก':
    'เด็กจบใหม่ไม่มีประสบการณ์ ควรเริ่มเตรียมพอร์ตโฟลิโออย่างไรให้เตะตากรรมการ',
    'ไม่ได้จบตรงสายเริ่มยังไง':
    'อยากเริ่มทำงานสาย IT แต่ไม่ได้จบตรงสาย ต้องวางแผนและเริ่มเรียนรู้จากอะไรก่อน',
    'จำลองสัมภาษณ์งานตำแหน่ง Junior':
    'ช่วยจำลองคำถามสัมภาษณ์งานตำแหน่ง Junior Developer และแนวทางการตอบให้หน่อย',
    'ทักษะที่ตลาดต้องการมากที่สุด':
    'ทักษะหรือสกิลที่ตลาดแรงงาน IT ต้องการมากที่สุดตอนนี้มีอะไรบ้าง',
    'ฐานเงินเดือนเริ่มต้นแต่ละสาย':
    'ฐานเงินเดือนเริ่มต้นของสายงาน IT แต่ละสายงานอยู่ที่ประมาณเท่าไหร่',
  };

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(kMentorApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
        },
        body: jsonEncode({'message': text}),
      ).timeout(const Duration(seconds: 25));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add(ChatMessage(text: data['reply'] ?? 'ไม่สามารถดึงข้อมูลคำตอบได้', isUser: false));
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(text: 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ (${response.statusCode})', isUser: false));
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: 'ไม่สามารถเชื่อมต่อ AI Mentor API ได้ ($e)', isUser: false));
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF10B981),
              radius: 16,
              child: Icon(Icons.smart_toy, size: 18, color: Colors.black),
            ),
            const SizedBox(width: 10),
            Text('AI Mentor Assistant v2.0', style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: msg.isUser ? const Color(0xFF059669) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: msg.isUser ? null : Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: MarkdownBody(
                      data: msg.text,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: GoogleFonts.prompt(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2.5),
              ),
            ),
          Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final label = _quickPrompts[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _isLoading ? null : () => _sendMessage(_quickPromptFull[label] ?? label),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF022C22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF065F46)),
                      ),
                      alignment: Alignment.center,
                      child: Text(label, style: GoogleFonts.prompt(color: const Color(0xFF34D399), fontSize: 11)),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.prompt(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'พิมพ์คำถามปรึกษา AI...',
                      hintStyle: GoogleFonts.prompt(color: const Color(0xFF64748B)),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF10B981)),
                  onPressed: _isLoading ? null : () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 3: IT TRACKS & FIELDS
// ==========================================
class ITTracksScreen extends StatelessWidget {
  const ITTracksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('เลือกสายงาน IT (Specialization Tracks)',
                style: GoogleFonts.prompt(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('แตะเพื่อเลือกสายงานที่คุณสนใจ ระบบจะจดจำสายงานที่เลือกไว้',
                style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 16),
            _buildTrackCard(context, state, 'swe', 'Software & Web Development', 'Frontend / Backend / Full-Stack',
                'พัฒนาแอปพลิเคชัน เว็บไซต์ และซอฟต์แวร์ระบบ', Icons.code, Colors.blue,
                ['Python', 'Node.js', 'React', 'SQL']),
            _buildTrackCard(context, state, 'data', 'Data & AI Engineering', 'Data Science / ML / Data Analyst',
                'วิเคราะห์ข้อมูล และสร้างแบบจำลอง AI Machine Learning', Icons.psychology, Colors.purple,
                ['Python', 'Pandas', 'SQL', 'PowerBI']),
            _buildTrackCard(context, state, 'devops', 'Cloud & DevOps', 'Cloud Engineer / SysAdmin / CI/CD',
                'ดูแลโครงสร้างพื้นฐานคลาวด์ และระบบอัตโนมัติ', Icons.cloud, const Color(0xFF10B981),
                ['AWS/GCP', 'Docker', 'Linux', 'Terraform']),
            _buildTrackCard(context, state, 'sec', 'Cybersecurity', 'SOC Analyst / Security / Pentester',
                'คุ้มครองและป้องกันระบบสารสนเทศ ตรวจจับช่องโหว่', Icons.security, const Color(0xFFF43F5E),
                ['Network', 'Linux', 'SIEM', 'Wireshark']),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackCard(
      BuildContext context,
      AppState state,
      String id,
      String title,
      String subtitle,
      String desc,
      IconData icon,
      Color color,
      List<String> tags) {
    final active = state.selectedTrack == id;
    return InkWell(
      onTap: () {
        context.read<AppState>().selectTrack(id);
        showAppToast(context, 'เปลี่ยนเป็นสายงาน: $title', type: ToastType.info);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF10B981).withValues(alpha:0.08) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: active ? const Color(0xFF10B981) : const Color(0xFF1E293B),
              width: active ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: color.withValues(alpha:0.2), radius: 24, child: Icon(icon, color: color)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                              child: Text(title,
                                  style: GoogleFonts.prompt(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
                          if (active)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFF065F46), borderRadius: BorderRadius.circular(6)),
                                child: Text('เลือกอยู่',
                                    style: GoogleFonts.prompt(color: const Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                      Text(subtitle, style: GoogleFonts.jetBrainsMono(color: color, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(desc, style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(6)),
                child: Text(t, style: GoogleFonts.jetBrainsMono(color: const Color(0xFFCBD5E1), fontSize: 10)),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 4: CAREER ROADMAP & RADAR CHART
// ==========================================
class CareerRoadmapScreen extends StatelessWidget {
  const CareerRoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Career Roadmap (IT Industry)',
                style: GoogleFonts.prompt(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('บันไดความก้าวหน้าและฐานเงินเดือนจริงในอุตสาหกรรม IT ไทย',
                style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 20),
            _roadmapStep(state,
                emoji: '🟢',
                title: 'Junior IT / Dev Specialist',
                requiredXP: 0,
                skills: 'ทักษะพื้นฐาน Coding, Basic Scripting, Database Fundamentals, Network Intro',
                start: 20000,
                avg: 28000,
                max: 35000,
                years: '0–2 ปี',
                color: const Color(0xFF10B981)),
            _roadmapArrow(),
            _roadmapStep(state,
                emoji: '🔵',
                title: 'Mid-Level IT Specialist',
                requiredXP: 180,
                skills: 'OOP, API Design, Containerization, Automation & Security Basics',
                start: 40000,
                avg: 60000,
                max: 80000,
                years: '2–5 ปี',
                color: const Color(0xFF3B82F6)),
            _roadmapArrow(),
            _roadmapStep(state,
                emoji: '🟣',
                title: 'Senior IT Expert / Specialist',
                requiredXP: 400,
                skills: 'System Design, High Availability, Cloud Architecture, Advanced Security',
                start: 85000,
                avg: 115000,
                max: 150000,
                years: '5+ ปี',
                color: const Color(0xFFA855F7)),
            _roadmapArrow(),
            _roadmapStep(state,
                emoji: '👑',
                title: 'Tech Lead / Solution Architect / CTO',
                requiredXP: 700,
                skills: 'IT Strategy, Enterprise Architecture, Business Alignment, Leadership',
                start: 180000,
                avg: 250000,
                max: -1,
                years: '8+ ปี',
                color: const Color(0xFFF59E0B)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.radar, color: Color(0xFF60A5FA), size: 18),
                      const SizedBox(width: 8),
                      Text('IT Multi-Domain Skill Analysis',
                          style: GoogleFonts.prompt(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: RadarChart(
                      RadarChartData(
                        radarShape: RadarShape.polygon,
                        ticksTextStyle: const TextStyle(color: Colors.transparent),
                        titlePositionPercentageOffset: 0.2,
                        getTitle: (index, angle) {
                          const labels = ['Coding', 'System', 'DevOps', 'Database', 'Security'];
                          return RadarChartTitle(text: labels[index % labels.length]);
                        },
                        dataSets: [
                          RadarDataSet(
                            fillColor: const Color(0xFF3B82F6).withValues(alpha:0.15),
                            borderColor: const Color(0xFF3B82F6),
                            entryRadius: 2,
                            dataEntries: const [
                              RadarEntry(value: 85),
                              RadarEntry(value: 80),
                              RadarEntry(value: 75),
                              RadarEntry(value: 75),
                              RadarEntry(value: 70),
                            ],
                          ),
                          RadarDataSet(
                            fillColor: const Color(0xFF10B981).withValues(alpha:0.25),
                            borderColor: const Color(0xFF10B981),
                            entryRadius: 3,
                            dataEntries: [
                              RadarEntry(value: (state.totalXP / 8).clamp(5, 100).toDouble()),
                              RadarEntry(value: (state.totalXP / 10).clamp(5, 100).toDouble()),
                              RadarEntry(value: (state.totalXP / 12).clamp(5, 100).toDouble()),
                              RadarEntry(value: (state.totalXP / 9).clamp(5, 100).toDouble()),
                              RadarEntry(value: (state.totalXP / 14).clamp(5, 100).toDouble()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roadmapArrow() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Center(child: Icon(Icons.arrow_downward, color: Color(0xFF334155), size: 16)),
  );

  Widget _roadmapStep(
      AppState state, {
        required String emoji,
        required String title,
        required int requiredXP,
        required String skills,
        required int start,
        required int avg,
        required int max,
        required String years,
        required Color color,
      }) {
    final unlocked = state.totalXP >= requiredXP;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? color.withValues(alpha:0.08) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: unlocked ? color.withValues(alpha:0.4) : const Color(0xFF1E293B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha:0.15), borderRadius: BorderRadius.circular(16)),
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(title,
                        style: GoogleFonts.prompt(
                            color: unlocked ? Colors.white : const Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: unlocked ? color.withValues(alpha:0.2) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        unlocked ? 'UNLOCKED' : 'ล็อก (ต้องการ $requiredXP XP)',
                        style: GoogleFonts.prompt(
                            color: unlocked ? color : const Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(skills, style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 11)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statBox('เริ่มต้น', '฿${formatMoney(start)}', color),
                    const SizedBox(width: 8),
                    _statBox('เฉลี่ย', '฿${formatMoney(avg)}', color),
                    const SizedBox(width: 8),
                    _statBox('สูงสุด', max > 0 ? '฿${formatMoney(max)}' : 'Unlimited', color),
                    const SizedBox(width: 8),
                    _statBox('ระยะเวลา', years, const Color(0xFF94A3B8)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.prompt(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(label, style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 8)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 5: LIVE SANDBOX (DESKTOP PYTHON + MOBILE PYODIDE)
// ==========================================
class LiveSandboxScreen extends StatefulWidget {
  const LiveSandboxScreen({super.key});

  @override
  State<LiveSandboxScreen> createState() => _LiveSandboxScreenState();
}

class _LiveSandboxScreenState extends State<LiveSandboxScreen> {
  int _missionIndex = 0;

  SandboxMission get _mission => kSandboxMissions[_missionIndex];

  late final TextEditingController _codeController =
  TextEditingController(text: kSandboxMissions[0].starterCode);
  final TextEditingController _consoleInputController = TextEditingController();
  final ScrollController _consoleScrollController = ScrollController();

  String _output = "System ready. Select a script to run.\n";
  bool _isReady = false;
  bool _isRunning = false;
  bool _isTesting = false;

  late List<bool?> _testResults = List<bool?>.filled(
      _mission.tests.length, null);

  bool _hintVisible = false;
  bool _hintLoading = false;
  String _hintText = '';

  bool _isDesktop = false;
  String _pythonCommand = '';

  late final WebViewController _webViewController;
  Completer<String>? _pendingCompleter;

  // Multi-file project support
  Map<String, String> _projectFiles = {
    'main.py': kSandboxMissions[0].starterCode,
  };
  String _activeFileName = 'main.py';

  @override
  void initState() {
    super.initState();
    _initEnvironment();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _consoleInputController.dispose();
    _consoleScrollController.dispose();
    super.dispose();
  }

  void _appendOutput(String text) {
    setState(() => _output += text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_consoleScrollController.hasClients) {
        _consoleScrollController.jumpTo(
            _consoleScrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _initEnvironment() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      _isDesktop = true;
      await _checkLocalPython();
    } else {
      _isDesktop = false;
      _initMobilePyodide();
    }
  }

  // --------------------------------------------------
  // DESKTOP (LOCAL PYTHON)
  // --------------------------------------------------
  Future<void> _checkLocalPython() async {
    final candidates = <String>['python3', 'python', 'py'];
    for (final command in candidates) {
      try {
        final args = command == 'py' ? <String>['-3', '--version'] : <String>[
          '--version'
        ];
        final result = await Process
            .run(command, args, runInShell: true)
            .timeout(const Duration(seconds: 5));

        if (result.exitCode == 0) {
          if (!mounted) return;
          setState(() {
            _pythonCommand = command;
            _isReady = true;
            _output += "\n✅ [Desktop Mode] Python พร้อมใช้งานแล้ว ($command)";
          });
          return;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _isReady = false;
      _output =
      "❌ ไม่พบ Python ในเครื่อง\nติดตั้ง Python 3 จาก python.org แล้วเปิดแอปใหม่";
    });
  }


  Future<void> _runDesktopCode() async {
    final code = _codeController.text;
    _appendOutput("\n\n▶ Executing main.py...\n");

    File? tempFile;
    try {
      // 1. แอบสร้างไฟล์ temp_sandbox.py ชั่วคราว เพื่อแก้ปัญหา Windows ตัดโค้ดหลายบรรทัดทิ้ง
      tempFile = File('temp_sandbox.py');
      await tempFile.writeAsString(code);

      // 2. สั่งรันจากไฟล์โดยตรงแทนการใช้ -c
      final args = _pythonCommand == 'py'
          ? <String>['-3', '-u', tempFile.path]
          : <String>['-u', tempFile.path];

      // ปิด runInShell เพื่อให้รันได้เสถียรที่สุด
      final process = await Process.start(_pythonCommand, args);

      // ส่งค่าจากช่อง Input
      final testInput = _consoleInputController.text;

      process.stdin.writeln(testInput);
      await process.stdin.close();

// ดึงผลลัพธ์
      final stdoutText = await process.stdout.transform(utf8.decoder).join();
      final stderrText = await process.stderr.transform(utf8.decoder).join();

      if (!mounted) return;

      final buffer = StringBuffer();

      // 1. จัดการ Output ปกติ
      if (stdoutText.isNotEmpty) {
        buffer.write(stdoutText); // ใช้ write แทน writeln เพื่อรักษาข้อความเดิม

        // 💡 เช็คว่าถ้าข้อความสุดท้ายไม่ใช่การขึ้นบรรทัดใหม่ ให้ขึ้นบรรทัดใหม่รอไว้เลย
        // เพื่อป้องกันไม่ให้ข้อความ Error ไปต่อท้ายในบรรทัดเดียวกัน
        if (!stdoutText.endsWith('\n')) {
          buffer.writeln();
        }
      }

      // 2. จัดการ Error
      if (stderrText.isNotEmpty) {
        // 💡 ดักจับ Error กรณีที่ผู้ใช้ลืมพิมพ์ตัวเลขส่งเข้าไปโดยเฉพาะ
        if (stderrText.contains("ValueError: invalid literal for int()")) {
          buffer.writeln("⚠️ โปรแกรมถูกยกเลิก: กรุณาพิมพ์ตัวเลขในช่องด้านล่างก่อนรันครับ");
        } else {
          // ถ้าเป็น Error ชนิดอื่นๆ ให้ดึงมาแค่บรรทัดสุดท้ายที่บอกสาเหตุ
          final errorLines = stderrText.trim().split('\n');
          final actualError = errorLines.isNotEmpty ? errorLines.last : 'เกิดข้อผิดพลาด';
          buffer.writeln("⚠️ แจ้งเตือน: $actualError");
        }
      }

      setState(() {
        _output += buffer.toString();
        _isRunning = false;
      });

      _consoleInputController.clear();

    } catch (e) {
      setState(() {
        _output += "[System Error] ไม่สามารถรัน Python ได้\n$e";
        _isRunning = false;
      });
    } finally {
      // 3. ลบไฟล์ชั่วคราวทิ้งเสมอเมื่อรันจบ เพื่อไม่ให้รกเครื่อง
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }
  // --------------------------------------------------
  // MOBILE (PYODIDE WEBVIEW)
  // --------------------------------------------------
  void _initMobilePyodide() {
    const String pyodideHtml = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="https://cdn.jsdelivr.net/pyodide/v0.24.1/full/pyodide.js"></script>
      </head>
      <body style=" {
                  040709; color: white;">
        <script>

                }          let pyodide;
          async function main() {
            try {
              pyodide = await loadPyodide();
              SandboxChannel.postMessage("READY");
            } catch(e) {
              SandboxChannel.postMessage("ERROR: " + e.message);
            }
          }
          main();

          async function runPython(code, inputValue) {
            try {
              let output = "";
              pyodide.setStdout({ batched: (msg) => { output += msg + "\\n"; } });
              pyodide.setStderr({ batched: (msg) => { output += "[stderr] " + msg + "\\n"; } });

              const inputJson = JSON.stringify(inputValue);
              const prepCode = "import builtins\\ndef mock_input(prompt=''):\\n    return " + inputJson + "\\nbuiltins.input = mock_input\\n" + code;

              await pyodide.runPythonAsync(prepCode);
              SandboxChannel.postMessage("RESULT: " + output);
            } catch (err) {
              SandboxChannel.postMessage("ERROR: " + err.message);
            }
          }
        </script>
      </body>
      </html>
    ''';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'SandboxChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == "READY") {
            setState(() {
              _isReady = true;
              _output += "\n✅ [Mobile Mode] Pyodide พร้อมใช้งานแล้ว";
            });
          } else if (message.message.startsWith("RESULT: ")) {
            final text = message.message.replaceFirst("RESULT: ", "").trim();
            if (_pendingCompleter != null) {
              final c = _pendingCompleter!;
              _pendingCompleter = null;
              if (!c.isCompleted) c.complete(text);
            } else {
              setState(() {
                _output += text;
                if (_output.endsWith("Executing main.py...\n")) {
                  _output += "Script finished successfully.";
                }
                _isRunning = false;
              });
            }
          } else if (message.message.startsWith("ERROR: ")) {
            final text = message.message.replaceFirst("ERROR: ", "");
            if (_pendingCompleter != null) {
              final c = _pendingCompleter!;
              _pendingCompleter = null;
              if (!c.isCompleted) c.complete("[Error] $text");
            } else {
              setState(() {
                _output += "[Python Error]\n$text";
                _isRunning = false;
              });
            }
          }
        },
      )
      ..loadHtmlString(pyodideHtml);
  }

  void _runMobileCode() {
    final code = _codeController.text;
    _appendOutput("\n\n▶ Executing on Pyodide...\n");
    final argsStr = '${jsonEncode(code)}, ${jsonEncode("5")}';
    _webViewController.runJavaScript('runPython($argsStr);');
  }


  // --------------------------------------------------
  // EXECUTE / RESET
  // --------------------------------------------------
  void _execute() {
    if (!_isReady || _isRunning) return;
    if (_codeController.text
        .trim()
        .isEmpty) {
      _appendOutput("\n[Error] กรุณาใส่ Python code ก่อน");
      return;
    }

    // Keep project map in sync with current editor content
    _projectFiles[_activeFileName] = _codeController.text;

    setState(() => _isRunning = true);
    context.read<AppState>().incrementRunCount();
    _announceNewBadges();

    if (_isDesktop) {
      _runDesktopCode();
    } else {
      _runMobileCode();
    }
  }

  void _clearConsole() {
    setState(() {
      _output = "System ready. Select a script to run.\n";
    });
  }

  void _selectMission(int index) {
    if (index == _missionIndex || _isRunning || _isTesting) return;
    setState(() {
      // เซฟโค้ดไฟล์ที่เปิดอยู่ก่อนสลับ Mission
      _projectFiles[_activeFileName] = _codeController.text;

      _missionIndex = index;

      // อัปเดตเฉพาะ main.py เป็น starter ของ Mission ใหม่
      // ไฟล์อื่นที่สร้างไว้ (เช่น utils.py, ddd.py) ยังคงอยู่
      _projectFiles['main.py'] = _mission.starterCode;

      // สลับกลับไปที่ main.py เสมอเมื่อเปลี่ยน Mission
      _activeFileName = 'main.py';
      _codeController.text = _mission.starterCode;

      _testResults = List<bool?>.filled(_mission.tests.length, null);
      _hintVisible = false;
      _hintText = '';
      _output = "System ready. Mission switched to \"${_mission.title}\".\n";
    });
  }

  void _resetCode() {
    setState(() {
      // Reset เฉพาะ main.py แล้วสลับไปที่ไฟล์นั้น
      _projectFiles['main.py'] = _mission.starterCode;
      _activeFileName = 'main.py';
      _codeController.text = _mission.starterCode;
    });
    showAppToast(
        context, 'รีเซ็ตโค้ดกลับเป็นค่าเริ่มต้นแล้ว', type: ToastType.info);
  }

  // 🔄 สลับไฟล์ (เซฟโค้ดปัจจุบันก่อน)
  void _switchFile(String fileName) {
    if (_activeFileName == fileName) return;
    setState(() {
      _projectFiles[_activeFileName] = _codeController.text;
      _activeFileName = fileName;
      _codeController.text = _projectFiles[fileName] ?? '';
    });
  }

  // 🗑️ ลบไฟล์ (ลบ main.py ไม่ได้)
  void _deleteFile(String fileName) {
    if (fileName == 'main.py') {
      showAppToast(context, 'ไม่สามารถลบไฟล์ main.py ได้ครับ', type: ToastType.error);
      return;
    }
    setState(() {
      _projectFiles.remove(fileName);
      if (_activeFileName == fileName) {
        _activeFileName = 'main.py';
        _codeController.text = _projectFiles['main.py'] ?? '';
      }
    });
  }

  // ➕ Dialog สร้างไฟล์ใหม่
  void _showAddFileDialog() {
    final fileNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1E293B)),
          ),
          title: Text('สร้างไฟล์ใหม่',
              style: GoogleFonts.prompt(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: fileNameController,
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'เช่น utils.py',
              hintStyle: GoogleFonts.prompt(color: const Color(0xFF64748B)),
              enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF334155))),
              focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF3B82F6))),
            ),
            onSubmitted: (_) => _createFileFromDialog(ctx, fileNameController),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ยกเลิก', style: GoogleFonts.prompt(color: const Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _createFileFromDialog(ctx, fileNameController),
              child: Text('สร้าง', style: GoogleFonts.prompt(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _createFileFromDialog(BuildContext dialogContext, TextEditingController nameCtrl) {
    String newName = nameCtrl.text.trim();
    if (newName.isEmpty) return;
    if (!newName.endsWith('.py')) {
      newName += '.py';
    }
    if (_projectFiles.containsKey(newName)) {
      showAppToast(context, 'มีไฟล์ชื่อนี้อยู่แล้ว', type: ToastType.error);
      return;
    }
    setState(() {
      _projectFiles[_activeFileName] = _codeController.text;
      _projectFiles[newName] = '';
      _activeFileName = newName;
      _codeController.text = '';
    });
    Navigator.pop(dialogContext);
    showAppToast(context, 'สร้างไฟล์ $newName แล้ว', type: ToastType.success);
  }

  Future<void> _copyOutput() async {
    await Clipboard.setData(ClipboardData(text: _output));
    if (!mounted) return;
    showAppToast(context, 'คัดลอก Output แล้ว', type: ToastType.info);
  }

  void _announceNewBadges() {
    final newly = context.read<AppState>().checkBadgesAndReturnNew();
    for (final b in newly) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          showAppToast(context, '🏅 Achievement: "${b.name}" — ${b.desc}',
              type: ToastType.badge);
        }
      });
    }
  }



// --------------------------------------------------
  // RUN TESTS (real functional replacement of JS runTests)
  // --------------------------------------------------
  Future<void> _runTests() async {
    if (!_isReady || _isTesting) return;
    final mission = _mission;

    // Keep project map in sync with current editor content
    _projectFiles[_activeFileName] = _codeController.text;

    setState(() {
      _isTesting = true;
      _testResults = List<bool?>.filled(mission.tests.length, null);
    });

    _appendOutput("\n\n🧪 IT Automated Testing System — ${mission.title}\n");

    bool allPassed = true;
    final code = _codeController.text;

    for (int i = 0; i < mission.tests.length; i++) {
      dynamic test = mission.tests[i];
      File? tempFile;

      try {
        // 1. สร้างไฟล์ temp ชั่วคราวสำหรับตรวจข้อสอบ
        tempFile = File('temp_test_$i.py');
        await tempFile.writeAsString(code);

        final args = _pythonCommand == 'py'
            ? <String>['-3', '-u', tempFile.path]
            : <String>['-u', tempFile.path];

        final process = await Process.start(_pythonCommand, args);

        // 💡 ดึงค่า Input แบบดักครบทุกโครงสร้าง (Map / Class Property)
        String inputVal = '';
        if (test is Map) {
          inputVal = test['input'] ?? test['inputData'] ?? test['input_data'] ?? '';
        } else {
          try { inputVal = test.input ?? ''; } catch (_) {}
          if (inputVal.isEmpty) {
            try { inputVal = test.inputData ?? ''; } catch (_) {}
          }
        }

        // 💡 ดึงค่า Expected (เพิ่มการเช็ค expectedContains เข้าไปให้ชัวร์ 100%)
        String rawExpected = '';
        if (test is Map) {
          rawExpected = test['expectedContains'] ?? test['expected'] ?? test['output'] ?? test['expectedOutput'] ?? test['expected_output'] ?? '';
        } else {
          try { rawExpected = test.expectedContains ?? ''; } catch (_) {}
          if (rawExpected.isEmpty) {
            try { rawExpected = test.expected ?? ''; } catch (_) {}
          }
          if (rawExpected.isEmpty) {
            try { rawExpected = test.output ?? ''; } catch (_) {}
          }
          if (rawExpected.isEmpty) {
            try { rawExpected = test.expectedOutput ?? ''; } catch (_) {}
          }
        }

        final String expectedVal = rawExpected.toString().trim();

        // 2. ป้อน Input เข้าไปใน Python
        process.stdin.writeln(inputVal);
        await process.stdin.close();

        // 3. อ่านผลลัพธ์ Output
        final stdoutText = await process.stdout.transform(utf8.decoder).join();
        String actualOutput = stdoutText.trim();

        // 🚨 4. เปรียบเทียบผลลัพธ์แบบใหม่! (ยกเลิกการหั่น split(':') แล้ว)
        // ใช้ .endsWith() เช็คว่า Output ลงท้ายด้วยคำตอบที่คาดหวังหรือไม่
        bool isPassed = actualOutput == expectedVal || actualOutput.endsWith(expectedVal);

        // จัดรูป actualOutput ใหม่ให้โชว์ใน Log สวยๆ
        if (isPassed && actualOutput != expectedVal) {
          actualOutput = expectedVal; // ถ้าผ่านแล้ว ตัด Prompt ทิ้งเฉพาะตอนโชว์ Log
        } else if (!isPassed && actualOutput.contains('\n')) {
          actualOutput = actualOutput.split('\n').last.trim(); // ถ้าไม่ผ่าน ดึงแค่บรรทัดสุดท้ายมาโชว์
        }

        setState(() {
          _testResults[i] = isPassed;
        });

        if (isPassed) {
          _appendOutput("✅ Test ${i + 1} Passed\n");
        } else {
          allPassed = false;
          _appendOutput("❌ Test ${i + 1} Failed → expected \"$expectedVal\", got: \"$actualOutput\"\n");
        }
      } catch (e) {
        allPassed = false;
        setState(() {
          _testResults[i] = false;
        });
        _appendOutput("❌ Test ${i + 1} Error: $e\n");
      } finally {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    }

    setState(() => _isTesting = false);

    final state = context.read<AppState>();
    if (allPassed) {
      final wasThisMissionDoneBefore = state.completedMissionIds.contains(
          mission.id);
      state.completeMissionById(mission.id, mission.xpReward);
      _announceNewBadges();
      if (!mounted) return;
      if (!wasThisMissionDoneBefore) {
        showAppToast(context,
            '🎉 ผ่านทุกเทสต์! ได้รับ +${mission.xpReward * state.multiplier} XP',
            type: ToastType.success);
        showSalaryUnlockDialog(
            context, mission.title, mission.xpReward * state.multiplier);
      } else {
        showAppToast(
            context, '✅ ผ่านทุกเทสต์! (ทำ Mission นี้สำเร็จไปแล้วก่อนหน้านี้)',
            type: ToastType.success);
      }
    } else {
      if (!mounted) return;
      showAppToast(context, 'เทสต์ยังไม่ผ่านทั้งหมด ลองปรับแก้โค้ดดูนะครับ SUSU',
          type: ToastType.error);
    }
  }
  // --------------------------------------------------
  // AI HINT (real functional replacement of JS getAIHint)
  // --------------------------------------------------
  Future<void> _getAIHint() async {
    setState(() {
      _hintVisible = true;
      _hintLoading = true;
      _hintText = '';
    });

    final code = _codeController.text;
    final mission = _mission;
    final promptMessage =
        'ช่วยตรวจโค้ด Python นี้เพื่อทำ Mission "${mission
        .title}":\n```python\n$code\n```\nคำโจทย์: ${mission
        .description}\nช่วยให้ AI Hint คำแนะนำแบบสั้นๆ กระชับ (ไม่เกิน 2 ประโยค) เพื่อบอกแนวทางการแก้ไขโดยตรง';

    try {
      final response = await http.post(
        Uri.parse(kMentorApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true'
        },
        body: jsonEncode({'message': promptMessage}),
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() =>
        _hintText = data['reply'] ??
            'ลองตรวจสอบ f-string หรือการรับค่าตัวแปรผ่าน input() ดูก่อนนะครับ');
      } else {
        setState(() =>
        _hintText = 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ (${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() =>
      _hintText =
      '💡 ลองตรวจสอบว่า input() รับค่าใส่ตัวแปรถูกต้อง และรูปแบบ print/f-string ตรงกับโจทย์ "${_mission
          .description}" หรือไม่ครับ');
    } finally {
      if (mounted) setState(() => _hintLoading = false);
    }
  }

  void _submitProject() {
    showAppToast(context, '✅ ส่งผลงานเข้าสู่ IT Cloud Portfolio สำเร็จ!',
        type: ToastType.success);
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery
        .of(context)
        .size
        .width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF040709),
      appBar: _buildIDEAppBar(),
      body: Column(
        children: [
          Expanded(
            child: isWide
                ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLeftSidebar(),
                Container(width: 1, color: const Color(0xFF1E293B)),
                Expanded(child: _buildCodeEditor()),
                Container(width: 1, color: const Color(0xFF1E293B)),
                _buildRightConsole(),
              ],
            )
                : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 340, child: _buildCodeEditor()),
                  Container(height: 1, color: const Color(0xFF1E293B)),
                  SizedBox(height: 260, child: _buildRightConsole()),
                  Container(height: 1, color: const Color(0xFF1E293B)),
                  _buildLeftSidebar(),
                ],
              ),
            ),
          ),
          if (!_isDesktop)
            SizedBox(
              height: 1,
              width: 1,
              child: WebViewWidget(controller: _webViewController),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildIDEAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0A0F1A),
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: const Color(0xFF1E293B), height: 1.0),
      ),
      title: Row(
        children: [
          const Icon(
              Icons.terminal_rounded, color: Colors.blueAccent, size: 24),
          const SizedBox(width: 8),
          Flexible(
            child: Text('LearnPro IT Live Sandbox',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.prompt(fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (_isReady ? Colors.orange : Colors.grey).withValues(
                  alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _isReady ? Colors.orange.shade700 : Colors.grey),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_isReady ? Icons.bolt : Icons.hourglass_bottom,
                    color: _isReady ? Colors.orange : Colors.grey, size: 12),
                const SizedBox(width: 4),
                Text(_isReady ? 'Engine Ready' : 'Loading...',
                    style: GoogleFonts.prompt(
                        color: _isReady ? Colors.orange : Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _buildAppbarButton(
          _hintLoading ? Icons.sync : Icons.lightbulb_outline,
          'AI Hint',
          const Color(0xFF3B0764),
          Colors.white,
          onPressed: _hintLoading ? null : _getAIHint,
        ),
        const SizedBox(width: 8),
        _buildAppbarOutlineButton(
          _isTesting ? Icons.sync : Icons.science_outlined,
          _isTesting ? 'Testing...' : 'Run Tests',
          Colors.blueAccent,
          onPressed: (_isReady && !_isTesting) ? _runTests : null,
        ),
        const SizedBox(width: 8),
        _buildAppbarButton(
          _isRunning ? Icons.sync : Icons.play_arrow,
          _isRunning ? 'Running...' : 'Execute',
          _isRunning ? Colors.grey.shade800 : const Color(0xFF1E293B),
          _isRunning ? Colors.grey.shade400 : Colors.white,
          onPressed: (_isReady && !_isRunning) ? _execute : null,
        ),
        const SizedBox(width: 8),
        _buildAppbarButton(
            Icons.cloud_upload, 'Submit', Colors.blue.shade700, Colors.white,
            onPressed: _submitProject),
        const SizedBox(width: 8),
        _buildAppbarOutlineButton(
          Icons.replay,
          'Reset',
          const Color(0xFF94A3B8),
          onPressed: (_isRunning || _isTesting) ? null : _resetCode,
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildAppbarButton(IconData icon, String label, Color bgColor,
      Color textColor, {VoidCallback? onPressed}) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(icon, color: textColor, size: 14),
                const SizedBox(width: 6),
                Text(label, style: GoogleFonts.prompt(color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppbarOutlineButton(IconData icon, String label, Color color,
      {VoidCallback? onPressed}) {
    final active = onPressed != null;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: active ? color : Colors.grey.shade700),
            ),
            child: Row(
              children: [
                Icon(icon, color: active ? color : Colors.grey, size: 14),
                const SizedBox(width: 6),
                Text(label, style: GoogleFonts.prompt(
                    color: active ? color : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftSidebar() {
    final state = context.watch<AppState>();
    return Container(
      width: 280,
      color: const Color(0xFF0A0F1A),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('MISSIONS', style: GoogleFonts.prompt(
              color: const Color(0xFF475569),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(kSandboxMissions.length, (i) {
              final m = kSandboxMissions[i];
              final active = i == _missionIndex;
              final done = state.completedMissionIds.contains(m.id);
              return InkWell(
                onTap: () => _selectMission(i),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF1E3A8A) : const Color(
                        0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: active ? Colors.blueAccent : const Color(
                            0xFF1E293B)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (done)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                              Icons.check_circle, color: Color(0xFF34D399),
                              size: 11),
                        ),
                      Text('${i + 1}',
                          style: GoogleFonts.jetBrainsMono(
                              color: active ? Colors.white : const Color(
                                  0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF064E3B),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(
                    'MISSION ${(_missionIndex + 1).toString().padLeft(2, '0')}',
                    style: GoogleFonts.prompt(color: const Color(0xFF34D399),
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  const Icon(
                      Icons.monetization_on, color: Colors.amber, size: 12),
                  const SizedBox(width: 4),
                  Text('+${_mission.xpReward} XP', style: GoogleFonts.prompt(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(_mission.title, style: GoogleFonts.prompt(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_mission.description,
              style: GoogleFonts.prompt(
                  color: const Color(0xFF94A3B8), fontSize: 11, height: 1.5)),
          const SizedBox(height: 16),

          if (_hintVisible)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E1065).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6B21A8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFC084FC),
                          size: 14),
                      const SizedBox(width: 6),
                      Text('AI HINT', style: GoogleFonts.prompt(
                          color: const Color(0xFFC084FC),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_hintLoading)
                    Row(
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFC084FC)),
                        ),
                        const SizedBox(width: 8),
                        Text('กำลังวิเคราะห์โค้ด...', style: GoogleFonts.prompt(
                            color: const Color(0xFFE9D5FF), fontSize: 10)),
                      ],
                    )
                  else
                    Text(_hintText, style: GoogleFonts.prompt(
                        color: const Color(0xFFE9D5FF),
                        fontSize: 10,
                        height: 1.5)),
                ],
              ),
            ),

          Text('TEST CASES', style: GoogleFonts.prompt(
              color: const Color(0xFF475569),
              fontSize: 10,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_mission.tests.length, (i) {
                final result = i < _testResults.length ? _testResults[i] : null;
                final isLast = i == _mission.tests.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                  child: _buildTestCaseItem(result, _mission.tests[i].label),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PROJECT FILES', style: GoogleFonts.prompt(
                  color: const Color(0xFF475569),
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
              InkWell(
                onTap: _showAddFileDialog,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.add, color: Color(0xFF475569), size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._projectFiles.keys.map((fileName) {
            final isActive = fileName == _activeFileName;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isActive ? Colors.blueAccent.withValues(alpha: 0.5) : const Color(0xFF1E293B),
                ),
              ),
              child: InkWell(
                onTap: () => _switchFile(fileName),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.code, color: Colors.blueAccent, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: GoogleFonts.prompt(
                            color: isActive ? Colors.white : const Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (fileName != 'main.py')
                        InkWell(
                          onTap: () => _deleteFile(fileName),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.close, color: Color(0xFFF87171), size: 14),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTestCaseItem(bool? state, String text) {
    IconData icon;
    Color color;
    if (state == null) {
      icon = Icons.radio_button_unchecked;
      color = const Color(0xFF475569);
    } else if (state) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else {
      icon = Icons.cancel;
      color = Colors.redAccent;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.prompt(
            color: const Color(0xFF94A3B8), fontSize: 10))),
      ],
    );
  }

  Widget _buildCodeEditor() {
    return Container(
      color: const Color(0xFF161B22),
      child: Column(
        children: [
          Container(
            height: 40,
            color: const Color(0xFF0A0F1A),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF161B22),
                    border: Border(
                        top: BorderSide(color: Colors.blueAccent, width: 2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                          Icons.code, color: Colors.blueAccent, size: 14),
                      const SizedBox(width: 8),
                      Text(_activeFileName, style: GoogleFonts.prompt(
                          color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
                Expanded(child: Container()),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: const Color(0xFF0D1117),
                  child: Column(
                    children: List.generate(
                      20,
                          (index) =>
                          Text('${index + 1}',
                              style: GoogleFonts.jetBrainsMono(
                                  color: const Color(0xFF475569),
                                  fontSize: 13,
                                  height: 1.5)),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      controller: _codeController,
                      maxLines: null,
                      expands: true,
                      style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFFCBD5E1),
                          fontSize: 13,
                          height: 1.5),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
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

  Widget _buildRightConsole() {
    return Container(
      width: 320,
      color: const Color(0xFF0A0F1A),
      child: Column(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.chevron_right, color: Color(0xFF475569),
                        size: 16),
                    const SizedBox(width: 4),
                    Text('OUTPUT CONSOLE', style: GoogleFonts.prompt(
                        color: const Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                          Icons.copy_all_outlined, color: Color(0xFF64748B),
                          size: 14),
                      onPressed: _copyOutput,
                      tooltip: 'Copy Output',
                      splashRadius: 16,
                    ),
                    IconButton(
                      icon: const Icon(
                          Icons.delete_outline, color: Color(0xFF64748B),
                          size: 14),
                      onPressed: _clearConsole,
                      tooltip: 'Clear Console',
                      splashRadius: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                controller: _consoleScrollController,
                child: Text(
                  _output,
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                const Icon(
                    Icons.chevron_right, color: Color(0xFF475569), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _consoleInputController,
                    style: GoogleFonts.jetBrainsMono(
                        color: Colors.white, fontSize: 11),
                    decoration: const InputDecoration(
                      hintText: 'Type input here... (e.g. John)',
                      hintStyle: TextStyle(color: Color(0xFF475569)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) {
                      if (_isReady && !_isRunning) _execute();
                    },
                  ),
                ),
              ],
            ),
          ),
        ], // วงเล็บปิดของ Column
      ), // วงเล็บปิดของ Container
    ); // วงเล็บปิดของ return
  } // วงเล็บปิดของฟังก์ชัน _buildRightConsole
}
