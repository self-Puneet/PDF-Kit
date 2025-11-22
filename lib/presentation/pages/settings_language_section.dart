import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf_kit/providers/locale_provider.dart';
import 'package:pdf_kit/core/localization/app_localizations.dart';

class LanguageSettingsSection extends StatelessWidget {
  const LanguageSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocaleProvider>();
    final current = provider.locale?.languageCode ?? 'en';
    final t = AppLocalizations.of(context).t;

    const languages = <String, String>{'en': 'English', 'hi': 'हिन्दी'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('settings_title'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Language',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              items: languages.entries
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (code) {
                if (code != null) provider.setLocale(code);
              },
            ),
          ),
        ),
      ],
    );
  }
}
