import 'package:flutter/material.dart';

class Mood {
  Mood._();

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

  static Color color(int mood) {
    switch (mood) {
      case 1:
        return const Color(0xFFE53935);
      case 2:
        return const Color(0xFFFB8C00);
      case 3:
        return const Color(0xFFFDD835);
      case 4:
        return const Color(0xFF7CB342);
      case 5:
        return const Color(0xFF43A047);
      default:
        return const Color(0xFFFDD835);
    }
  }
}
