# Practice 11 — A Real Server

## Level 1 — Wire inspection (`curl` / Postman first)

All endpoints were inspected against `https://jsonplaceholder.typicode.com` before writing Dart models or repository code.

### Observed endpoints

| Request | Status | `Content-Type` | Shape & key observations |
| --- | --- | --- | --- |
| `GET /users` | `200 OK` | `application/json; charset=utf-8` | JSON array of **10** user objects (`id` 1–10). All 10 have identical top-level keys and no `null` values in the sample dataset. |
| `GET /users/1` | `200 OK` | `application/json; charset=utf-8` | Single JSON object (509 bytes, `Leanne Graham`). Nested 1 level: `address`, `company`. Nested 2 levels: `address.geo`. |
| `GET /users/999` | `404 Not Found` | `application/json; charset=utf-8` | Body is `{}` (2 bytes — valid empty JSON object). Status **must** be checked in `_check` before `_decode`; otherwise decoding succeeds and `User.fromJson` fails on `id` with `BadResponseException` instead of `NotFoundException`. |
| `POST /users` (JSON body + `Content-Type: application/json`) | `201 Created` | `application/json; charset=utf-8` | `Location: https://jsonplaceholder.typicode.com/users/11`. Echoes back the posted JSON fields and assigns/adds `"id": 11`. |
| `GET /users?id=3` | `200 OK` | `application/json; charset=utf-8` | Returns a **JSON array with 1 object** (`[{ "id": 3, ... }]`), not a bare object. This is the shape returned when passing query parameters via `Uri.https(host, '/users', {'id': '3'})`. |

### Top-level `User` fields

| Field | JSON type | Dart type | Nullable? |
| --- | --- | --- | --- |
| `id` | number (integer) | `int` | No |
| `name` | string | `String` | No |
| `username` | string | `String` | No |
| `email` | string | `String` | No |
| `address` | object | `Address` | No |
| `phone` | string | `String` (raw kept; normalized via `phoneDigits`) | No |
| `website` | string | `String?` (modeled optional with `as String?`) | Yes |
| `company` | object | `({String name, String catchPhrase})` | No |

### Nested `address` fields

| Field | JSON type | Dart type | Nullable? |
| --- | --- | --- | --- |
| `street` | string | `String` | No |
| `suite` | string | `String` | No |
| `city` | string | `String` | No |
| `zipcode` | string | `String` | No |
| `geo` | object | `Geo` | No |

### Twice-nested `address.geo` fields

| Field | JSON type | Dart type | Nullable? |
| --- | --- | --- | --- |
| `lat` | string (e.g. `"-37.3159"`) | `double` (`double.parse(json['lat'] as String)`) | No |
| `lng` | string (e.g. `"81.1496"`) | `double` (`double.parse(json['lng'] as String)`) | No |

### Nested `company` fields

| Field | JSON type | Dart type | Nullable? |
| --- | --- | --- | --- |
| `name` | string | `String` | No |
| `catchPhrase` | string | `String` | No |
| `bs` | string | *(not stored in the `Company` record)* | N/A |

## Level 2 & Level 3 — Parsing, exceptions, and `http` boundary

- **Strict casts as claims:** Changing `"id"` in user 1 JSON from `1` to `"1"` throws:
  `type 'String' is not a subtype of type 'int' in type cast` (`TypeError`).
  In `UserRepository`, `TypeError` and `FormatException` inside `fromJson` are caught and rethrown as `BadResponseException('users/$id: $e')`.
- **Live repository smoke check (`jsonplaceholder.typicode.com`):**
  - `getAll()` returned all 10 users.
  - `getById(999)` threw `NotFoundException` (`_check` ran before `_decode`).
  - `create(draft)` returned status `201` with server-assigned `id: 11`.
  - Typo host `jsonplaceholder.typicode.co` threw `NoConnectionException` in **124 ms**.
- **HTTP import boundary (`grep -rn "package:http" lib/`):**
  ```text
  lib/core/api/api_client.dart:7:import 'package:http/http.dart' as http;
  lib/main.dart:4:import 'package:http/http.dart' as http;
  ```
  `ApiClient` owns all HTTP transport (`_send`, `_check`, `_decode`, headers, debug `log`); `main.dart` is the single composition root constructing `http.Client()`. `UserRepository`, `UsersModel`, `User`, and all UI screens never import `package:http` or touch `http.Response`.

## Level 5 — Two kinds of "no network" (measured on Pixel 7 + DevTools)

| Scenario | How it was tested on Pixel 7 (`emulator-5554`) | Measured timing | App & DevTools observation |
| --- | --- | --- | --- |
| **1. Airplane mode (no route)** | Enabled Airplane mode (`adb shell cmd connectivity airplane-mode enable`) and pulled to refresh. | **`39 ms`** (< 1 s) | Immediate `SocketException` → `NoConnectionException` → `OfflineView` (`No connection` + `Retry`). DevTools → Network recorded `GET /users` with `Status: Error`, `Duration: 39 ms`. Turning Airplane mode off and tapping **Retry** reloaded all 10 users (`200 OK`, `265 ms`) without restarting the app. |
| **2. Network with no reply (timeout)** | Disabled Wi-Fi and applied emulator network latency > 10 s (`adb emu network delay`) so packets leave without a reply before the 10-second timeout. | **`~10 s`** (app switched to `OfflineView` at the 10-second timeout; DevTools recorded `Connection established: 11590.3 ms` with no HTTP status) | Spinner stayed up for 10 seconds, then `.timeout(const Duration(seconds: 10))` threw `TimeoutException` → `NoConnectionException`, triggered `AbortableRequest` cancellation, and showed the exact same `OfflineView`. DevTools → Network (`screenshot_timeout.png`) shows `GET /users` with `Status: --` (no status). |
| **Normal network baseline** | Pull to refresh with normal connectivity. | **`462 ms`** | DevTools → Network (`screenshot_200.png`) shows `GET /users`, `Status: 200`, `Type: json`, and the expanded 10-user JSON array in the `Response` tab. |

## Static analysis and async hygiene

- `analysis_options.yaml` keeps `unawaited_futures: true` enabled from Practice 10; deliberate fire-and-forget calls (`model.load()` in `main.dart`, `Navigator.push`, keyboard submit) are wrapped in `unawaited(...)`.
- `NewUserScreen` disables `Save` while `_saving` is `true` so rapid double-taps send only one `POST /users` request (`201 Created`, new user inserted at index 0 with server-assigned `id: 11`).
