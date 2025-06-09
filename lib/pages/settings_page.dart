// lib/pages/settings_page.dart - Simple and reliable
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
        'الإعدادات',
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
          _buildSectionTitle('المظهر والعرض'),
          const SizedBox(height: 16),
          _buildThemeSection(themeController),
          const SizedBox(height: 32),
          _buildSectionTitle('حول التطبيق'),
          const SizedBox(height: 16),
          _buildInfoSection(),
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
        children: AppThemeEnum.values.map((theme) {
          final isLast = theme == AppThemeEnum.values.last;
          return Column(
            children: [
              Obx(() => _buildThemeOption(
                theme: theme,
                isSelected: themeController.isSelected(theme),
                onTap: () => themeController.updateTheme(theme),
              )),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThemeOption({
    required AppThemeEnum theme,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isRecommended = theme == AppThemeEnum.system;

    return ListTile(
      leading: Icon(
        theme.icon,
        color: isSelected ? Get.theme.colorScheme.primary : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              theme.displayName,
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
                'مُوصى',
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
        theme.description,
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

  Widget _buildInfoSection() {
    return Card(
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.info_outline,
            title: 'إصدار التطبيق',
            subtitle: '1.0.0',
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.book,
            title: 'عدد الصفحات',
            subtitle: '604 صفحة',
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.storage,
            title: 'قواعد البيانات',
            subtitle: 'النص العثماني + تخطيط المصحف',
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.text_fields,
            title: 'الخطوط المستخدمة',
            subtitle: 'Digital, Uthmani, Me Quran',
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.brightness_auto,
            title: 'المظهر الافتراضي',
            subtitle: 'يتبع إعدادات النظام تلقائياً',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Digital',
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'Digital',
          fontSize: 12,
        ),
      ),
    );
  }
}