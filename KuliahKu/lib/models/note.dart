import '../core/validators.dart';

/// Catatan kuliah. Immutable.
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.course = '',
    required this.lastUpdated,
  });

  final String id;
  final String title;
  final String content;
  final String course;
  final DateTime lastUpdated;

  bool get hasCourse => course.trim().isNotEmpty;

  /// Kompatibel dengan format `notes.json` versi lama.
  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id']?.toString() ?? generateId(),
        title: json['title']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        course: json['course']?.toString() ?? '',
        lastUpdated: DateTime.tryParse(json['lastUpdated']?.toString() ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'course': course,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        content.toLowerCase().contains(q) ||
        course.toLowerCase().contains(q);
  }
}
