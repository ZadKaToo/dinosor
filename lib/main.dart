import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'state/app_state.dart';
import 'screens/login_screen.dart'; // ✅ นำเข้า LoginScreen เป็นหน้าแรก

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rbdjjzqdhftrzlwrewej.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJiZGpqenFkaGZ0cnpsd3Jld2VqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY4NTkyMjYsImV4cCI6MjEwMjQzNTIyNn0.wBUj_YJf6SwptOC1X6alsh2egKhKhq99n9M4GfOw4ys',
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
      home: const LoginScreen(), // ✅ เปลี่ยนจาก MainLayoutScreen เป็น LoginScreen
    );
  }
}