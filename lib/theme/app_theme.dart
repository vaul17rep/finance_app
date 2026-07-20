import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: AppColors.background,

    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),

    textTheme: TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      headlineMedium: AppTextStyles.balance,
      titleLarge: AppTextStyles.title,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.secondary,
      labelMedium: AppTextStyles.caption,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
