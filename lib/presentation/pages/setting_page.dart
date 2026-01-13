import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/component/setting_tile.dart';
import 'package:pdf_kit/presentation/models/setting_info_type.dart';
import 'package:pdf_kit/providers/locale_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<String?> _resolveDefaultPdfInitialPath() async {
    final stored = Prefs.getString(Constants.pdfOutputFolderPathKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored;
    }
    return null;
  }

  Future<String?> _resolveDefaultCameraInitialPath() async {
    final stored = Prefs.getString(Constants.imagesFolderPathKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored;
    }
    return null;
  }

  Future<String?> _resolveDefaultScreenshotInitialPath() async {
    final stored = Prefs.getString(Constants.screenshotsFolderPathKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localeCode =
        context.watch<LocaleProvider>().locale?.languageCode ?? 'en';
    final languageDisplay =
        localeCode == 'hi' ? t.t('language_option_hindi') : t.t('language_option_english');

    final items = <SettingsItem>[
      SettingsItem(
        id: 'language',
        title: t.t('settings_language_item_title'),
        subtitle: t.t('settings_language_item_subtitle'),
        type: SettingsItemType.value,
        trailingText: languageDisplay,
        leadingIcon: Icons.language,
        onTap: () {
          context.push('/settings/language');
        },
      ),
      SettingsItem(
        id: 'default_save',
        title: t.t('settings_default_save_location_title'),
        subtitle: t.t('settings_default_save_location_subtitle'),
        type: SettingsItemType.navigation,
        leadingIcon: Icons.folder_outlined,
        onTap: () async {
          final initialPath = await _resolveDefaultPdfInitialPath();
          if (!context.mounted) return;

          final extra = <String, dynamic>{
            'title': t.t('files_pdfs_folder'),
            'description': t.t('folder_picker_description_pdfs'),
            if (initialPath != null) 'path': initialPath,
          };

          final res = await context.pushNamed(
            AppRouteName.folderPickScreen,
            extra: extra,
          );

          final selectedPath = res is String ? res : null;
          if (selectedPath == null || selectedPath.trim().isEmpty) return;
          await Prefs.setString(Constants.pdfOutputFolderPathKey, selectedPath);
        },
      ),
      SettingsItem(
        id: 'default_camera_save',
        title: t.t('settings_default_camera_location_title'),
        subtitle: t.t('settings_default_camera_location_subtitle'),
        type: SettingsItemType.navigation,
        leadingIcon: Icons.camera_alt_outlined,
        onTap: () async {
          final initialPath = await _resolveDefaultCameraInitialPath();
          if (!context.mounted) return;

          final extra = <String, dynamic>{
            'title': t.t('files_images_folder'),
            'description': t.t('folder_picker_description_images'),
            if (initialPath != null) 'path': initialPath,
          };

          final res = await context.pushNamed(
            AppRouteName.folderPickScreen,
            extra: extra,
          );

          final selectedPath = res is String ? res : null;
          if (selectedPath == null || selectedPath.trim().isEmpty) return;
          await Prefs.setString(Constants.imagesFolderPathKey, selectedPath);
        },
      ),
      SettingsItem(
        id: 'default_screenshot_save',
        title: t.t('settings_default_screenshot_location_title'),
        subtitle: t.t('settings_default_screenshot_location_subtitle'),
        type: SettingsItemType.navigation,
        leadingIcon: Icons.screenshot,
        onTap: () async {
          final initialPath = await _resolveDefaultScreenshotInitialPath();
          if (!context.mounted) return;

          final extra = <String, dynamic>{
            'title': t.t('files_screenshots_folder'),
            'description': t.t('folder_picker_description_screenshots'),
            if (initialPath != null) 'path': initialPath,
          };

          final res = await context.pushNamed(
            AppRouteName.folderPickScreen,
            extra: extra,
          );

          final selectedPath = res is String ? res : null;
          if (selectedPath == null || selectedPath.trim().isEmpty) return;
          await Prefs.setString(
            Constants.screenshotsFolderPathKey,
            selectedPath,
          );
        },
      ),
      SettingsItem(
        id: 'dark_mode',
        title: t.t('settings_dark_mode_title'),
        subtitle: t.t('settings_dark_mode_subtitle'),
        type: SettingsItemType.navigation,
        leadingIcon: Icons.palette_outlined,
        onTap: () {
          context.push('/settings/theme');
        },
      ),
      SettingsItem(
        id: 'filter_options',
        title: t.t('settings_filter_options_title'),
        subtitle: t.t('settings_filter_options_subtitle'),
        type: SettingsItemType.navigation,
        leadingIcon: Icons.filter_list,
        onTap: () {
          context.push('/settings/filter-options');
        },
      ),
      SettingsItem(
        id: 'pdf_content_fit',
        title: t.t('settings_pdf_content_fit_title'),
        subtitle: t.t('settings_pdf_content_fit_subtitle'),
        type: SettingsItemType.navigation,
        leadingIcon: Icons.crop_landscape,
        onTap: () {
          context.push('/settings/pdf-content-fit');
        },
      ),
      SettingsItem(
        id: 'help_center',
        title: t.t('settings_help_center_title'),
        subtitle: t.t('settings_help_center_subtitle'),
        type: SettingsItemType.navigation,
        leadingIcon: Icons.help_outline,
        onTap: () {
          context.push('/settings/help-support');
        },
      ),
      SettingsItem(
        id: 'about_pdfkit',
        title: t.t('settings_about_pdf_kit_title'),
        subtitle: t.t('settings_about_pdf_kit_subtitle'),
        type: SettingsItemType.navigation,
        leadingIcon: Icons.info_outline,
        onTap: () {
          context.push('/settings/about-pdf-kit');
        },
      ),
      SettingsItem(
        id: 'about_us',
        title: t.t('settings_about_us_title'),
        subtitle: t.t('settings_about_us_subtitle'),
        type: SettingsItemType.navigation,
        leadingIcon: Icons.group_outlined,
        onTap: () {
          context.push('/settings/about-us');
        },
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: screenPadding,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox.shrink(),
                  itemBuilder: (context, index) {
                    return SettingsTile(item: items[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Icon(
                    Icons.widgets_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).t('home_brand_title'),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
