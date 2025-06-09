// lib/utils/enums/app_theme.dart
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
        return 'تلقائي حسب النظام';
      case AppThemeEnum.light:
        return 'الوضع النهاري';
      case AppThemeEnum.dark:
        return 'الوضع الليلي';
    }
  }

  String get description {
    switch (this) {
      case AppThemeEnum.system:
        return 'يتبع إعدادات نظام الجهاز';
      case AppThemeEnum.light:
        return 'خلفية فاتحة مناسبة للقراءة في النهار';
      case AppThemeEnum.dark:
        return 'خلفية داكنة مناسبة للقراءة في الليل';
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