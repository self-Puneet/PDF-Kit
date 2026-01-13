
# SnackBar Usage Inventory (PDF-Kit)

Last updated: 2026-01-12

This document lists every `SnackBar` usage found in the app (via `ScaffoldMessenger.showSnackBar`), including:

- **Where (screen/widget)** it appears
- **What message** it shows (literal text or localization key)
- **Why** it’s shown (purpose)
- **What triggers** it (user action or error path)

Notes:
- Many messages are localized via `AppLocalizations.of(context).t('...')` (shown below as the key/pattern).
- Some SnackBars are intentionally shown **after navigating back to Home** using `Future.delayed(...)`.
- A few SnackBar call sites are **commented out** (listed separately).
- As of 2026-01-13, **success SnackBars for the 8 main operations** are standardized to a short localized `common_done` ("Done") with a single `common_open_snackbar` ("Open") action. Protected PDFs open in the **native Android viewer**.

---

## Global / Shared Widgets

### Selection validation (applies across multiple tools)

- **Screen/Widget:** `SelectionLayout`
- **File:** [lib/presentation/layouts/selection_layout.dart](lib/presentation/layouts/selection_layout.dart)
- **Location:** [selection_layout.dart](lib/presentation/layouts/selection_layout.dart#L78-L87)
- **Trigger:** `SelectionProvider.lastValidationError != null` (e.g., user selects wrong file type / violates min/max/allowed rules)
- **Message:** `provider.lastValidationError` (dynamic)
- **Purpose:** Show a quick inline validation error (red background, 3s), then clears the error.

---

## Home Screen

### HomeTab (Get Started “toast”-style hints)

- **Screen/Widget:** Home tab (`HomeTab`)
- **File:** [lib/presentation/pages/home_page.dart](lib/presentation/pages/home_page.dart)
- **Location:** [home_page.dart](lib/presentation/pages/home_page.dart#L27)
- **Trigger:** “Get Started” buttons in `RecentFilesSection` (`onGetStartedPrimary/Secondary`)
- **Message:** `t.t(key)` where key is one of:
  - `home_get_started_scan`
  - `home_get_started_import`
- **Purpose:** Simple hint/feedback when user taps the “Get Started” actions.

### RecentFilesSection (inside Home)

- **Screen/Widget:** Home → Recent files list (`RecentFilesSection`)
- **File:** [lib/presentation/pages/home_page.dart](lib/presentation/pages/home_page.dart)

1) Delete recent entry failed
	- **Location:** [home_page.dart](lib/presentation/pages/home_page.dart#L245-L253)
	- **Trigger:** User deletes a recent file entry; `RecentFilesService.removeRecentFile` fails
	- **Message:** `Error: $error`
	- **Purpose:** Surface failure to remove from recent list.

2) Delete recent entry success
	- **Location:** [home_page.dart](lib/presentation/pages/home_page.dart#L259-L261)
	- **Trigger:** User deletes a recent file entry; removal succeeds
	- **Message:** `Removed from recent files`
	- **Purpose:** Confirm recent entry was removed.

3) Rename failed
	- **Location:** [home_page.dart](lib/presentation/pages/home_page.dart#L280-L287)
	- **Trigger:** Rename action fails
	- **Message:** `exception.message`
	- **Purpose:** Surface rename error.

4) Rename success
	- **Location:** [home_page.dart](lib/presentation/pages/home_page.dart#L294-L296)
	- **Trigger:** Rename succeeds
	- **Message:** `File renamed successfully`
	- **Purpose:** Confirm rename.

---

## Recent Files Screens

### RecentFilesPage

- **Screen/Widget:** Recent files page (separate screen)
- **File:** [lib/presentation/pages/recent_files_page.dart](lib/presentation/pages/recent_files_page.dart)

1) Remove recent entry success
	- **Location:** [recent_files_page.dart](lib/presentation/pages/recent_files_page.dart#L136-L138)
	- **Trigger:** Delete recent entry succeeds
	- **Message:** `t.t('snackbar_removed_recent')`
	- **Purpose:** Confirm recent entry removed.

2) Rename failed
	- **Location:** [recent_files_page.dart](lib/presentation/pages/recent_files_page.dart#L157-L165)
	- **Trigger:** Rename fails
	- **Message:** `exception.message`
	- **Purpose:** Surface rename failure.

3) Rename success
	- **Location:** [recent_files_page.dart](lib/presentation/pages/recent_files_page.dart#L174-L176)
	- **Trigger:** Rename succeeds
	- **Message:** `File renamed successfully`
	- **Purpose:** Confirm rename.

4) Clear All failed
	- **Location:** [recent_files_page.dart](lib/presentation/pages/recent_files_page.dart#L219)
	- **Trigger:** “Clear All” fails
	- **Message:** `t.t('snackbar_error').replaceAll('{message}', error.toString())`
	- **Purpose:** Show clear-all error.

### RecentFilesSearchPage

- **Screen/Widget:** Recent files search
- **File:** [lib/presentation/pages/recent_files_search_page.dart](lib/presentation/pages/recent_files_search_page.dart)

1) Delete failed
	- **Location:** [recent_files_search_page.dart](lib/presentation/pages/recent_files_search_page.dart#L188-L197)
	- **Trigger:** Delete recent entry fails
	- **Message:** `t.t('snackbar_error').replaceAll('{message}', error.toString())`
	- **Purpose:** Surface failure removing from recent list.

2) Delete success
	- **Location:** [recent_files_search_page.dart](lib/presentation/pages/recent_files_search_page.dart#L204-L206)
	- **Trigger:** Delete succeeds
	- **Message:** `t.t('snackbar_removed_recent')`
	- **Purpose:** Confirm removal.

3) Rename failed
	- **Location:** [recent_files_search_page.dart](lib/presentation/pages/recent_files_search_page.dart#L226-L234)
	- **Trigger:** Rename fails
	- **Message:** `exception.message`
	- **Purpose:** Surface rename error.

4) Rename success
	- **Location:** [recent_files_search_page.dart](lib/presentation/pages/recent_files_search_page.dart#L247-L248)
	- **Trigger:** Rename succeeds
	- **Message:** `File renamed successfully`
	- **Purpose:** Confirm rename.

---

## File Manager Screens

### FileSearchPage

- **Screen/Widget:** File search
- **File:** [lib/presentation/pages/file_search_page.dart](lib/presentation/pages/file_search_page.dart)

1) Rename success
	- **Location:** [file_search_page.dart](lib/presentation/pages/file_search_page.dart#L355-L357)
	- **Trigger:** Rename completed in rename sheet
	- **Message:** `Renamed successfully`
	- **Purpose:** Confirm rename.

2) Delete success
	- **Location:** [file_search_page.dart](lib/presentation/pages/file_search_page.dart#L370-L372)
	- **Trigger:** Delete completed in delete sheet
	- **Message:** `Deleted successfully`
	- **Purpose:** Confirm delete.

### FileScreenPage

- **Screen/Widget:** File screen listing
- **File:** [lib/presentation/pages/file_screen_page.dart](lib/presentation/pages/file_screen_page.dart)

1) Rename success
	- **Location:** [file_screen_page.dart](lib/presentation/pages/file_screen_page.dart#L324-L326)
	- **Trigger:** Rename completes (provider rename)
	- **Message:** `File renamed successfully`
	- **Purpose:** Confirm rename.

### FilesRootPage (recent files menu inside file manager root)

- **Screen/Widget:** Files root
- **File:** [lib/presentation/pages/files_root_page.dart](lib/presentation/pages/files_root_page.dart)

1) Remove recent entry failed
	- **Location:** [files_root_page.dart](lib/presentation/pages/files_root_page.dart#L1183-L1188)
	- **Trigger:** Menu → delete recent; remove fails
	- **Message:** `Error: $error`
	- **Purpose:** Surface failure.

2) Remove recent entry success
	- **Location:** [files_root_page.dart](lib/presentation/pages/files_root_page.dart#L1194-L1195)
	- **Trigger:** Menu → delete recent; remove succeeds
	- **Message:** `Removed from recent files`
	- **Purpose:** Confirm removal.

3) Rename failed
	- **Location:** [files_root_page.dart](lib/presentation/pages/files_root_page.dart#L1210-L1216)
	- **Trigger:** Menu → rename; rename fails
	- **Message:** `exception.message`
	- **Purpose:** Surface rename error.

4) Rename success
	- **Location:** [files_root_page.dart](lib/presentation/pages/files_root_page.dart#L1221-L1222)
	- **Trigger:** Menu → rename; rename succeeds
	- **Message:** `File renamed successfully`
	- **Purpose:** Confirm rename.

---

## PDF Viewer

### PdfViewerPage (file actions)

- **Screen/Widget:** PDF viewer
- **File:** [lib/presentation/pages/pdf_viewer_page.dart](lib/presentation/pages/pdf_viewer_page.dart)

1) Rename failed
	- **Location:** [pdf_viewer_page.dart](lib/presentation/pages/pdf_viewer_page.dart#L262)
	- **Trigger:** Rename fails
	- **Message:** `err.message`
	- **Purpose:** Surface rename failure.

2) Delete failed
	- **Location:** [pdf_viewer_page.dart](lib/presentation/pages/pdf_viewer_page.dart#L296)
	- **Trigger:** Delete fails
	- **Message:** `err.message`
	- **Purpose:** Surface delete failure.

3) Move failed
	- **Location:** [pdf_viewer_page.dart](lib/presentation/pages/pdf_viewer_page.dart#L336)
	- **Trigger:** Move to folder fails
	- **Message:** `err.message`
	- **Purpose:** Surface move failure.

4) Incorrect password / encrypted file open error
	- **Location:** [pdf_viewer_page.dart](lib/presentation/pages/pdf_viewer_page.dart#L545-L552)
	- **Trigger:** PDF open error where error string suggests password/encryption, and user already provided a password
	- **Message:** `Incorrect password or file error.`
	- **Purpose:** Inform user and then re-open password dialog.

---

## PDF Operations

### ReorderPdfPage

- **Screen/Widget:** Reorder PDF
- **File:** [lib/presentation/pages/reorder_pdf_page.dart](lib/presentation/pages/reorder_pdf_page.dart)

1) Reorder success
	- **Location:** [reorder_pdf_page.dart](lib/presentation/pages/reorder_pdf_page.dart#L272-L279)
	- **Trigger:** Reorder operation completes successfully
	- **Message:** `t.t('reorder_pdf_success')`
	- **Purpose:** Confirm success before navigating back to Home.

2) Generic error (red)
	- **Location:** [reorder_pdf_page.dart](lib/presentation/pages/reorder_pdf_page.dart#L303-L312)
	- **Trigger:** Any error path calling `_showError(message)`
	- **Message:** `message` (dynamic)
	- **Purpose:** Surface failure in a standard red SnackBar.

### MergePdfPage

- **Screen/Widget:** Merge PDF
- **File:** [lib/presentation/pages/merge_pdf.dart](lib/presentation/pages/merge_pdf.dart)

1) Merge failed
	- **Location:** [merge_pdf.dart](lib/presentation/pages/merge_pdf.dart#L284-L292)
	- **Trigger:** Merge service returns error
	- **Message:** `t.t('snackbar_error').replaceAll('{message}', error.message)`
	- **Purpose:** Surface failure.

2) Merge success (after navigation)
	- **Location:** [merge_pdf.dart](lib/presentation/pages/merge_pdf.dart#L322-L340)
	- **Trigger:** Merge succeeds → navigates Home → shows SnackBar after `Future.delayed`
	- **Message:** `t.t('snackbar_success_merge').replaceAll('{fileName}', mergedFile.name)`
	- **Purpose:** Confirm success and offer **Open** action (`common_open_snackbar`).

### CompressPdfPage

- **Screen/Widget:** Compress PDF
- **File:** [lib/presentation/pages/compress_pdf.dart](lib/presentation/pages/compress_pdf.dart)

1) No file selected
	- **Location:** [compress_pdf.dart](lib/presentation/pages/compress_pdf.dart#L100-L107)
	- **Trigger:** User tries compress with empty selection
	- **Message:** `t.t('compress_pdf_select_first_error')`
	- **Purpose:** Prompt user to select a PDF first.

2) Compress failed
	- **Location:** [compress_pdf.dart](lib/presentation/pages/compress_pdf.dart#L153-L159)
	- **Trigger:** Compress service returns error
	- **Message:** `err.message`
	- **Purpose:** Surface failure.

3) Compress success (after navigation)
	- **Location:** [compress_pdf.dart](lib/presentation/pages/compress_pdf.dart#L194-L213)
	- **Trigger:** Compress succeeds → navigates Home → shows SnackBar after `Future.delayed`
	- **Message pattern:** `t.t('compress_pdf_result_pattern')` with replacements:
	  - `{original}` = original file name
	  - `{level}` = `optimized`
	  - `{result}` = compressed file name
	- **Purpose:** Confirm result and offer **Open** action (`common_open_snackbar`).

### SplitPdfPage

- **Screen/Widget:** Split PDF
- **File:** [lib/presentation/pages/split_pdf_page.dart](lib/presentation/pages/split_pdf_page.dart)

1) Page count/load error (service failure)
	- **Location:** [split_pdf_page.dart](lib/presentation/pages/split_pdf_page.dart#L228-L235)
	- **Trigger:** `PdfSplitService.getPageCount` returns error
	- **Message:** `Error: $error`
	- **Purpose:** Surface PDF info load error.

2) Page count/load error (exception)
	- **Location:** [split_pdf_page.dart](lib/presentation/pages/split_pdf_page.dart#L253-L260)
	- **Trigger:** Exception during `_loadPdfInfoForPath`
	- **Message:** `Error: $e`
	- **Purpose:** Surface exception.

3) No valid ranges provided
	- **Location:** [split_pdf_page.dart](lib/presentation/pages/split_pdf_page.dart#L371-L376)
	- **Trigger:** User taps Split with no valid page range
	- **Message:** `Please add at least one valid page range`
	- **Purpose:** Validation feedback.

4) Range validation error
	- **Location:** [split_pdf_page.dart](lib/presentation/pages/split_pdf_page.dart#L388-L395)
	- **Trigger:** Ranges invalid vs total pages
	- **Message:** `error` (dynamic string returned by validator)
	- **Purpose:** Validation feedback (red).

5) Split success (after navigation)
	- **Location:** [split_pdf_page.dart](lib/presentation/pages/split_pdf_page.dart#L491-L499)
	- **Trigger:** Split succeeds → navigates Home → shows SnackBar after `Future.delayed`
	- **Message:** `Successfully split PDF into {n} files`
	- **Purpose:** Confirm success.

6) Split failed
	- **Location:** [split_pdf_page.dart](lib/presentation/pages/split_pdf_page.dart#L503-L509)
	- **Trigger:** Split result `success == false`
	- **Message:** `result.errorMessage ?? 'Failed to split PDF'`
	- **Purpose:** Surface failure.

### ProtectPdfPage

- **Screen/Widget:** Protect PDF
- **File:** [lib/presentation/pages/protect_pdf.dart](lib/presentation/pages/protect_pdf.dart)

1) Password missing
	- **Location:** [protect_pdf.dart](lib/presentation/pages/protect_pdf.dart#L54-L61)
	- **Trigger:** User taps Protect with empty password
	- **Message:** `t.t('protect_pdf_error_enter_password')`
	- **Purpose:** Validation feedback.

2) Protect failed
	- **Location:** [protect_pdf.dart](lib/presentation/pages/protect_pdf.dart#L126-L134)
	- **Trigger:** Protect operation fails
	- **Message:** `t.t('snackbar_error').replaceAll('{message}', failure.message)`
	- **Purpose:** Surface failure.

3) Protect success (with Open action)
	- **Location:** [protect_pdf.dart](lib/presentation/pages/protect_pdf.dart#L153-L177)
	- **Trigger:** Protect succeeds
	- **Message:** `Successfully protected {fileName}`
	- **Purpose:** Confirm success and allow opening result via SnackBar action.

### UnlockPdfPage

- **Screen/Widget:** Unlock PDF
- **File:** [lib/presentation/pages/unlock_pdf_page.dart](lib/presentation/pages/unlock_pdf_page.dart)

1) Password missing
	- **Location:** [unlock_pdf_page.dart](lib/presentation/pages/unlock_pdf_page.dart#L54-L61)
	- **Trigger:** User taps Unlock with empty password
	- **Message:** `t.t('unlock_pdf_error_enter_password')`
	- **Purpose:** Validation feedback.

2) Unlock failed
	- **Location:** [unlock_pdf_page.dart](lib/presentation/pages/unlock_pdf_page.dart#L126-L134)
	- **Trigger:** Unlock fails
	- **Message:** `t.t('snackbar_error').replaceAll('{message}', failure.message)`
	- **Purpose:** Surface failure.

3) Unlock success (with Open action)
	- **Location:** [unlock_pdf_page.dart](lib/presentation/pages/unlock_pdf_page.dart#L153-L176)
	- **Trigger:** Unlock succeeds
	- **Message:** `Successfully unlocked {fileName}`
	- **Purpose:** Confirm success and allow opening result via SnackBar action.

### PdfToImagePage

- **Screen/Widget:** PDF → Images
- **File:** [lib/presentation/pages/pdf_to_image_page.dart](lib/presentation/pages/pdf_to_image_page.dart)

1) Destination folder selected
	- **Location:** [pdf_to_image_page.dart](lib/presentation/pages/pdf_to_image_page.dart#L158-L161)
	- **Trigger:** User selects output folder
	- **Message pattern:** `t.t('pdf_to_image_destination_snackbar').replaceAll('{folderName}', folderName)`
	- **Purpose:** Confirm destination selection.

2) No file selected
	- **Location:** [pdf_to_image_page.dart](lib/presentation/pages/pdf_to_image_page.dart#L230-L235)
	- **Trigger:** Convert with empty selection
	- **Message:** `t.t('pdf_to_image_no_file_error')`
	- **Purpose:** Validation feedback.

3) Convert failed
	- **Location:** [pdf_to_image_page.dart](lib/presentation/pages/pdf_to_image_page.dart#L320-L328)
	- **Trigger:** Export service returns error
	- **Message:** `t.t('snackbar_error').replaceAll('{message}', error.message)`
	- **Purpose:** Surface failure.

4) Convert success (after navigation)
	- **Location:** [pdf_to_image_page.dart](lib/presentation/pages/pdf_to_image_page.dart#L370-L379)
	- **Trigger:** Convert succeeds → navigates Home → shows SnackBar after `Future.delayed`
	- **Message pattern:** `t.t('snackbar_success_pdf_to_image')`
	  - `{count}` = number of exported images
	  - `{folderName}` = `outputName` (note: variable name suggests folder, but code uses outputName)
	- **Purpose:** Confirm success.

### ImagesToPdfPage

- **Screen/Widget:** Images → PDF
- **File:** [lib/presentation/pages/images_to_pdf_page.dart](lib/presentation/pages/images_to_pdf_page.dart)

1) Convert failed
	- **Location:** [images_to_pdf_page.dart](lib/presentation/pages/images_to_pdf_page.dart#L224-L231)
	- **Trigger:** Convert service returns error
	- **Message:** `t.t('snackbar_error').replaceAll('{message}', error.message)`
	- **Purpose:** Surface failure.

2) Convert success (after navigation)
	- **Location:** [images_to_pdf_page.dart](lib/presentation/pages/images_to_pdf_page.dart#L261-L278)
	- **Trigger:** Convert succeeds → navigates Home → shows SnackBar after `Future.delayed`
	- **Message pattern:** `t.t('snackbar_success_images_to_pdf').replaceAll('{fileName}', convertedFile.name)`
	- **Purpose:** Confirm success and offer **Open** action.

---

## Settings / Informational Screens

### PdfContentFitSettingsPage

- **Screen/Widget:** PDF content fit settings
- **File:** [lib/presentation/pages/pdf_content_fit_settings_page.dart](lib/presentation/pages/pdf_content_fit_settings_page.dart)
- **Location:** [pdf_content_fit_settings_page.dart](lib/presentation/pages/pdf_content_fit_settings_page.dart#L39-L46)
- **Trigger:** User selects a fit mode
- **Message:** `t.t('pdf_content_fit_settings_applied_snackbar')`
- **Purpose:** Confirm setting was applied.

### LanguageSettingPage

- **Screen/Widget:** Language settings
- **File:** [lib/presentation/pages/language_setting_page.dart](lib/presentation/pages/language_setting_page.dart)
- **Location:** [language_setting_page.dart](lib/presentation/pages/language_setting_page.dart#L79-L85)
- **Trigger:** User changes language
- **Message:** `t.t('language_settings_applied_snackbar')`
- **Purpose:** Confirm language change; it also hides any existing SnackBar first.

### AboutUsPage

- **Screen/Widget:** About Us
- **File:** [lib/presentation/pages/about_us_page.dart](lib/presentation/pages/about_us_page.dart)
- **Location:** [about_us_page.dart](lib/presentation/pages/about_us_page.dart#L19)
- **Trigger:** External link launch failed
- **Message:** `Could not open the link`
- **Purpose:** Tell user the URL couldn’t be opened.

### AboutPdfKitPage

- **Screen/Widget:** About PDF Kit
- **File:** [lib/presentation/pages/about_pdf_kit_page.dart](lib/presentation/pages/about_pdf_kit_page.dart)

1) Invalid privacy policy URL
	- **Location:** [about_pdf_kit_page.dart](lib/presentation/pages/about_pdf_kit_page.dart#L65-L66)
	- **Trigger:** Privacy policy URL parsing fails (`Uri.tryParse(url)` returns null)
	- **Message:** `Invalid privacy policy URL`
	- **Purpose:** Input/config validation feedback.

2) External link launch failed
	- **Location:** [about_pdf_kit_page.dart](lib/presentation/pages/about_pdf_kit_page.dart#L75)
	- **Trigger:** `launchUrl` returns false
	- **Message:** `Could not open the link`
	- **Purpose:** Tell user the URL couldn’t be opened.

---

## Commented-out / Inactive SnackBars

These do not run (currently commented out), but are still present in code:

- [lib/presentation/pages/recent_files_page.dart](lib/presentation/pages/recent_files_page.dart#L121-L129)
  - **Intent (commented):** show `snackbar_error` on delete failure (currently the UI restores the file but does not show a SnackBar).

- [lib/models/functionality_list.dart](lib/models/functionality_list.dart#L279)
  - **Intent (commented):** show a message via SnackBar (not active).

