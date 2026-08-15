import 'package:flutter/material.dart';
import '../models/salary_tier.dart';
import '../models/badge_def.dart';
import '../models/sandbox_mission.dart';

const String kMentorApiUrl = "https://curvy-geese-do.loca.lt/api/mentor";

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

const List<BadgeDef> kBadges = [
  BadgeDef('first_run', Icons.play_arrow_rounded, 'First Run', 'รันโค้ดครั้งแรก'),
  BadgeDef('first_pass', Icons.check_circle_outline, 'Test Passer', 'ผ่าน Test แรก'),
  BadgeDef('streak3', Icons.local_fire_department, 'On Fire!', '3 วันติดต่อกัน'),
  BadgeDef('xp50', Icons.star_outline, 'Rising Star', 'สะสม 50 XP'),
  BadgeDef('xp100', Icons.looks_one_outlined, 'Century Club', 'สะสม 100 XP'),
  BadgeDef('mission1', Icons.flag_outlined, 'Mission Pro', 'ผ่าน Mission 1'),
  BadgeDef('coder', Icons.terminal, 'IT Practitioner', 'ใช้งาน Sandbox 10 ครั้ง'),
  BadgeDef('xp200', Icons.rocket_launch_outlined, 'Rocket Dev', 'สะสม 200 XP'),
];

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
