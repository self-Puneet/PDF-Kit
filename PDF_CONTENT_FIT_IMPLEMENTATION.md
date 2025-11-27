# Translation Keys Required for PDF Content Fit Settings

Add these keys to all language ARB files (ar.arb, bn.arb, de.arb, en.arb, es.arb, fr.arb, hi.arb, ja.arb, pt.arb, zh.arb):

```json
{
  "pdf_content_fit_settings_page_title": "PDF Content Fit",
  "pdf_content_fit_settings_description": "This setting controls how images are placed in PDF pages when creating or merging PDFs. It only affects images, not existing PDF files.",
  "pdf_content_fit_settings_choose_mode_label": "Choose Fit Mode",
  "pdf_content_fit_settings_applied_snackbar": "Content fit mode updated successfully",
  
  "pdf_content_fit_mode_original_title": "Original Size",
  "pdf_content_fit_mode_original_description": "Images keep their original dimensions",
  
  "pdf_content_fit_mode_fit_title": "Fit with Padding",
  "pdf_content_fit_mode_fit_description": "Images are scaled to fit the page with padding if needed",
  
  "pdf_content_fit_mode_crop_title": "Crop to Fit",
  "pdf_content_fit_mode_crop_description": "Images are scaled to fill the entire page, cropping if necessary"
}
```

## Feature Implementation Summary

### 1. **Constants Added** (`lib/core/constants.dart`)
- `pdfContentFitModeKey`: Storage key for user preference
- `fitModeOriginal`: Keep original image size
- `fitModeFit`: Fit with padding (maintain aspect ratio)
- `fitModeCrop`: Crop to fit (fill page)
- `defaultPdfContentFitMode`: Default mode (original)

### 2. **New Page** (`lib/presentation/pages/pdf_content_fit_settings_page.dart`)
- Visual cards showing 3 fit modes
- Each card has:
  - Icon representing the mode
  - Title and description
  - Visual example diagram
  - Selection indicator
- Saves preference to SharedPreferences via Prefs utility
- Shows confirmation snackbar on change

### 3. **Router Integration** (`lib/core/routing/app_router.dart`)
- Added route: `/settings/pdf-content-fit`
- Route name: `pdf-content-fit-settings`
- Linked from settings page

### 4. **Settings Page Updated** (`lib/presentation/pages/setting_page.dart`)
- "PDF Content Fit" tile now navigates to new settings page

### 5. **Merge Service Updated** (`lib/service/pdf_merge_service.dart`)
- Reads fit mode from SharedPreferences
- Separates PDFs and images
- **PDFs**: Merged as-is (no fit mode applied)
- **Images**: Converted with selected fit mode configuration
- **Mixed content**: Images converted first, then merged with PDFs

#### Fit Mode Configurations:
- **Original**: `ImageScale.original`, `keepAspectRatio: true`
- **Fit**: A4 size (595x842 points), `keepAspectRatio: true`
- **Crop**: A4 size (595x842 points), `keepAspectRatio: false`

### 6. **Export Added** (`lib/presentation/pages/page_export.dart`)
- Exported `pdf_content_fit_settings_page.dart`

## How It Works

1. User opens Settings → "PDF Content Fit"
2. Selects one of 3 modes with visual preview
3. Preference saved to SharedPreferences
4. When merging files:
   - Service reads the saved preference
   - Applies fit mode ONLY to images
   - PDFs maintain their original layout
   - Final merged PDF respects the user's choice for image content

## Testing Checklist

- [ ] Navigate to Settings → PDF Content Fit
- [ ] Select each mode and verify snackbar appears
- [ ] Merge images only → verify fit mode is applied
- [ ] Merge PDFs only → verify PDFs unchanged
- [ ] Merge mixed content → verify images use fit mode, PDFs unchanged
- [ ] Check logs for fit mode configuration messages
