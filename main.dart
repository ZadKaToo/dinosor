import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// Global Key for Confetti
final GlobalKey<_MainLayoutScreenState> mainScreenKey = GlobalKey();

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
  int currentIndex = 0; // Manage tabs globally

  // IDE State
  Map<String, String> files = {
    'main.py': "name = input('Enter your name: ')\nprint(f'Hello, {name}!')"
  };
  String activeFile = 'main.py';
  bool showAIHint = false;
  bool test1Passed = false;
  bool test2Passed = false;
  bool mission1Submitted = false;

  final Set<String> earnedBadges = {};

  int get currentSalary {
    if (totalXP >= 700) return 180000;
    if (totalXP >= 500) return 130000;
    if (totalXP >= 400) return 90000;
    if (totalXP >= 300) return 65000;
    if (totalXP >= 180) return 45000;
    if (totalXP >= 100) return 35000;
    if (totalXP >= 40) return 25000;
    return 20000;
  }

  String get currentRole {
    if (totalXP >= 700) return "Tech Lead / CTO";
    if (totalXP >= 500) return "Senior Solution Architect";
    if (totalXP >= 400) return "Senior IT Specialist";
    if (totalXP >= 300) return "Mid-Level Engineer / Analyst";
    if (totalXP >= 180) return "Mid-Level IT Specialist";
    if (totalXP >= 100) return "Junior IT Specialist (Advanced)";
    if (totalXP >= 40) return "Junior IT / Developer";
    return "Junior IT Specialist (Entry)";
  }

  void switchTab(int index) {
    currentIndex = index;
    notifyListeners();
  }

  void selectTrack(String track) {
    selectedTrack = track;
    notifyListeners();
  }

  void toggleHint() {
    showAIHint = !showAIHint;
    notifyListeners();
  }

  void addFile(String filename) {
    if (!files.containsKey(filename)) {
      files[filename] = "";
      activeFile = filename;
      notifyListeners();
    }
  }

  void switchFile(String filename) {
    activeFile = filename;
    notifyListeners();
  }

  void updateActiveFile(String content) {
    files[activeFile] = content;
  }

  void updateTests(bool t1, bool t2) {
    test1Passed = t1;
    test2Passed = t2;
    notifyListeners();
  }

  void addXP(int amount) {
    int multiplier = streakDays >= 7 ? 3 : (streakDays >= 3 ? 2 : 1);
    totalXP += amount * multiplier;
    checkBadges();
    notifyListeners();
  }

  void incrementRunCount() {
    runCount++;
    if (runCount >= 1) earnedBadges.add('first_run');
    if (runCount >= 10) earnedBadges.add('coder');
    notifyListeners();
  }

  void completeMission(int xp) {
    if (!mission1Submitted) {
      mission1Submitted = true;
      missionsDone++;
      if (missionsDone >= 1) earnedBadges.add('mission1');
      addXP(xp);
      mainScreenKey.currentState?.playConfetti();
    }
  }

  void checkBadges() {
    if (totalXP >= 40) earnedBadges.add('first_pass');
    if (totalXP >= 50) earnedBadges.add('xp50');
    if (totalXP >= 100) earnedBadges.add('xp100');
    if (totalXP >= 200) earnedBadges.add('xp200');
  }

  void resetProgress() {
    totalXP = 20;
    missionsDone = 0;
    runCount = 0;
    mission1Submitted = false;
    test1Passed = false;
    test2Passed = false;
    earnedBadges.clear();
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
      home: MainLayoutScreen(key: mainScreenKey),
    );
  }
}

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  late ConfettiController _confettiController;

  final List<Widget> _tabs = [
    const ITCenterDashboardScreen(),
    const AIMentorChatScreen(),
    const ITTracksScreen(),
    const CareerRoadmapScreen(),
    const LiveSandboxScreen(),
  ];

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

  void playConfetti() {
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    bool isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              if (isWide) _buildDesktopSidebar(context, state),
              Expanded(child: _tabs[state.currentIndex]),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
        currentIndex: state.currentIndex,
        onTap: (index) => state.switchTab(index),
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
      width: 250,
      color: const Color(0xFF0A0F1A),
      padding: const EdgeInsets.all(16),
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
                  color: Colors.orange.shade900.withOpacity(0.4),
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
                Text('💰 เงินเดือนเป้าหมาย IT', style: GoogleFonts.prompt(color: const Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '฿${state.currentSalary.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}/เดือน',
                  style: GoogleFonts.prompt(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(state.currentRole, style: GoogleFonts.prompt(color: const Color(0xFFA7F3D0), fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildNavButton(state, 0, Icons.home_rounded, 'หน้าหลัก IT Center'),
          _buildNavButton(state, 1, Icons.smart_toy_rounded, 'AI Mentor Chat'),
          _buildNavButton(state, 2, Icons.alt_route_rounded, 'IT Tracks & Fields'),
          _buildNavButton(state, 3, Icons.show_chart_rounded, 'Career Roadmap'),
          _buildNavButton(state, 4, Icons.terminal_rounded, 'Live Sandbox'),
          const Spacer(),
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
                    Text('Level ${(state.totalXP ~/ 100) + 1}', style: GoogleFonts.prompt(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('${state.totalXP} XP', style: GoogleFonts.prompt(color: Colors.lightBlueAccent, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (state.totalXP % 100) / 100.0,
                  backgroundColor: Colors.black26,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNavButton(AppState state, int index, IconData icon, String label) {
    bool isActive = state.currentIndex == index;
    return InkWell(
      onTap: () => state.switchTab(index),
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
// TAB 1: IT CENTER DASHBOARD
// ==========================================
class ITCenterDashboardScreen extends StatelessWidget {
  const ITCenterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF0C1A2E)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade900.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🚀 เส้นทางเติบโตในสายงาน IT', style: GoogleFonts.prompt(color: Colors.blue.shade300, fontSize: 12, fontWeight: FontWeight.bold)),
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
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Daily Challenge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF78350F), Color(0xFF92400E)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('⚡ DAILY CHALLENGE', style: GoogleFonts.prompt(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('🎯 "IT Problem Solving & Automation"', style: GoogleFonts.prompt(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        Text('เขียนโปรแกรมหรือ Script ตรวจสอบระบบอัตโนมัติ', style: GoogleFonts.prompt(color: Colors.amber.shade100, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      state.switchTab(4); // Jump to IDE
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                    child: Text('รับ +75 XP', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Salary Tiers Overview
            Text('📊 ประมาณการเงินเดือนสายงาน IT ในไทย', style: GoogleFonts.prompt(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildTierCard('Junior IT / Dev', '฿20–35K', '0–2 ปีประสบการณ์', const Color(0xFF10B981), true),
                _buildTierCard('Mid Specialist', '฿40–80K', '2–5 ปีประสบการณ์', Colors.blue, state.totalXP >= 100),
                _buildTierCard('Senior Expert', '฿85–150K', '5+ ปีประสบการณ์', Colors.purple, state.totalXP >= 300),
                _buildTierCard('Tech Lead / CTO', '฿180K+', 'ระดับบริหารเทคโนโลยี', Colors.amber, state.totalXP >= 500),
              ],
            ),

            const SizedBox(height: 24),
            Text('📋 ภารกิจพื้นฐาน (General IT Missions)', style: GoogleFonts.prompt(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildMissionCard(
              context,
              state,
              '01',
              'Greeting Automation Script',
              'เขียน Script ตอบรับและแสดงผลการทักทายผู้ใช้งานระบบอัตโนมัติ',
              '+40 XP',
              true,
              state.mission1Submitted,
            ),
            _buildMissionCard(
              context,
              state,
              '02',
              'System Metric Calculator',
              'สร้างระบบคำนวณและประมวลผลทรัพยากรของเครื่องเซิร์ฟเวอร์',
              '+60 XP',
              false,
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(String title, String salary, String subtitle, Color color, bool unlocked) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: unlocked ? color.withOpacity(0.5) : const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 11)),
              if (!unlocked) const Icon(Icons.lock, size: 12, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 4),
          Text(salary, style: GoogleFonts.prompt(color: unlocked ? color : Colors.grey, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.prompt(color: const Color(0xFF475569), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMissionCard(BuildContext context, AppState state, String num, String title, String desc, String xp, bool isUnlocked, bool isDone) {
    return InkWell(
      onTap: isUnlocked ? () => state.switchTab(4) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDone ? Colors.green : (isUnlocked ? Colors.blue.withOpacity(0.5) : const Color(0xFF1E293B))),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(num, style: GoogleFonts.prompt(color: isUnlocked ? Colors.blue : Colors.grey, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: GoogleFonts.prompt(color: isUnlocked ? Colors.white : Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      if (isDone)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: Text('DONE', style: GoogleFonts.prompt(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                  Text(desc, style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(xp, style: GoogleFonts.prompt(color: isUnlocked ? Colors.amber : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                if (!isUnlocked) const Icon(Icons.lock, size: 14, color: Colors.grey),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 2: AI MENTOR CHATBOT
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

  final List<String> quickPrompts = [
    "เตรียมพอร์ตยังไงให้ได้งานแรก",
    "ไม่ได้จบตรงสายเริ่มยังไง",
    "จำลองสัมภาษณ์งานตำแหน่ง Junior",
    "ทักษะที่ตลาดต้องการมากที่สุด",
    "ฐานเงินเดือนเริ่มต้นแต่ละสาย"
  ];

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
        Uri.parse('https://open-garlics-poke.loca.lt/api/mentor'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
        },
        body: jsonEncode({'message': text}),
      ).timeout(const Duration(seconds: 15));

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
        _messages.add(ChatMessage(text: 'ระบบขัดข้องชั่วคราว แต่จากประสบการณ์ของผม แนะนำให้เริ่มจากการสร้าง Portfolio โชว์ผลงานจริงครับ', isUser: false));
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            ),

          // Quick Prompts Horizontal Scroll
          Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: quickPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () => _sendMessage(prompt),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF064E3B).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF047857)),
                        ),
                        child: Text(
                          prompt,
                          style: GoogleFonts.prompt(color: const Color(0xFF34D399), fontSize: 11),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Input Box
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
                  onPressed: () => _sendMessage(_controller.text),
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
    final state = Provider.of<AppState>(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('เลือกสายงาน IT (Specialization Tracks)', style: GoogleFonts.prompt(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTrackCard(state, 'swe', 'Software & Web Development', 'Frontend / Backend / Full-Stack', 'พัฒนาแอปพลิเคชัน เว็บไซต์ และซอฟต์แวร์ระบบ', Icons.code, Colors.blue),
            _buildTrackCard(state, 'data', 'Data & AI Engineering', 'Data Science / ML / Data Analyst', 'วิเคราะห์ข้อมูล และสร้างแบบจำลอง AI Machine Learning', Icons.psychology, Colors.purple),
            _buildTrackCard(state, 'devops', 'Cloud & DevOps', 'Cloud Engineer / SysAdmin / CI/CD', 'ดูแลโครงสร้างพื้นฐานคลาวด์ และระบบอัตโนมัติ', Icons.cloud, const Color(0xFF10B981)),
            _buildTrackCard(state, 'sec', 'Cybersecurity', 'SOC Analyst / Security / Pentester', 'คุ้มครองและป้องกันระบบสารสนเทศ ตรวจจับช่องโหว่', Icons.security, const Color(0xFFF43F5E)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackCard(AppState state, String id, String title, String subtitle, String desc, IconData icon, Color color) {
    bool isActive = state.selectedTrack == id;
    return InkWell(
      onTap: () => state.selectTrack(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? color : const Color(0xFF1E293B)),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.2), radius: 24, child: Icon(icon, color: color)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.prompt(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: GoogleFonts.jetBrainsMono(color: color, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(desc, style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 12)),
                ],
              ),
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
    final state = Provider.of<AppState>(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Career Roadmap (IT Industry)', style: GoogleFonts.prompt(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Roadmap Steps
            _buildRoadmapCard(
              title: 'Junior IT / Dev Specialist',
              reqXP: 0,
              currentXP: state.totalXP,
              color: Colors.green,
              salary: '฿20K - 35K',
            ),
            _buildRoadmapArrow(),
            _buildRoadmapCard(
              title: 'Mid-Level IT Specialist',
              reqXP: 100,
              currentXP: state.totalXP,
              color: Colors.blue,
              salary: '฿40K - 80K',
            ),
            _buildRoadmapArrow(),
            _buildRoadmapCard(
              title: 'Senior IT Expert / Specialist',
              reqXP: 300,
              currentXP: state.totalXP,
              color: Colors.purple,
              salary: '฿85K - 150K',
            ),
            _buildRoadmapArrow(),
            _buildRoadmapCard(
              title: 'Tech Lead / Solution Architect',
              reqXP: 500,
              currentXP: state.totalXP,
              color: Colors.amber,
              salary: '฿180K+',
            ),

            const SizedBox(height: 30),

            // Radar Chart
            Text('IT Multi-Domain Skill Analysis', style: GoogleFonts.prompt(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              height: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  ticksTextStyle: const TextStyle(color: Colors.transparent),
                  titlePositionPercentageOffset: 0.2,
                  getTitle: (index, angle) {
                    switch (index) {
                      case 0: return const RadarChartTitle(text: 'Coding');
                      case 1: return const RadarChartTitle(text: 'System');
                      case 2: return const RadarChartTitle(text: 'DevOps');
                      case 3: return const RadarChartTitle(text: 'Database');
                      case 4: return const RadarChartTitle(text: 'Security');
                      default: return const RadarChartTitle(text: '');
                    }
                  },
                  dataSets: [
                    RadarDataSet(
                      fillColor: const Color(0xFF10B981).withOpacity(0.3),
                      borderColor: const Color(0xFF10B981),
                      entryRadius: 3,
                      dataEntries: [
                        RadarEntry(value: 30 + (state.totalXP * 0.1).clamp(0, 70).toDouble()),
                        RadarEntry(value: 20 + (state.totalXP * 0.08).clamp(0, 80).toDouble()),
                        RadarEntry(value: 10 + (state.totalXP * 0.05).clamp(0, 90).toDouble()),
                        RadarEntry(value: 40 + (state.totalXP * 0.06).clamp(0, 60).toDouble()),
                        RadarEntry(value: 20 + (state.totalXP * 0.04).clamp(0, 80).toDouble()),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmapArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Center(child: Icon(Icons.arrow_downward, color: Colors.grey, size: 20)),
    );
  }

  Widget _buildRoadmapCard({required String title, required int reqXP, required int currentXP, required Color color, required String salary}) {
    bool unlocked = currentXP >= reqXP;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: unlocked ? color.withOpacity(0.5) : const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: unlocked ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(unlocked ? Icons.check : Icons.lock, color: unlocked ? color : Colors.grey, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.prompt(color: unlocked ? Colors.white : Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(unlocked ? 'Salary: $salary' : 'ล็อก (ต้องการ $reqXP XP)', style: GoogleFonts.prompt(color: unlocked ? color : Colors.grey, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// TAB 5: LIVE SANDBOX (HYBRID: WINDOWS + MOBILE)
// ==========================================
class LiveSandboxScreen extends StatefulWidget {
  const LiveSandboxScreen({super.key});

  @override
  State<LiveSandboxScreen> createState() => _LiveSandboxScreenState();
}

class _LiveSandboxScreenState extends State<LiveSandboxScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _consoleInputController = TextEditingController();

  String _output = "System ready. Select a script to run.\n";
  bool _isReady = false;
  bool _isRunning = false;

  // สำหรับ Windows
  bool _isDesktop = false;
  String _pythonCommand = '';

  // สำหรับ Mobile
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _initEnvironment();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = Provider.of<AppState>(context, listen: false);
    _codeController.text = state.files[state.activeFile] ?? '';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _consoleInputController.dispose();
    super.dispose();
  }

  Future<void> _initEnvironment() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      _isDesktop = true;
      _checkLocalPython();
    } else {
      _isDesktop = false;
      _initMobilePyodide();
    }
  }

  Future<void> _checkLocalPython() async {
    final candidates = <String>['python', 'py'];
    for (final command in candidates) {
      try {
        final args = command == 'py' ? <String>['-3', '--version'] : <String>['--version'];
        final result = await Process.run(command, args, runInShell: true).timeout(const Duration(seconds: 5));

        if (result.exitCode == 0) {
          if (!mounted) return;
          setState(() {
            _pythonCommand = command;
            _isReady = true;
            _output += "\n✅ [Desktop Mode] Python พร้อมใช้งานแล้ว";
          });
          return;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _isReady = false;
      _output = "❌ ไม่พบ Python ในเครื่อง\nติดตั้ง Python 3 จาก python.org แล้วเปิดแอปใหม่";
    });
  }

  Future<void> _runDesktopCode() async {
    final code = _codeController.text;
    setState(() {
      _isRunning = true;
      _output += "\n\n▶ Executing script...\n";
    });

    try {
      final args = _pythonCommand == 'py' ? <String>['-3', '-c', code] : <String>['-c', code];
      final process = await Process.start(_pythonCommand, args, runInShell: true);

      // ใส่ input ปลอม
      for (int i = 0; i < 5; i++) {
        process.stdin.writeln('John');
      }
      await process.stdin.close();

      final stdoutText = await process.stdout.transform(utf8.decoder).join();
      final stderrText = await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      if (!mounted) return;

      final buffer = StringBuffer();
      if (stdoutText.isNotEmpty) buffer.writeln(stdoutText);
      if (stderrText.isNotEmpty) buffer.writeln("[stderr]\n$stderrText");
      if (exitCode != 0) buffer.writeln("\n[Exit Code] $exitCode");

      setState(() {
        _output += buffer.toString().trim();
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _output += "[Error] ไม่สามารถรัน Python ได้\n$e";
        _isRunning = false;
      });
    }
  }

  void _initMobilePyodide() {
    const String pyodideHtml = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="https://cdn.jsdelivr.net/pyodide/v0.24.1/full/pyodide.js"></script>
      </head>
      <body style="background-color: #040709; color: white;">
        <script>
          let pyodide;
          async function main() {
            try {
              pyodide = await loadPyodide();
              SandboxChannel.postMessage("READY");
            } catch(e) {
              SandboxChannel.postMessage("ERROR: " + e.message);
            }
          }
          main();

          async function runPython(code) {
            try {
              let output = "";
              pyodide.setStdout({ batched: (msg) => { output += msg + "\\n"; } });
              pyodide.setStderr({ batched: (msg) => { output += "[stderr] " + msg + "\\n"; } });
              
              const prepCode = `
import builtins
def mock_input(prompt=""):
    return "John"
builtins.input = mock_input
              ` + "\\n" + code;
              
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
            setState(() {
              _output += message.message.replaceFirst("RESULT: ", "").trim();
              _isRunning = false;
            });
          } else if (message.message.startsWith("ERROR: ")) {
            setState(() {
              _output += "[Python Error]\n" + message.message.replaceFirst("ERROR: ", "");
              _isRunning = false;
            });
          }
        },
      )
      ..loadHtmlString(pyodideHtml);
  }

  void _runMobileCode() {
    final code = _codeController.text;
    setState(() {
      _isRunning = true;
      _output += "\n\n▶ Executing on Pyodide...\n";
    });

    final encodedCode = jsonEncode(code);
    _webViewController.runJavaScript('runPython($encodedCode);');
  }

  void _execute() {
    if (!_isReady || _isRunning) return;
    if (_codeController.text.trim().isEmpty) {
      setState(() => _output += "\n[Error] กรุณาใส่ Python code ก่อน");
      return;
    }

    Provider.of<AppState>(context, listen: false).incrementRunCount();

    if (_isDesktop) {
      _runDesktopCode();
    } else {
      _runMobileCode();
    }
  }

  void _runTests(AppState state) {
    String code = _codeController.text;
    bool hasInput = code.contains('input');
    bool hasPrint = code.contains('print');
    bool hasHello = code.contains('Hello');

    setState(() {
      _output += "\n\n▶ Running Tests...";
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      bool pass = hasInput && hasPrint && hasHello;
      state.updateTests(pass, pass);
      setState(() {
        if (pass) {
          _output += "\n✅ All tests passed! Ready to submit.";
        } else {
          _output += "\n❌ Tests failed. Please check your output format and input usage.";
        }
      });
    });
  }

  void _submitProject(AppState state) {
    if (state.test1Passed && state.test2Passed) {
      state.completeMission(40);
      setState(() {
        _output += "\n🎉 Project Submitted Successfully! +40 XP";
      });
    } else {
      setState(() {
        _output += "\n⚠️ Cannot submit. Please run and pass tests first.";
      });
    }
  }

  void _clearConsole() {
    setState(() {
      _output = "System ready. Select a script to run.\n";
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final bool isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF040709),
      appBar: _buildIDEAppBar(state),
      body: Column(
        children: [
          Expanded(
            child: isWide
                ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLeftSidebar(state),
                Container(width: 1, color: const Color(0xFF1E293B)),
                Expanded(child: _buildCodeEditor(state)),
                Container(width: 1, color: const Color(0xFF1E293B)),
                _buildRightConsole(),
              ],
            )
                : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 400, child: _buildCodeEditor(state)),
                  Container(height: 1, color: const Color(0xFF1E293B)),
                  SizedBox(height: 300, child: _buildRightConsole()),
                  Container(height: 1, color: const Color(0xFF1E293B)),
                  _buildLeftSidebar(state),
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

  PreferredSizeWidget _buildIDEAppBar(AppState state) {
    return AppBar(
      backgroundColor: const Color(0xFF0A0F1A),
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.terminal_rounded, color: Colors.blueAccent, size: 24),
          const SizedBox(width: 8),
          Text('LearnPro IT Live Sandbox', style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
      actions: [
        _buildAppbarButton(Icons.lightbulb_outline, 'AI Hint', const Color(0xFF6B21A8), Colors.white, onPressed: state.toggleHint),
        const SizedBox(width: 8),
        _buildAppbarOutlineButton(Icons.science_outlined, 'Run Tests', Colors.indigoAccent, onPressed: () => _runTests(state)),
        const SizedBox(width: 8),
    _buildAppbarButton(Icons.play_arrow, 'Execute', Colors.blueGrey.shade800, Colors.greenAccent, onPressed: _isReady ? _execute : null),
        const SizedBox(width: 8),
        _buildAppbarButton(Icons.cloud_upload, 'Submit', Colors.blue.shade700, Colors.white, onPressed: () => _submitProject(state)),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildAppbarButton(IconData icon, String label, Color bgColor, Color textColor, {VoidCallback? onPressed}) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed ?? () {},
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
            child: Row(
              children: [
                Icon(icon, color: textColor, size: 14),
                const SizedBox(width: 6),
                Text(label, style: GoogleFonts.prompt(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppbarOutlineButton(IconData icon, String label, Color color, {VoidCallback? onPressed}) {
    return Center(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.prompt(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftSidebar(AppState state) {
    return Container(
      width: 280,
      color: const Color(0xFF0A0F1A),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF064E3B), borderRadius: BorderRadius.circular(4)),
                child: Text('MISSION 01', style: GoogleFonts.prompt(color: const Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 12),
                  const SizedBox(width: 4),
                  Text('+40 XP', style: GoogleFonts.prompt(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Text('Greeting Automation Script', style: GoogleFonts.prompt(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.prompt(color: const Color(0xFF94A3B8), fontSize: 11, height: 1.5),
              children: const [
                TextSpan(text: 'รับชื่อผู้ใช้งาน '),
                TextSpan(text: 'input()', style: TextStyle(color: Colors.blueAccent, backgroundColor: Color(0xFF1E293B))),
                TextSpan(text: ' แล้ว print คำทักทายว่า\n'),
                TextSpan(text: '"Hello, [ชื่อ]!"', style: TextStyle(color: Color(0xFF34D399))),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // AI HINT BOX
          if (state.showAIHint)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E1065).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6B21A8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFC084FC), size: 14),
                      const SizedBox(width: 6),
                      Text('AI HINT', style: GoogleFonts.prompt(color: const Color(0xFFC084FC), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'โจทย์ต้องการรับชื่อด้วยฟังก์ชัน input() แล้วพิมพ์คำว่า "Hello, [ชื่อ]!" ให้เพิ่มการรับค่าชื่อ เช่น name = input(\'Enter your name: \') และสั่งพิมพ์ print(f"Hello, {name}!")',
                    style: GoogleFonts.prompt(color: const Color(0xFFE9D5FF), fontSize: 10, height: 1.5),
                  ),
                ],
              ),
            ),
          if (state.showAIHint) const SizedBox(height: 20),

          // TEST CASES
          Text('TEST CASES', style: GoogleFonts.prompt(color: const Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold)),
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
              children: [
                _buildTestCaseItem(state.test1Passed, 'input "John" → "Hello, John!"'),
                const SizedBox(height: 8),
                _buildTestCaseItem(state.test2Passed, 'input "สมชาย" → "Hello, สมชาย!"'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // PROJECT FILES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PROJECT FILES', style: GoogleFonts.prompt(color: const Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () => state.addFile('new_script.py'),
                child: const Icon(Icons.add, color: Color(0xFF475569), size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...state.files.keys.map((filename) => InkWell(
            onTap: () {
              state.switchFile(filename);
              _codeController.text = state.files[filename] ?? '';
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: state.activeFile == filename ? const Color(0xFF1E293B) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.code, color: state.activeFile == filename ? Colors.blueAccent : Colors.grey, size: 14),
                  const SizedBox(width: 8),
                  Text(filename, style: GoogleFonts.prompt(color: state.activeFile == filename ? Colors.white : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildTestCaseItem(bool isPass, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(isPass ? Icons.check_circle : Icons.circle_outlined, color: isPass ? Colors.green : Colors.grey, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.prompt(color: const Color(0xFF94A3B8), fontSize: 10))),
      ],
    );
  }

  Widget _buildCodeEditor(AppState state) {
    return Container(
      color: const Color(0xFF161B22),
      child: Column(
        children: [
          // Editor Tab
          Container(
            height: 40,
            color: const Color(0xFF0A0F1A),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF161B22),
                    border: Border(top: BorderSide(color: Colors.blueAccent, width: 2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.code, color: Colors.blueAccent, size: 14),
                      const SizedBox(width: 8),
                      Text(state.activeFile, style: GoogleFonts.prompt(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
                Expanded(child: Container()),
              ],
            ),
          ),
          // Editor Area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: const Color(0xFF0D1117),
                  child: Column(
                    children: List.generate(20, (index) => Text('${index + 1}', style: GoogleFonts.jetBrainsMono(color: const Color(0xFF475569), fontSize: 13, height: 1.5))).toList(),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      controller: _codeController,
                      onChanged: (val) => state.updateActiveFile(val),
                      maxLines: null,
                      expands: true,
                      style: GoogleFonts.jetBrainsMono(color: const Color(0xFFCBD5E1), fontSize: 13, height: 1.5),
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
                    const Icon(Icons.chevron_right, color: Color(0xFF475569), size: 16),
                    const SizedBox(width: 4),
                    Text('OUTPUT CONSOLE', style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFF64748B), size: 14),
                  onPressed: _clearConsole,
                  tooltip: 'Clear Console',
                  splashRadius: 16,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
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
        ],
      ),
    );
  }
}