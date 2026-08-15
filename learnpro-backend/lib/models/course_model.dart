class CourseModel {
  final int id;
  final String title;
  final String description;
  final int xpReward;
  final String track; // เช่น 'swe', 'data', 'design'
  final String? imageUrl;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.track,
    this.imageUrl,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'ไม่มีชื่อคอร์ส',
      description: json['description'] ?? '',
      xpReward: json['xp_reward'] ?? 0,
      track: json['track'] ?? 'general',
      imageUrl: json['image_url'],
    );
  }
}