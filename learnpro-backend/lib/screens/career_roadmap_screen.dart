import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../state/app_state.dart';
import '../constants/app_constants.dart';
import '../widgets/google_fonts_shim.dart';
import '../services/job_service.dart'; // <-- อย่าลืมเช็ค path ให้ตรงกับโปรเจกต์ของคุณ

class CareerRoadmapScreen extends StatelessWidget {
  const CareerRoadmapScreen({super.key});

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
            Text('Career Roadmap (IT Industry)',
                style: GoogleFonts.prompt(color: state.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('บันไดความก้าวหน้าและฐานเงินเดือนจริงในอุตสาหกรรม IT ไทย',
                style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 20),
            _roadmapStep(
              context,
              state,
              iconData: Icons.rocket_launch_outlined,
              title: 'Junior IT / Dev Specialist',
              levelParam: 'Junior', // ส่งค่าไปให้ API ค้นหา
              requiredXP: 0,
              skills: 'ทักษะพื้นฐาน Coding, Basic Scripting, Database Fundamentals, Network Intro',
              start: 20000,
              avg: 28000,
              max: 35000,
              years: '0–2 ปี',
              color: const Color(0xFF10B981),
            ),
            _roadmapArrow(),
            _roadmapStep(
              context,
              state,
              iconData: Icons.layers_outlined,
              title: 'Mid-Level IT Specialist',
              levelParam: 'Mid-level', // ส่งค่าไปให้ API ค้นหา
              requiredXP: 180,
              skills: 'OOP, API Design, Containerization, Automation & Security Basics',
              start: 40000,
              avg: 60000,
              max: 80000,
              years: '2–5 ปี',
              color: const Color(0xFF3B82F6),
            ),
            _roadmapArrow(),
            _roadmapStep(
              context,
              state,
              iconData: Icons.workspace_premium_outlined,
              title: 'Senior IT Expert / Specialist',
              levelParam: 'Senior', // ส่งค่าไปให้ API ค้นหา
              requiredXP: 400,
              skills: 'System Design, High Availability, Cloud Architecture, Advanced Security',
              start: 85000,
              avg: 115000,
              max: 150000,
              years: '5+ ปี',
              color: const Color(0xFFA855F7),
            ),
            _roadmapArrow(),
            _roadmapStep(
              context,
              state,
              iconData: Icons.emoji_events_outlined,
              title: 'Tech Lead / Solution Architect / CTO',
              levelParam: 'Lead', // ส่งค่าไปให้ API ค้นหา
              requiredXP: 700,
              skills: 'IT Strategy, Enterprise Architecture, Business Alignment, Leadership',
              start: 180000,
              avg: 250000,
              max: -1,
              years: '8+ ปี',
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: state.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: state.borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.radar, color: Color(0xFF60A5FA), size: 18),
                      const SizedBox(width: 8),
                      Text('IT Multi-Domain Skill Analysis',
                          style: GoogleFonts.prompt(color: state.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
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
                            fillColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
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
                            fillColor: const Color(0xFF10B981).withValues(alpha: 0.25),
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
    BuildContext context,
    AppState state, {
    required IconData iconData,
    required String title,
    required String levelParam,
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
        color: unlocked ? color.withValues(alpha: 0.08) : state.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: unlocked ? color.withValues(alpha: 0.4) : state.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
            child: Icon(iconData, color: color, size: 26),
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
                            color: unlocked ? state.textPrimary : state.textMuted,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: unlocked ? color.withValues(alpha: 0.2) : state.cardAltColor,
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
                // --- ส่วนที่เพิ่มเข้ามาใหม่: ปุ่มกดดูงาน ---
                if (unlocked) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showJobListModal(context, state, title, levelParam, color),
                      icon: const Icon(Icons.work_outline, size: 16),
                      label: Text('ดูงานที่เปิดรับสำหรับขั้นนี้', style: GoogleFonts.prompt(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ]
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

  // --- ส่วนที่เพิ่มเข้ามาใหม่: BottomSheet แสดงรายการงาน ---
  void _showJobListModal(BuildContext context, AppState state, String title, String experienceLevel, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: state.isLightTheme ? Colors.white : state.bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: state.borderColor)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.work, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'งาน $title',
                          style: GoogleFonts.prompt(
                              color: state.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: state.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
                // FutureBuilder ดึงข้อมูลงาน
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: JobService.getJobs(experience: experienceLevel),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: color));
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล',
                              style: GoogleFonts.prompt(color: Colors.red)),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text('ยังไม่มีตำแหน่งงานว่างสำหรับระดับนี้',
                              style: GoogleFonts.prompt(color: state.textMuted)),
                        );
                      }

                      final jobs = snapshot.data!;
                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: jobs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final job = jobs[index];
                          // โครงสร้างขึ้นอยู่กับ API Response ของคุณ (ปรับแก้ key ได้ตามจริง)
                          final jobTitle = job['title'] ?? 'ไม่ระบุตำแหน่ง';
                          final company = job['company'] ?? 'ไม่ระบุบริษัท';
                          final salary = job['salary'] ?? 'เจรจาต่อรองได้';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: state.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: state.borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(jobTitle,
                                    style: GoogleFonts.prompt(
                                        color: state.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(company,
                                    style: GoogleFonts.prompt(color: state.textMuted, fontSize: 13)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    salary,
                                    style: GoogleFonts.prompt(
                                        color: color, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}