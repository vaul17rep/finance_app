import 'package:flutter/material.dart';

class AppColors {
  // ==================== Светлая тема ====================
  static const background = Color(0xFFF5F7FA);
  static const card = Color(0xFFFFFFFF);
  static const primary = Color(
    0xFF7BA9F5,
  ); // теперь не используется в карточках
  static const textPrimary = Color(0xFF2D3748);
  static const textSecondary = Color(0xFF718096);
  static const income = Color(0xFF81C784);
  static const expense = Color(0xFFE57373);
  static const divider = Color(0xFFE2E8F0);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEDF2F7);

  // Цвета для карточек счетов (пастельные, приятные)
  static const cardGradientStart = Color(0xFFB3C6E7); // нежный голубой
  static const cardGradientEnd = Color(0xFF8BA7D4); // чуть насыщеннее
  static const star = Color(0xFFFFC107); // Amber

  // Можно добавить альтернативные варианты (для разных типов счетов)
  static const cardGreenStart = Color(0xFFA8D5BA);
  static const cardGreenEnd = Color(0xFF81C784);
  static const cardPurpleStart = Color(0xFFD1C4E9);
  static const cardPurpleEnd = Color(0xFFB39DDB);
  static const cardOrangeStart = Color(0xFFFFE0B2);
  static const cardOrangeEnd = Color(0xFFFFCC80);

  // ==================== Тёмная тема ====================
  static const darkBackground = Color(0xFF12121A);
  static const darkCard = Color(0xFF1E1E2A);
  static const darkPrimary = Color(0xFF4A7FB5);
  static const darkTextPrimary = Color(0xFFD1D5DB);
  static const darkTextSecondary = Color(0xFF9CA3AF);
  static const darkDivider = Color(0xFF2D2D3A);
  static const darkSurface = Color(0xFF1E1E2A);
  static const darkSurfaceVariant = Color(0xFF2D2D3A);

  // Карточки в тёмной теме – приглушённые, тёплые
  static const darkCardGradientStart = Color(0xFF2D3A5A);
  static const darkCardGradientEnd = Color(0xFF1E2A44);
}
