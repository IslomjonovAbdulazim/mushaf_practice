// lib/pages/settings_page.dart - English language version
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mushaf_practice/controllers/theme_controller.dart';
import 'package:mushaf_practice/utils/enums/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(themeController),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Settings',
        style: TextStyle(
          fontFamily: 'Digital',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Get.back(),
      ),
    );
  }

  Widget _buildBody(ThemeController themeController) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Appearance & Display'),
          const SizedBox(height: 16),
          _buildThemeSection(themeController),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Digital',
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildThemeSection(ThemeController themeController) {
    return Card(
      child: Column(
        children: [
          // System Theme Option (Default & Recommended)
          Obx(() => _buildThemeOption(
            title: 'Automatic (System)',
            subtitle: 'Follows your device dark/light mode settings',
            icon: Icons.brightness_auto,
            isSelected: themeController.isSelected(AppThemeEnum.system),
            onTap: () => themeController.updateTheme(AppThemeEnum.system),
            isRecommended: true,
          )),
          const Divider(height: 1),

          // Light Theme Option
          Obx(() => _buildThemeOption(
            title: 'Light Mode',
            subtitle: 'Bright background suitable for daytime reading',
            icon: Icons.light_mode,
            isSelected: themeController.isSelected(AppThemeEnum.light),
            onTap: () => themeController.updateTheme(AppThemeEnum.light),
          )),
          const Divider(height: 1),

          // Dark Theme Option
          Obx(() => _buildThemeOption(
            title: 'Dark Mode',
            subtitle: 'Dark background suitable for night reading',
            icon: Icons.dark_mode,
            isSelected: themeController.isSelected(AppThemeEnum.dark),
            onTap: () => themeController.updateTheme(AppThemeEnum.dark),
          )),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isRecommended = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Get.theme.colorScheme.primary : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Digital',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Get.theme.colorScheme.primary : null,
              ),
            ),
          ),
          if (isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Get.theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Text(
                'Recommended',
                style: TextStyle(
                  fontFamily: 'Digital',
                  fontSize: 10,
                  color: Get.theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'Digital',
          fontSize: 12,
        ),
      ),
      trailing: isSelected
          ? Icon(
        Icons.check_circle,
        color: Get.theme.colorScheme.primary,
      )
          : const Icon(Icons.radio_button_unchecked),
      onTap: onTap,
    );
  }

}