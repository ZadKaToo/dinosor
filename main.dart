import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'state/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fvccmpvjvahvoqglfizt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ2Y2NtcHZqdmFodm9xZ2xmaXp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY2ODc3NjcsImV4cCI6MjEwMjI2Mzc2N30.3E6y4EETGMWGATTsXGW_yhx3VdlzOSLpnWZc2Hfi6tY',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const LearnProApp(),
    ),
  );
}

class LearnProApp extends StatelessWidget {
  const LearnProApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'LearnPro MAX — IT Career Platform',
      debugShowCheckedModeBanner: false,
      theme: state.themeData,
      // ใช้ AuthGate เพื่อตรวจสอบสถานะก่อนว่าต้องไปหน้าไหน
      home: const AuthGate(),
    );
  }
}

/// Widget สำหรับตรวจสอบสถานะ Session ของ Supabase
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // รอสักนิดเพื่อให้ UI build เสร็จก่อนทำการ Navigate
    await Future.delayed(const Duration(milliseconds: 500));

    // บังคับล้าง session ทุกครั้งที่เปิดแอป เพื่อให้ต้อง login ใหม่เสมอ
    // (ปิดการ "จำ session" ของ Supabase ที่เก็บไว้ในเครื่อง)
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    // ไม่ต้องเช็ค session อีกต่อไป เพราะเพิ่ง sign out ไปแล้ว
    // จะไปหน้า Login เสมอ
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // หน้าจอโหลดชั่วคราวระหว่างเช็คสถานะ
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}