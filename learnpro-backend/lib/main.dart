import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'screens/main_layout_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const MainLayoutScreen(),
    );
  }
}
