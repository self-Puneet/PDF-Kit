import 'package:flutter/material.dart';
import 'package:pdf_kit/core/localization/app_localizations.dart';

Future<void> showRenameFileSheet({
  required BuildContext context,
  required String initialName,          // current file/folder name
  required ValueChanged<String>? onRename,
}) {
  final controller = TextEditingController(text: initialName);

  debugPrint('[RenameFileSheet] Opening sheet; initialName="$initialName"');

  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final viewInsets = MediaQuery.of(ctx).viewInsets;
          final theme = Theme.of(ctx);

          void submitRename() {
            final newName = controller.text.trim();
            debugPrint(
              '[RenameFileSheet] Rename tapped; raw="${controller.text}"; trimmed="$newName"',
            );
            if (newName.isEmpty || newName == initialName.trim()) {
              debugPrint('[RenameFileSheet] Name empty/unchanged; ignoring');
              return;
            }
            Navigator.of(ctx).maybePop();
            try {
              debugPrint(
                '[RenameFileSheet] Invoking onRename callback with "$newName"',
              );
              onRename?.call(newName);
            } catch (e) {
              debugPrint('[RenameFileSheet] onRename threw: $e');
            }
          }

          return SafeArea(
            top: false,
            left: false,
            right: false,
            bottom: true,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + viewInsets.bottom),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  color: theme.dialogBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 10,
                      bottom: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 4,
                          margin: const EdgeInsets.only(top: 0, bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)
                              .t('rename_sheet_title'), // e.g. "Rename"
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor.withAlpha(64),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppLocalizations.of(context)
                                .t('rename_field_label'), // e.g. "New name"
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controller,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: AppLocalizations.of(context)
                                .t('rename_field_hint'), // e.g. "Enter new name"
                            border: const UnderlineInputBorder(),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFF3D5AFE),
                                width: 2,
                              ),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => submitRename(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () =>
                                    Navigator.of(ctx).maybePop(),
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFE9EDFF),
                                  foregroundColor: const Color(0xFF3D5AFE),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)
                                      .t('common_cancel'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    controller.text.trim().isEmpty ||
                                            controller.text.trim() ==
                                                initialName.trim()
                                        ? null
                                        : submitRename,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3D5AFE),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)
                                      .t('rename_button'), // e.g. "Rename"
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() => debugPrint('[RenameFileSheet] Closed'));
}
