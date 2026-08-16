class CourseModel {
  final String id;
  final String title;
  final String? category;
  final String? summary;
  final String? coverImageUrl;
  final String? durationText;
  final String? difficultyLevel;
  final double rating;
  final String? instructor;
  final String? badgeEarned;
  final int totalLessons;
  final int likeCount;
  final int shareCount;
  final DateTime? createdAt;

  CourseModel({
    required this.id,
    required this.title,
    this.category,
    this.summary,
    this.coverImageUrl,
    this.durationText,
    this.difficultyLevel,
    this.rating = 5.0,
    this.instructor,
    this.badgeEarned,
    this.totalLessons = 1,
    this.likeCount = 0,
    this.shareCount = 0,
    this.createdAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'ไม่มีชื่อคอร์ส',
      category: json['category'],
      summary: json['summary'],
      coverImageUrl: json['cover_image_url'],
      durationText: json['duration_text'],
      difficultyLevel: json['difficulty_level'],
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      instructor: json['instructor'],
      badgeEarned: json['badge_earned'],
      totalLessons: (json['total_lessons'] ?? 1) as int,
      likeCount: (json['like_count'] ?? 0) as int,
      shareCount: (json['share_count'] ?? 0) as int,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
