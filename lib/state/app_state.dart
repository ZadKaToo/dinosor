import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/badge_def.dart';
import '../models/salary_tier.dart';
import '../models/run_history_entry.dart';

// นำเข้า Service ที่เราสร้างไว้ (ปรับ path ให้ตรงกับโปรเจกต์คุณ)
import '../services/user_service.dart';
import '../services/progress_service.dart';
import '../services/mission_service.dart';
import '../services/auth_service.dart'; // เพิ่ม AuthService สำหรับเช็ค Auth

class AppState extends ChangeNotifier {
  // ==========================================
  // PROGRESS & USER DATA
  // ==========================================
  int totalXP = 0;
  int streakDays = 0;
  int missionsDone = 0;
  int runCount = 0;
  String selectedTrack = 'swe';
  String userId = ''; // เก็บ User ID
  String fullName = 'Guest'; // ชื่อผู้ใช้

  final Set<String> earnedBadges = {};
  final List<BadgeDef> pendingBadgeToasts = [];
  final Set<String> completedMissionIds = {};

  // คำนวณ Multiplier ตาม Streak (ลอจิกเดียวกับ Backend)
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

  // ==========================================
  // INIT DATA (เรียกใช้ตอนเข้าแอปหลังจาก Login)
  // ==========================================
  Future<void> initializeUserData() async {
    // 1. โหลด Profile และ Settings
    final profileData = await UserService.getMyProfile();
    final settingsData = await UserService.getSettings();
    // 2. โหลด Progress
    final progressData = await ProgressService.getMyProgress();

    if (profileData != null) {
      userId = profileData['id'] ?? '';
      fullName = profileData['full_name'] ?? 'Guest';
      selectedTrack = profileData['target_role'] ?? 'swe';
    }

    if (settingsData != null) {
      isLightTheme = !(settingsData['dark_mode'] ?? false);
      settingsNotifications = settingsData['push_notifications'] ?? true;
      // ถ้าใน DB มีเซฟฟิลด์พวกนี้ด้วย ก็สามารถดึงมาแมปได้ (ตอนนี้ทำเป็น local state ไปก่อน)
    }

    if (progressData != null) {
      totalXP = progressData['total_xp'] ?? 0;
      streakDays = progressData['streak_days'] ?? 0;
      runCount = progressData['run_count'] ?? 0;

      // อัปเดต Badges จาก Backend
      earnedBadges.clear();
      final List<dynamic> badges = progressData['badges'] ?? [];
      for (var b in badges) {
        if (b['id'] != null) earnedBadges.add(b['id'].toString());
      }
    }

    // 3. โหลดประวัติภารกิจ (ดึงเฉพาะอันที่สำเร็จแล้ว)
    final missionsData = await MissionService.getMyMissions();
    completedMissionIds.clear();
    missionsDone = 0;
    for (var m in missionsData) {
      if (m['status'] == 'completed') {
        completedMissionIds.add(m['mission_id'].toString());
        missionsDone++;
      }
    }

    notifyListeners();
  }

  // ==========================================
  // ACTIONS (อัปเดต UI + ยิง API หลังบ้าน)
  // ==========================================

  // อัปเดต XP (ให้ Backend เป็นคนจัดการ บวก multiplier)
  Future<void> addXP(int amount) async {
    // เอาขึ้น UI ไปก่อนให้ดูเร็ว (Optimistic UI)
    final gained = amount * multiplier;
    totalXP += gained;
    _checkBadgesLocal();
    notifyListeners();

    // ส่งไปบวกของจริงที่ Backend (และรับค่าที่ถูกต้องกลับมาทับ)
    final result = await ProgressService.addXp(amount);
    if (result != null) {
      totalXP = result['total_xp'] ?? totalXP;
      streakDays = result['streak_days'] ?? streakDays;
      runCount = result['run_count'] ?? runCount;
      // ให้ชัวร์ว่าโหลด Badges ใหม่
      final progressData = await ProgressService.getMyProgress();
      if (progressData != null) {
        final List<dynamic> badges = progressData['badges'] ?? [];
        for (var b in badges) {
          if (b['id'] != null) earnedBadges.add(b['id'].toString());
        }
      }
      notifyListeners();
    }
  }

  // รันโค้ด
  Future<void> incrementRunCount() async {
    runCount++;
    _checkBadgesLocal();
    notifyListeners();

    final result = await ProgressService.incrementRunCount();
    if (result != null) {
      runCount = result['run_count'] ?? runCount;
      notifyListeners();
    }
  }

  // ส่งภารกิจ
  Future<void> completeMissionById(String missionId, int xp) async {
    if (!completedMissionIds.contains(missionId)) {
      completedMissionIds.add(missionId);
      missionsDone++;
      addXP(xp); // แอบบวก XP ล่วงหน้า
      notifyListeners();

      // ส่ง API ไปอัปเดตภารกิจ (ส่งพารามิเตอร์ครบ 3 ตัว: missionId, code, passed)
      await MissionService.startMission(missionId); // เปลี่ยน status เป็น in_progress
      await MissionService.submitMission(missionId, '# submitted code', true); // จำลองส่งโค้ดสำเร็จ
    }
  }

