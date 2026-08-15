import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/app_constants.dart';
import '../widgets/google_fonts_shim.dart';
import '../widgets/app_toast.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Map<String, String> _trackNames = {
    'swe': 'Software & Web Development',
    'data': 'Data & AI Engineering',
    'devops': 'Cloud & DevOps',
    'sec': 'Cybersecurity',
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: state.bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: state.cardAltColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.settings_outlined, color: state.accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text('แถบตั้งค่า', style: GoogleFonts.prompt(color: state.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text('ตั้งค่ารวมของทั้งแอป — ใช้ร่วมกันทุกหน้าจอ',
                style: GoogleFonts.prompt(color: state.textMuted, fontSize: 12)),
            const SizedBox(height: 24),
            _buildThemeSection(context, state),
            const SizedBox(height: 20),
            _buildProfileSection(context, state),
            const SizedBox(height: 20),
            _buildSettingsSection(context, state),
            const SizedBox(height: 20),
            _buildCurriculumSection(context, state),
            const SizedBox(height: 20),
            _buildHistorySection(context, state),
            const SizedBox(height: 20),
            _buildGuideSection(context, state),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── ธีม (Theme) ──────────────────────────
  Widget _buildThemeSection(BuildContext context, AppState state) {
    return _sectionCard(
      state: state,
      icon: Icons.palette_outlined,
      title: 'ธีม (Theme)',
      child: Row(
        children: [
          Expanded(
            child: _themeOptionCard(
              context: context,
              state: state,
              selected: !state.isLightTheme,
              label: 'ธีมที่ใช้ปัจจุบัน',
              subtitle: 'Dark',
              icon: Icons.dark_mode_outlined,
              swatch: const Color(0xFF0A0F1A),
              onTap: () => context.read<AppState>().toggleTheme(false),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _themeOptionCard(
              context: context,
              state: state,
              selected: state.isLightTheme,
              label: 'ธีมสีขาวฟ้า',
              subtitle: 'Light Blue',
              icon: Icons.light_mode_outlined,
              swatch: const Color(0xFFEAF3FF),
              onTap: () => context.read<AppState>().toggleTheme(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeOptionCard({
    required BuildContext context,
    required AppState state,
    required bool selected,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color swatch,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? state.accentColor.withValues(alpha: 0.12) : state.cardAltColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? state.accentColor : state.borderColorSoft, width: selected ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: swatch,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: state.borderColorSoft),
                  ),
                  child: Icon(icon, size: 12, color: swatch.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70),
                ),
                const Spacer(),
                if (selected) Icon(Icons.check_circle, color: state.accentColor, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.prompt(color: state.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold)),
            Text(subtitle, style: GoogleFonts.prompt(color: state.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required AppState state, required IconData icon, required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: state.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: state.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: state.accentColor, size: 16),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.prompt(color: state.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ── โปรไฟล์ ──────────────────────────────
  Widget _buildProfileSection(BuildContext context, AppState state) {
    return _sectionCard(
      state: state,
      icon: Icons.person_outline,
      title: 'โปรไฟล์ (Profile)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF047857)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('Lv.${state.level}',
                    style: GoogleFonts.prompt(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.currentRole,
                        style: GoogleFonts.prompt(color: state.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('฿${formatMoney(state.currentSalary)}/เดือน · ${state.totalXP} XP',
                        style: GoogleFonts.prompt(color: const Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade900.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade700, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 12),
                    Text(' ${state.streakDays} วัน',
                        style: GoogleFonts.prompt(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.xpIntoLevel / 100.0,
              minHeight: 6,
              backgroundColor: Colors.black26,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),
          const SizedBox(height: 4),
          Text('${state.xpIntoLevel}/100 XP ไปเลเวลถัดไป',
              style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 10)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('สายงานที่เลือก: ${_trackNames[state.selectedTrack] ?? '-'}',
                    style: GoogleFonts.prompt(color: const Color(0xFF94A3B8), fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ),
              Text('${state.earnedBadges.length}/${kBadges.length} เหรียญตรา',
                  style: GoogleFonts.prompt(color: const Color(0xFF94A3B8), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ── ตั้งค่า ────────────────────────────────
  Widget _buildSettingsSection(BuildContext context, AppState state) {
    return _sectionCard(
      state: state,
      icon: Icons.tune,
      title: 'ตั้งค่า (Settings)',
      child: Column(
        children: [
          _switchTile(
            state: state,
            title: 'บันทึกอัตโนมัติ',
            subtitle: 'บันทึกโค้ดเมื่อสลับไฟล์ใน Sandbox',
            value: state.settingsAutoSave,
            onChanged: (v) => context.read<AppState>().updateAutoSave(v),
          ),
          const SizedBox(height: 8),
          _switchTile(
            state: state,
            title: 'แสดงหมายเลขบรรทัด',
            subtitle: 'แสดงเลขบรรทัดใน Code Editor',
            value: state.settingsShowLineNumbers,
            onChanged: (v) => context.read<AppState>().updateShowLineNumbers(v),
          ),
          const SizedBox(height: 8),
          _switchTile(
            state: state,
            title: 'การแจ้งเตือน',
            subtitle: 'แจ้งเตือนเมื่อได้รับ XP หรือเหรียญตราใหม่',
            value: state.settingsNotifications,
            onChanged: (v) => context.read<AppState>().updateNotifications(v),
          ),
          const SizedBox(height: 8),
          _switchTile(
            state: state,
            title: 'เอฟเฟกต์เสียง',
            subtitle: 'เสียงเมื่อรันโค้ดสำเร็จ',
            value: state.settingsSoundEffects,
            onChanged: (v) => context.read<AppState>().updateSoundEffects(v),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: state.cardAltColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ขนาดตัวอักษร Editor', style: GoogleFonts.prompt(color: state.textPrimary, fontSize: 13)),
                DropdownButton<String>(
                  value: state.settingsFontSize,
                  dropdownColor: state.cardColor,
                  style: GoogleFonts.prompt(color: state.textPrimary, fontSize: 12),
                  underline: const SizedBox(),
                  items: ['เล็ก', 'ปกติ', 'ใหญ่'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) {
                    if (v != null) context.read<AppState>().updateFontSize(v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmReset(context),
              icon: const Icon(Icons.restart_alt, size: 16, color: Color(0xFFF87171)),
              label: Text('รีเซ็ตความคืบหน้าทั้งหมด', style: GoogleFonts.prompt(color: const Color(0xFFF87171), fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF7F1D1D)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required AppState state,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: state.cardAltColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.prompt(color: state.textPrimary, fontSize: 13)),
                Text(subtitle, style: GoogleFonts.prompt(color: state.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Switch(value: value, activeColor: state.accentColor, onChanged: onChanged),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    final state = context.read<AppState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: state.cardColor,
        title: Text('รีเซ็ตความคืบหน้า?', style: GoogleFonts.prompt(color: state.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('ล้างความคืบหน้าทั้งหมดเพื่อเริ่มใหม่หรือไม่?',
            style: GoogleFonts.prompt(color: state.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('ยกเลิก', style: GoogleFonts.prompt(color: state.textSecondary)),
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

  // ── หลักสูตรที่ได้เลือกไว้ / วางแผนไว้ ──────────────
  Widget _buildCurriculumSection(BuildContext context, AppState state) {
    return _sectionCard(
      state: state,
      icon: Icons.menu_book_outlined,
      title: 'หลักสูตรที่ได้เลือกไว้ / วางแผนไว้',
      child: Column(
        children: state.plannedCurriculum.map((topic) {
          final done = state.completedCurriculum.contains(topic);
          return GestureDetector(
            onTap: () => context.read<AppState>().toggleCurriculumTopic(topic),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: done ? const Color(0xFF064E3B).withValues(alpha: 0.4) : state.cardAltColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: done ? const Color(0xFF065F46) : state.borderColorSoft),
              ),
              child: Row(
                children: [
                  Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: done ? const Color(0xFF34D399) : state.textMuted, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(topic,
                        style: GoogleFonts.prompt(
                            color: done ? const Color(0xFF34D399) : state.textPrimary,
                            fontSize: 12.5,
                            decoration: done ? TextDecoration.lineThrough : null)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── ประวัติการฝึกล่าสุด ────────────────────
  Widget _buildHistorySection(BuildContext context, AppState state) {
    return _sectionCard(
      state: state,
      icon: Icons.history,
      title: 'ประวัติการฝึกล่าสุด',
      child: state.runHistory.isEmpty
          ? Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('ยังไม่มีประวัติการฝึก — ลองไปรันโค้ดใน Live Sandbox ดูสิ!',
            style: GoogleFonts.prompt(color: state.textMuted, fontSize: 12)),
      )
          : Column(
        children: state.runHistory.take(6).map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: state.cardAltColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal, color: state.textMuted, size: 14),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(entry.missionTitle,
                      style: GoogleFonts.prompt(color: state.textPrimary, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
                Text(entry.timeLabel, style: GoogleFonts.prompt(color: state.textMuted, fontSize: 10)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── คู่มือการใช้งาน ────────────────────────
  Widget _buildGuideSection(BuildContext context, AppState state) {
    final items = <MapEntry<String, String>>[
      const MapEntry('หน้าหลัก IT Center', 'ภาพรวมความคืบหน้า เงินเดือนเป้าหมาย และ XP ของคุณ'),
      const MapEntry('AI Mentor Chat', 'พูดคุยกับ AI เพื่อขอคำแนะนำด้านสายงาน IT'),
      const MapEntry('IT Tracks & Fields', 'เลือกสายงาน IT ที่สนใจ เช่น SWE, Data, DevOps, Security'),
      const MapEntry('Career Roadmap', 'ดูเส้นทางความก้าวหน้าในสายอาชีพ IT'),
      const MapEntry('Live Sandbox', 'ฝึกเขียนโค้ด Python จริงและรัน Test Cases เพื่อรับ XP'),
      const MapEntry('ตั้งค่า (Settings)', 'จัดการโปรไฟล์ ตั้งค่าแอป ปรับธีม และดูประวัติการฝึกของคุณ'),
    ];
    return _sectionCard(
      state: state,
      icon: Icons.help_outline,
      title: 'คู่มือการใช้งาน',
      child: Column(
        children: items.map((e) {
          return Theme(
            data: (state.isLightTheme ? ThemeData.light() : ThemeData.dark())
                .copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              iconColor: state.textMuted,
              collapsedIconColor: state.textMuted,
              title: Text(e.key,
                  style: GoogleFonts.prompt(color: state.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600)),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(e.value, style: GoogleFonts.prompt(color: state.textSecondary, fontSize: 11.5)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}