import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';

class PdfContentFitSettingsPage extends StatefulWidget {
  const PdfContentFitSettingsPage({super.key});

  @override
  State<PdfContentFitSettingsPage> createState() =>
      _PdfContentFitSettingsPageState();
}

class _PdfContentFitSettingsPageState extends State<PdfContentFitSettingsPage> {
  PdfContentFitMode _selectedMode = PdfContentFitMode.original;

  @override
  void initState() {
    super.initState();
    _loadCurrentMode();
  }

  Future<void> _loadCurrentMode() async {
    final modeString = Prefs.getString(Constants.pdfContentFitModeKey);
    if (modeString != null && mounted) {
      setState(() {
        _selectedMode = PdfContentFitMode.fromString(modeString);
      });
    }
  }

  Future<void> _setMode(PdfContentFitMode mode) async {
    await Prefs.setString(Constants.pdfContentFitModeKey, mode.value);
    setState(() {
      _selectedMode = mode;
    });

    if (mounted) {
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.t('pdf_content_fit_settings_applied_snackbar')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.t('pdf_content_fit_settings_page_title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.t('pdf_content_fit_settings_description'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section title
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                t.t('pdf_content_fit_settings_choose_mode_label'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Option 1: Original Size
            _FitModeCard(
              mode: PdfContentFitMode.original,
              title: t.t('pdf_content_fit_mode_original_title'),
              description: t.t('pdf_content_fit_mode_original_description'),
              icon: Icons.photo_size_select_actual_outlined,
              isSelected: _selectedMode == PdfContentFitMode.original,
              onTap: () => _setMode(PdfContentFitMode.original),
              visualExample: _OriginalSizeExample(),
            ),
            const SizedBox(height: 12),

            // Option 2: Fit with Padding
            _FitModeCard(
              mode: PdfContentFitMode.fit,
              title: t.t('pdf_content_fit_mode_fit_title'),
              description: t.t('pdf_content_fit_mode_fit_description'),
              icon: Icons.fit_screen_outlined,
              isSelected: _selectedMode == PdfContentFitMode.fit,
              onTap: () => _setMode(PdfContentFitMode.fit),
              visualExample: _FitWithPaddingExample(),
            ),
            const SizedBox(height: 12),

            // Option 3: Crop to Fit
            _FitModeCard(
              mode: PdfContentFitMode.crop,
              title: t.t('pdf_content_fit_mode_crop_title'),
              description: t.t('pdf_content_fit_mode_crop_description'),
              icon: Icons.crop_outlined,
              isSelected: _selectedMode == PdfContentFitMode.crop,
              onTap: () => _setMode(PdfContentFitMode.crop),
              visualExample: _CropToFitExample(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FitModeCard extends StatelessWidget {
  final PdfContentFitMode mode;
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget visualExample;

  const _FitModeCard({
    required this.mode,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.visualExample,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Visual example
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: visualExample,
            ),
          ],
        ),
      ),
    );
  }
}

// Visual examples for each mode
class _OriginalSizeExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.2),
          border: Border.all(color: theme.colorScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            color: theme.colorScheme.primary,
            size: 40,
          ),
        ),
      ),
    );
  }
}

class _FitWithPaddingExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.2),
          border: Border.all(color: theme.colorScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            color: theme.colorScheme.primary,
            size: 40,
          ),
        ),
      ),
    );
  }
}

class _CropToFitExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: theme.colorScheme.primary.withOpacity(0.2),
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  color: theme.colorScheme.primary,
                  size: 50,
                ),
              ),
            ),
          ),
          // Crop indicators
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              height: 2,
              color: theme.colorScheme.error.withOpacity(0.5),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Container(
              height: 2,
              color: theme.colorScheme.error.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
