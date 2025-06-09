// lib/controllers/theme_controller.dart - Simple and reliable
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mushaf_practice/utils/enums/app_theme.dart';

class ThemeController extends GetxController {
  final _storage = GetStorage();
  final _key = 'selectedTheme';

  // Default to system theme
  Rx<AppThemeEnum> selectedTheme = AppThemeEnum.system.obs;

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromStorage();
    Get.changeThemeMode(themeMode);
  }

  void _loadThemeFromStorage() {
    final storedTheme = _storage.read(_key);
    if (storedTheme != null) {
      selectedTheme.value = AppThemeEnum.values[storedTheme];
    }
  }

  ThemeMode get themeMode {
    switch (selectedTheme.value) {
      case AppThemeEnum.light:
        return ThemeMode.light;
      case AppThemeEnum.dark:
        return ThemeMode.dark;
      case AppThemeEnum.system:
        return ThemeMode.system; // Flutter handles this automatically!
    }
  }

  void updateTheme(AppThemeEnum theme) {
    selectedTheme.value = theme;
    _storage.write(_key, theme.index);
    Get.changeThemeMode(themeMode);
    _showThemeChangeFeedback(theme);
  }

  void _showThemeChangeFeedback(AppThemeEnum theme) {
    Get.snackbar(
      'تم تغيير المظهر',
      theme.displayName,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: Get.theme.colorScheme.surface,
      colorText: Get.theme.colorScheme.onSurface,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: Icon(
        theme.icon,
        color: Get.theme.colorScheme.primary,
      ),
    );
  }

  // Helper methods for UI
  bool isSelected(AppThemeEnum theme) => selectedTheme.value == theme;

  String get currentThemeName => selectedTheme.value.displayName;

  IconData get currentThemeIcon => selectedTheme.value.icon;
}