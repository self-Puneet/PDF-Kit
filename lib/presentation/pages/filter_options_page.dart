import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/models/filter_models.dart';

class FilterOptionsPage extends StatefulWidget {
  const FilterOptionsPage({super.key});

  @override
  State<FilterOptionsPage> createState() => _FilterOptionsPageState();
}

class _FilterOptionsPageState extends State<FilterOptionsPage> {
  static const _prefName = 'name';
  static const _prefModified = 'modified';

  late SortOption _selected;

  @override
  void initState() {
    super.initState();
    _selected = _sortFromPref(Prefs.getString(Constants.filesSortOptionKey));
  }

  SortOption _sortFromPref(String? value) {
    switch (value) {
      case _prefModified:
        return SortOption.modified;
      case _prefName:
      default:
        return SortOption.name;
    }
  }

  String _sortToPref(SortOption option) {
    switch (option) {
      case SortOption.modified:
        return _prefModified;
      case SortOption.name:
      case SortOption.type:
        return _prefName;
    }
  }

  void _setSort(SortOption option) {
    setState(() => _selected = option);
    Prefs.setString(Constants.filesSortOptionKey, _sortToPref(option));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.t('settings_filter_options_title'))),
      body: SafeArea(
        child: Padding(
          padding: screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.t('settings_filter_options_subtitle'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    RadioListTile<SortOption>(
                      value: SortOption.name,
                      groupValue: _selected,
                      title: Text(t.t('filter_by_name')),
                      onChanged: (v) {
                        if (v == null) return;
                        _setSort(v);
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<SortOption>(
                      value: SortOption.modified,
                      groupValue: _selected,
                      title: Text(t.t('filter_by_modified')),
                      onChanged: (v) {
                        if (v == null) return;
                        _setSort(v);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
