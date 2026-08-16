// lib/models/user_guide.dart
class UserGuide {
  final int id;
  final String title;
  final String summary;
  final String? content;
  final String category;
  final int readingTimeMins;
  final int viewsCount;
  final DateTime? createdAt;

  UserGuide({
    required this.id,
    required this.title,
    required this.summary,
    this.content,
    required this.category,
    required this.readingTimeMins,
    required this.viewsCount,
    this.createdAt,
  });

  factory UserGuide.fromJson(Map<String, dynamic> json) {
    return UserGuide(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      summary: (json['summary'] ?? '') as String,
      content: json['content'] as String?,
      category: (json['category'] ?? '') as String,
      readingTimeMins: (json['reading_time_mins'] ?? 0) as int,
      viewsCount: (json['views_count'] ?? 0) as int,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}