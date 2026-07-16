import 'package:flutter/material.dart';

/// Helpers for rendering mood values (1–5) consistently across the app.
class Mood {
  Mood._();

  /// Valid mood range.
  static const int min = 1;
  static const int max = 5;

  static const List<int> values = [1, 2, 3, 4, 5];

  static IconData icon(int mood) {
    switch (mood) {
      case 1:
        return Icons.sentiment_very_dissatisfied;
      case 2:
        return Icons.sentiment_dissatisfied;
      case 3:
        return Icons.sentiment_neutral;
      case 4:
        return Icons.sentiment_satisfied;
      case 5:
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  static String label(int mood) {
    switch (mood) {
      case 1:
        return 'Awful';
      case 2:
        return 'Bad';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Great';
      default:
        return 'Okay';
    }
  }

  /// A fixed color per mood, readable in both light and dark themes.
  static Color color(int mood) {
    switch (mood) {
      case 1:
        return const Color(0xFFE53935); // red
      case 2:
        return const Color(0xFFFB8C00); // orange
      case 3:
        return const Color(0xFFFDD835); // yellow
      case 4:
        return const Color(0xFF7CB342); // light green
      case 5:
        return const Color(0xFF43A047); // green
      default:
        return const Color(0xFFFDD835);
    }
  }
}
