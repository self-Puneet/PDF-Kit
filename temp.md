<!-- # Device registration / FCM token sync API

This backend exposes a single endpoint that upserts a device record into **Firestore**.

- **Project URL prefix:** `/api/`
- **Endpoint:** `POST /api/add_device`
- **Django view:** `PDFSeva.views.add_device`
- **Firestore collection:** `devices`

## What it does

On every call, the backend validates the request body, then writes to Firestore:

1. If a document exists with the same `device_id` → it **updates** that document.
2. Else, if a document exists with the same `fcm_token` → it **updates** that document.
3. Else → it **creates** a new document.

In all cases it stores the submitted fields and also adds:

- `timestamp`: Firestore server timestamp (`firestore.SERVER_TIMESTAMP`)

## Request

### Method + URL

`POST {BASE_URL}/api/add_device`

Examples:

- Local dev: `http://127.0.0.1:8000/api/add_device`
- Prod (example): `https://<your-domain>/api/add_device`

### Headers

- `Content-Type: application/json`

No authentication headers are required by the current code.

### JSON body (required)

All fields below are **required** (the serializer does not mark any as optional):

| Field | Type | Notes |
|---|---:|---|
| `device_id` | string | Unique device identifier from your app (max 255 chars) |
| `fcm_token` | string | Firebase Cloud Messaging token (max 512 chars) |
| `app_version` | string | Human-readable version name (max 50 chars) |
| `version_code` | number (int) | Numeric build code |
| `locale` | string | e.g. `en`, `en-IN` (max 10 chars) |
| `brand` | string | e.g. `Samsung` |
| `manufacturer` | string | e.g. `samsung` |
| `model` | string | e.g. `SM-S911B` |
| `android_version` | string | e.g. `14` (max 10 chars) |
| `sdk_version` | string | e.g. `34` |
| `os` | string | Must be one of: `Android` or `iOS` |

### Example body

```json
{
  "device_id": "6b0c7bb2-88c6-4b25-9ee7-3fb2d7b829a8",
  "fcm_token": "fcm_token_here",
  "app_version": "1.3.2",
  "version_code": 132,
  "locale": "en-IN",
  "brand": "Samsung",
  "manufacturer": "samsung",
  "model": "SM-S911B",
  "android_version": "14",
  "sdk_version": "34",
  "os": "Android"
}
```

## Responses

### 201 Created (new document)

```json
{ "message": "Device created successfully" }
```

### 200 OK (updated by device_id)

```json
{ "message": "Device updated by device_id" }
```

### 200 OK (updated by fcm_token)

```json
{ "message": "Device updated by fcm_token" }
```

### 400 Bad Request (validation failed)

```json
{
  "error": "Validation failed",
  "details": {
    "device_id": ["This field is required."],
    "version_code": ["A valid integer is required."],
    "os": ["\"Windows\" is not a valid choice."]
  }
}
```

## Frontend examples

### `fetch`

```js
const baseUrl = "https://<your-domain>"; // or http://127.0.0.1:8000

async function upsertDevice(payload) {
  const res = await fetch(`${baseUrl}/api/add_device`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(`add_device failed: ${res.status} ${JSON.stringify(data)}`);
  }
  return data;
}
```

### `axios`

```js
import axios from "axios";

const api = axios.create({
  baseURL: "https://<your-domain>",
  headers: { "Content-Type": "application/json" }
});

export async function upsertDevice(payload) {
  const { data } = await api.post("/api/add_device", payload);
  return data;
}
```

## Notes / gotchas

- `os` must be exactly `Android` or `iOS` (case-sensitive).
- The backend uses Firestore server time; don’t send your own `timestamp` (it will be overwritten by backend data anyway).
- If Firestore credentials are missing/misconfigured (`firebase/secret_key.json`), this endpoint will fail with a server error. -->




action_images_to_pdf_label,
action_reorder_label,
action_pdf_to_image_label,
not included in other langauges other than en


file_quick_access_tile, files_storage_title, files_internal_storage, files_search_type_prompt, files_pdfs_folder, files_downloads_folder, files_images_folder not created in any language for the file root page, file search page


settings_default_camera_location_title, settings_default_camera_location-subtitle

settings_default_screenshot_location_title, settings_default_camera_location-subtitle

settings_default_camera_location_title, settings_default_camera_location-subtitle fields not in the any language file for the setting page.


folder_picker_description_pdfs, 

settings_default_camera_location_subtitle,
