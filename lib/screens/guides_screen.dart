import 'package:flutter/material.dart';
import '../services/guide_service.dart';
import '../models/user_guide.dart';

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  late Future<List<UserGuide>> _future;

  @override
  void initState() {
    super.initState();
    _future = GuideService().listGuides();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('คู่มือ')),
      body: FutureBuilder<List<UserGuide>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final guides = snap.data ?? [];
          if (guides.isEmpty) {
            return const Center(child: Text('ยังไม่มีบทความ'));
          }
          return ListView.builder(
            itemCount: guides.length,
            itemBuilder: (_, i) {
              final g = guides[i];
              return ListTile(
                title: Text(g.title),
                subtitle: Text(
                  '${g.category} · ${g.readingTimeMins} นาที · ${g.viewsCount} views',
                ),
                onTap: () async {
                  final detail = await GuideService().getGuide(g.id);
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GuideDetailScreen(guide: detail),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class GuideDetailScreen extends StatelessWidget {
  final UserGuide guide;
  const GuideDetailScreen({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(guide.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(guide.content ?? guide.summary),
      ),
    );
  }
}