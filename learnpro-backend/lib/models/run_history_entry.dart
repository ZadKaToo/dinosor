class RunHistoryEntry {
  final String missionTitle;
  final String code;
  final String output;
  final DateTime timestamp;

  RunHistoryEntry({
    required this.missionTitle,
    required this.code,
    required this.output,
    required this.timestamp,
  });

  String get timeLabel {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inSeconds < 60) return 'เมื่อกี้';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    return '${diff.inHours} ชั่วโมงที่แล้ว';
  }
}
