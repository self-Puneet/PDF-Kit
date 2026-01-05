import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final faqs = _faqItems(t);

    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = normalizedQuery.isEmpty
        ? faqs
        : faqs
              .where(
                (f) =>
                    f.question.toLowerCase().contains(normalizedQuery) ||
                    f.answer.toLowerCase().contains(normalizedQuery),
              )
              .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(t.t('settings_help_center_title'))),
      body: SafeArea(
        child: Padding(
          padding: screenPadding,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsetsGeometry.symmetric(vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.trim().isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No FAQs found. Try a different search.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      )
                    : ListView.separated(
                        // padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return Card(
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.1),
                              ),
                            ),
                            child: ExpansionTile(
                              title: Text(
                                item.question,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                16,
                              ),
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    item.answer,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_FaqItem> _faqItems(AppLocalizations t) {
    return const [
      _FaqItem(
        question: 'What can I do with PDF Kit?',
        answer:
            'PDF Kit helps you manage PDFs and files on your device. You can merge, split, compress, reorder pages, convert images to PDF, convert PDF to images, and add/remove password protection.',
      ),
      _FaqItem(
        question: 'Where are my generated PDFs saved?',
        answer:
            'The output is saved to the destination folder selected during the flow. You can also set a default save folder from Settings → Default save location.',
      ),
      _FaqItem(
        question: 'How do I change the default save location?',
        answer:
            'Open Settings → Default save location, pick a folder, and confirm. New outputs will be saved there unless you choose a different folder during an action.',
      ),
      _FaqItem(
        question: 'How do I merge multiple PDFs into one?',
        answer:
            'Tap Merge on the home tools grid, select at least 2 PDFs, then continue to merge. You can reorder files before merging if the merge screen provides the option.',
      ),
      _FaqItem(
        question: 'How do I convert images to a single PDF?',
        answer:
            'Tap Images to PDF, select 2+ images, then continue. Arrange images if prompted, and save the generated PDF.',
      ),
      _FaqItem(
        question: 'How do I split a PDF into pages/files?',
        answer:
            'Tap Split, select a single PDF, then choose the page range or split options on the Split screen and save the result.',
      ),
      _FaqItem(
        question: 'How do I reorder pages in a PDF?',
        answer:
            'Tap Reorder, select a single PDF, then drag pages to rearrange them. Save to export the new PDF with the updated order.',
      ),
      _FaqItem(
        question: 'How does PDF compression work?',
        answer:
            'Tap Compress, select a PDF, then choose a compression level (if available). Higher compression usually reduces file size but may reduce quality.',
      ),
      _FaqItem(
        question: 'How do I add a password to a PDF?',
        answer:
            'Tap Protect, pick a PDF (must be unprotected), enter the password, and save. Keep the password safe—without it the file can\'t be opened.',
      ),
      _FaqItem(
        question: 'How do I remove a password from a PDF?',
        answer:
            'Tap Unlock/Remove Password, choose a protected PDF, enter the correct password when asked, then save the unlocked copy.',
      ),
      _FaqItem(
        question: 'Which files are supported?',
        answer:
            'The app focuses on PDFs and common image formats. The viewer supports PDFs and images (including GIF previews). If a file can’t be opened, check that the extension matches a supported type.',
      ),
      _FaqItem(
        question: 'I can’t see my files or folders. What should I do?',
        answer:
            'This is usually a permission issue. On Android, allow storage/files access when prompted (or from system Settings → Apps → PDF Kit → Permissions). On Android 11+, “All files access” may be required for broad browsing.',
      ),
      _FaqItem(
        question: 'How do I find a file quickly?',
        answer:
            'Use the search feature in the file explorer screens (Files/Search). You can also open Recent Files from the home screen to quickly re-open recent documents.',
      ),
      _FaqItem(
        question: 'Why did my action fail or produce an empty output?',
        answer:
            'Common causes are selecting the wrong file type (e.g., protected PDF for actions that require unprotected), selecting too few files, or missing storage permissions. Re-try the action and ensure the selection rules shown on the picker are satisfied.',
      ),
    ];
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}
