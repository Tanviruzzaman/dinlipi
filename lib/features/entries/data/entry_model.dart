import 'package:cloud_firestore/cloud_firestore.dart';

/// A single journal entry.
///
/// Stored at `users/{uid}/entries/{entryId}`.
class Entry {
  const Entry({
    required this.id,
    required this.title,
    required this.body,
    required this.mood,
    required this.tags,
    required this.photoUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final int mood; // 1–5
  final List<String> tags;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// A blank entry for the "new entry" screen.
  factory Entry.empty() => Entry(
        id: '',
        title: '',
        body: '',
        mood: 3,
        tags: const [],
        photoUrls: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  factory Entry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return Entry(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      mood: (data['mood'] as num?)?.toInt() ?? 3,
      tags: _stringList(data['tags']),
      photoUrls: _stringList(data['photoUrls']),
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  /// Content fields only. Timestamps are set by the repository using
  /// server timestamps, so they are intentionally excluded here.
  Map<String, dynamic> toContentMap() => {
        'title': title,
        'body': body,
        'mood': mood,
        'tags': tags,
        'photoUrls': photoUrls,
      };

  Entry copyWith({
    String? id,
    String? title,
    String? body,
    int? mood,
    List<String>? tags,
    List<String>? photoUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Entry(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    // createdAt/updatedAt can be momentarily null while a server timestamp
    // is pending; fall back to "now" so the UI never breaks.
    return DateTime.now();
  }
}