  void completeMission(int xp) {
    missionsDone++;
    addXP(xp);
  }

  Future<void> selectTrack(String track) async {
    selectedTrack = track;
    notifyListeners();

    // บันทึกลง Profile
    await UserService.updateProfile(targetRole: track);
  }

  // Check Badges Local แบบเดิม (ไว้เช็คชั่วคราวก่อน API ตอบกลับ)
  List<BadgeDef> _checkBadgesLocal() {
    final newlyEarned = <BadgeDef>[];
    void mark(String id) {
      if (!earnedBadges.contains(id)) {
        earnedBadges.add(id);
        // หาใน kBadges (ถ้าคุณมี mock data เก็บไว้)
        try {
          final def = kBadges.firstWhere((b) => b.id == id);
          newlyEarned.add(def);
        } catch (e) {
          // ไม่พบ badge ใน local definition
        }
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
    final n = _checkBadgesLocal();
    if (n.isNotEmpty) notifyListeners();
    return n;
  }

  Future<void> resetProgress() async {
    // ในที่นี้อาจจะต้องสร้าง Endpoint ResetProgress ใน Backend ถ้าต้องการให้ลบจริงๆ
    // สำหรับตอนนี้เคลียร์แค่ใน State ก่อน
    totalXP = 0;
    missionsDone = 0;
    runCount = 0;
    earnedBadges.clear();
    completedMissionIds.clear();
    selectedTrack = 'swe';
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.logout();
    resetProgress();
  }

  // ==========================================
  // GLOBAL APP SETTINGS
  // ==========================================
  bool settingsAutoSave = true;
  bool settingsShowLineNumbers = true;
  String settingsFontSize = 'ปกติ'; // เล็ก, ปกติ, ใหญ่
  bool settingsNotifications = true;
  bool settingsSoundEffects = true;

  double get editorFontSize {
    switch (settingsFontSize) {
      case 'เล็ก': return 11;
      case 'ใหญ่': return 15;
      default: return 13;
    }
  }

  void updateAutoSave(bool v) {
    settingsAutoSave = v;
    notifyListeners();
  }

  void updateShowLineNumbers(bool v) {
    settingsShowLineNumbers = v;
    notifyListeners();
  }

  void updateFontSize(String v) {
    settingsFontSize = v;
    notifyListeners();
  }

  Future<void> updateNotifications(bool v) async {
    settingsNotifications = v;
    notifyListeners();
    await UserService.updateSettings(pushNotifications: v);
  }

  void updateSoundEffects(bool v) {
    settingsSoundEffects = v;
    notifyListeners();
  }

  // ==========================================
  // THEME
  // ==========================================
  bool isLightTheme = true;

  Future<void> toggleTheme(bool light) async {
    isLightTheme = light;
    notifyListeners();
    await UserService.updateSettings(darkMode: !light); // บันทึกลง Backend
  }

  // Semantic colors
  Color get bgColor => isLightTheme ? const Color(0xFFF3F8FF) : const Color(0xFF080C14);
  Color get sidebarColor => isLightTheme ? Colors.white : const Color(0xFF0A0F1A);
  Color get cardColor => isLightTheme ? const Color(0xFFEAF3FF) : const Color(0xFF0F172A);
  Color get cardAltColor => isLightTheme ? const Color(0xFFDCEBFF) : const Color(0xFF1E293B);
  Color get borderColor => isLightTheme ? const Color(0xFFBFDBFE) : const Color(0xFF1E293B);
  Color get borderColorSoft => isLightTheme ? const Color(0xFFDCEBFF) : const Color(0xFF334155);
  Color get textPrimary => isLightTheme ? const Color(0xFF0B1220) : Colors.white;
  Color get textSecondary => isLightTheme ? const Color(0xFF3B5177) : const Color(0xFF94A3B8);
  Color get textMuted => isLightTheme ? const Color(0xFF6B87B3) : const Color(0xFF64748B);
  Color get accentColor => isLightTheme ? const Color(0xFF2563EB) : const Color(0xFF10B981);

  ThemeData get themeData => isLightTheme
      ? ThemeData.light().copyWith(
    scaffoldBackgroundColor: const Color(0xFFF3F8FF),
    primaryColor: const Color(0xFF2563EB),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.light,
    ),
    dialogBackgroundColor: Colors.white,
  )
      : ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF080C14),
    primaryColor: const Color(0xFF10B981),
  );

  // หลักสูตร
  final List<String> plannedCurriculum = [
    'Python Basics',
    'File I/O & Error Handling',
    'OOP & Classes',
    'API & HTTP Requests',
  ];
  final Set<String> completedCurriculum = {};

  void toggleCurriculumTopic(String topic) {
    if (completedCurriculum.contains(topic)) {
      completedCurriculum.remove(topic);
    } else {
      completedCurriculum.add(topic);
    }
    notifyListeners();
  }

  // ประวัติการรันโค้ด
  final List<RunHistoryEntry> runHistory = [];

  void addRunHistory(RunHistoryEntry entry) {
    runHistory.insert(0, entry);
    if (runHistory.length > 10) runHistory.removeLast();
    notifyListeners();
  }
}