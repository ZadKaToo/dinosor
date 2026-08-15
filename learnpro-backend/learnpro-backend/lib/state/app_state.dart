import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/badge_def.dart';
import '../models/salary_tier.dart';
import '../models/run_history_entry.dart';

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

  // ==========================================
  // GLOBAL APP SETTINGS (แถบตั้งค่า / Settings Tab)
  // shared across the whole app — Sandbox tab and Settings tab
  // both read/write these same values.
  // ==========================================
  bool settingsAutoSave = true;
  bool settingsShowLineNumbers = true;
  String settingsFontSize = 'ปกติ'; // เล็ก, ปกติ, ใหญ่
  bool settingsNotifications = true;
  bool settingsSoundEffects = true;

  double get editorFontSize {
    switch (settingsFontSize) {
      case 'เล็ก':
        return 11;
      case 'ใหญ่':
        return 15;
      default:
        return 13;
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

  void updateNotifications(bool v) {
    settingsNotifications = v;
    notifyListeners();
  }

  void updateSoundEffects(bool v) {
    settingsSoundEffects = v;
    notifyListeners();
  }

  // หลักสูตรที่ได้เลือกไว้ / วางแผนไว้ (Planned Curriculum) — global
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

  // ประวัติการฝึกล่าสุด (Recent Training/Run History) — global
  final List<RunHistoryEntry> runHistory = [];

  void addRunHistory(RunHistoryEntry entry) {
    runHistory.insert(0, entry);
    if (runHistory.length > 10) runHistory.removeLast();
    notifyListeners();
  }

  // ==========================================
  // THEME (ธีมที่ใช้ปัจจุบัน / ธีมสีขาวฟ้า) — global, whole-app
  // ==========================================
  bool isLightTheme = false;

  void toggleTheme(bool light) {
    isLightTheme = light;
    notifyListeners();
  }

  // Semantic colors that adapt to the current theme.
  // Used by the app shell (sidebar/nav) and the Settings tab.
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
}

