// lib/utils/enums/app_theme.dart - English language version
import 'package:flutter/material.dart';

enum AppThemeEnum {
  system,
  light,
  dark,
}

extension AppThemeExtension on AppThemeEnum {
  String get displayName {
    switch (this) {
      case AppThemeEnum.system:
        return 'Auto theme enabled';
      case AppThemeEnum.light:
        return 'Light theme enabled';
      case AppThemeEnum.dark:
        return 'Dark theme enabled';
    }
  }

  String get description {
    switch (this) {
      case AppThemeEnum.system:
        return 'Follows your device settings';
      case AppThemeEnum.light:
        return 'Bright background for daytime reading';
      case AppThemeEnum.dark:
        return 'Dark background for night reading';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeEnum.system:
        return Icons.brightness_auto;
      case AppThemeEnum.light:
        return Icons.light_mode;
      case AppThemeEnum.dark:
        return Icons.dark_mode;
    }
  }
}