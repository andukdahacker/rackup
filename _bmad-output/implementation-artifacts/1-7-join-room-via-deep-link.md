# Story 1.7: Join Room via Deep Link

Status: review

## Story

As a player,
I want to tap a shared link (rackup.app/join/CODE) to join a friend's game directly,
So that I don't have to manually enter a room code.

## Acceptance Criteria

1. **Given** the player has RackUp installed and taps a deep link (`rackup.app/join/CODE`), **When** the app opens, **Then** `go_router` intercepts the deep link and routes directly to the join flow with the room code pre-filled **And** the player only needs to enter their display name and tap Join **And** the deep link to lobby flow completes within 4 seconds (NFR8)
2. **Given** the player does NOT have RackUp installed and taps a deep link, **When** the link opens in the browser, **Then** the player is redirected to the appropriate App Store (iOS App Store or Google Play) **And** the room code is preserved through the install process **And** after installation, the app opens directly into the join flow with the room code pre-filled (deferred deep link) *(Phase 1.5 — this story implements client-side platform configuration only; full deferred routing requires a server-side redirect page at rackup.app/join/:code)*
3. **Given** the deep link contains an invalid or expired room code, **When** the app attempts to join, **Then** the player sees the join screen with an inline error "Room not found" **And** they can manually enter a different code

## Tasks / Subtasks

### Platform Configuration (iOS)

- [x] Task 1: Configure iOS Universal Links (AC: #1, #2)
  - [x] 1.1 Create `ios/Runner/Runner.entitlements` with Associated Domains capability:
    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>com.apple.developer.associated-domains</key>
        <array>
            <string>applinks:rackup.app</string>
        </array>
    </dict>
    </plist>
    ```
  - [x] 1.2 Create `ios/Runner/Runner.release.entitlements` with the same content for release builds.
  - [x] 1.3 Update `ios/Runner.xcodeproj/project.pbxproj` to reference entitlements files. **Recommended approach:** Open the project in Xcode, select Runner target > Signing & Capabilities > + Capability > Associated Domains > add `applinks:rackup.app`. This auto-generates the entitlements files and updates `project.pbxproj` correctly (manual edits to `project.pbxproj` risk corrupting UUID-based structure). Alternatively, add `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` to Debug config and `CODE_SIGN_ENTITLEMENTS = Runner/Runner.release.entitlements` to Release config.
  - [x] 1.4 **Server-side requirement (deferred):** An `apple-app-site-association` (AASA) file must be hosted at `https://rackup.app/.well-known/apple-app-site-association` for universal links to work in production. For local development/testing, use `xcrun simctl openurl booted "https://rackup.app/join/ABCD"` or a custom URL scheme fallback. Document the required AASA JSON structure in a comment for future deployment.

### Platform Configuration (Android)

- [x] Task 2: Configure Android App Links (AC: #1, #2)
  - [x] 2.1 Add an `<intent-filter>` to `android/app/src/main/AndroidManifest.xml` inside the existing `<activity>` tag for deep link handling:
    ```xml
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="https" android:host="rackup.app" android:pathPrefix="/join/"/>
    </intent-filter>
    ```
  - [x] 2.2 **Server-side requirement (deferred):** A `assetlinks.json` file must be hosted at `https://rackup.app/.well-known/assetlinks.json` for verified App Links in production. Document the required JSON structure in a comment. For development, unverified deep links still work — Android will prompt the user to choose an app.

### Flutter Deep Link Routing

- [x] Task 3: Update `go_router` to handle deep links with pre-filled room code (AC: #1, #3)
  - [x] 3.1 Add a new route to `lib/core/routing/app_router.dart` for the deep link path pattern `/join/:code`. This route extracts the room code from the URL path parameter and passes it to `JoinRoomPage` as a constructor argument. The route builder follows the same `MultiBlocProvider` pattern as the existing `/join` route (provides `WebSocketCubit` and `RoomBloc`). Extract `code` via `state.pathParameters['code']`.
  - [x] 3.2 Update `JoinRoomPage` to accept an optional `initialCode` parameter (`String?`). When `initialCode` is non-null, pre-fill the 4-character code input fields and set them as read-only (the code came from a trusted deep link — user should not edit it). Auto-focus the display name field instead of the first code field.
  - [x] 3.3 The existing `/join` route (no code parameter) remains unchanged for manual code entry from the home screen.
  - [x] 3.4 Ensure `go_router`'s built-in deep link handling processes incoming platform deep links. `GoRouter` automatically handles `initialLocation` from platform deep links when the app is launched via a URL. Verify that `routerConfig: appRouter` in `app.dart` is sufficient — `go_router` >= 10.0 handles this natively. No `FlutterDeepLinkingEnabled` Info.plist key is needed when using `go_router` (it manages its own deep link stream).

### JoinRoomPage Deep Link Mode

- [x] Task 4: Modify `JoinRoomPage` for pre-filled code UX (AC: #1, #3)
  - [x] 4.1 Add `initialCode` parameter to `JoinRoomPage` constructor: `const JoinRoomPage({this.initialCode, super.key})`. Pass it down to `_JoinFormView`.
  - [x] 4.2 In `_JoinFormViewState.initState()`, when `initialCode` is non-null and exactly 4 alpha characters: pre-populate each `_codeControllers[i]` with the corresponding uppercase character, and request focus on `_nameFocusNode` (skip code entry). If `initialCode` is present but invalid (wrong length, non-alpha), ignore it and behave as normal manual entry. **IMPORTANT widget lifecycle note:** The BlocBuilder switch creates a NEW `_JoinFormView` when state transitions from `_LoadingView` (RoomJoining) back to `_JoinFormView` (RoomError), so `initState()` runs again. Only set code fields as read-only when `widget.errorMessage == null`. If `errorMessage` is non-null (error rebuild), pre-fill the code but leave fields editable (Task 4.4).
  - [x] 4.3 When `initialCode` is provided, make code fields read-only (`readOnly: true` on each `_CodeCharField`'s `TextField`) so the user sees the pre-filled code but cannot accidentally modify it. Style with slightly dimmed text (`RackUpColors.textSecondary`) to indicate non-editable state.
  - [x] 4.4 On `RoomError` state when `initialCode` was provided: unlock the code fields (make editable again) so the user can manually correct if the deep link code was invalid/expired. Reset `readOnly` to `false`.
  - [x] 4.5 The heading text should change contextually: "Join via Link" when `initialCode` is provided, "Enter Room Code" for manual entry.

### Deferred Deep Linking (App Store Redirect)

- [x] Task 5: Document deferred deep linking strategy (AC: #2)
  - [x] 5.1 Deferred deep linking (preserving room code through App Store install + first launch) is **deferred to Phase 1.5**. For MVP, only the app-already-installed path works natively. The not-installed case falls back to Safari/browser (iOS) or shows app chooser (Android) — functional but not seamless.
  - [x] 5.2 Add a code comment in `app_router.dart` documenting the deferred deep link strategy: "// TODO(Phase 1.5): Deferred deep linking — preserve room code through App Store install. Requires server-side redirect page at rackup.app/join/:code or third-party service (Branch/custom). MVP handles app-already-installed case only."

### Testing

- [x] Task 6: Tests for deep link routing and pre-filled code (all ACs)
  - [x] 6.1 **Router tests** — create `test/core/routing/app_router_test.dart`:
    - Test that `/join/ABCD` route exists and passes `initialCode: 'ABCD'` to `JoinRoomPage`
    - Test that `/join` route (no code) passes `initialCode: null`
    - Test case-insensitive code handling: `/join/abcd` should work (router passes it, page uppercases)
  - [x] 6.2 **Widget tests** — update existing `test/features/lobby/view/join_room_page_test.dart`:
    - Test that `JoinRoomPage(initialCode: 'ABCD')` pre-fills code fields with A, B, C, D
    - Test that code fields are read-only when `initialCode` is provided
    - Test that display name field has focus when `initialCode` is provided
    - Test that heading shows "Join via Link" with `initialCode`
    - Test that on error state, code fields become editable again
    - Test that invalid `initialCode` (e.g., '12', 'ABCDE') is ignored — falls back to manual entry
  - [x] 6.3 **Platform configuration verification** (manual):
    - Verify iOS entitlements file has `applinks:rackup.app`
    - Verify Android manifest has correct intent-filter with `rackup.app` host and `/join/` pathPrefix
    - Test cold-start: `xcrun simctl openurl booted "https://rackup.app/join/ABCD"` on iOS simulator (app not running)
    - Test warm-start: run app first, go to home screen, then `xcrun simctl openurl booted "https://rackup.app/join/WXYZ"` (app already running)
    - Test cold-start: `adb shell am start -a android.intent.action.VIEW -d "https://rackup.app/join/ABCD"` on Android emulator
    - Test warm-start: run app first, then send deep link via adb

## Dev Notes

### Architecture Constraints

- **go_router handles deep links natively** — do NOT use `uni_links`, `app_links`, or any third-party deep link packages. `go_router` >= 10.0 integrates with Flutter's deep link system. The `routerConfig` property on `MaterialApp.router` is sufficient.
- **Server-authoritative** — the deep link code is just a pre-fill. All validation (room exists, not full, not expired) happens server-side via `POST /rooms/:code/join`. Client never validates room code existence locally.
- **Protocol types vs domain models** — `core/protocol/` = wire format. `core/models/` = domain. Never use protocol types in Bloc states.
- **No new Bloc needed** — reuse existing `RoomBloc` with `JoinRoom` event. The deep link just pre-fills the code; the join flow is identical to Story 1.6. Deep link generation/sharing is handled by Story 1.5's Share Invite button — this story handles the **receiving side** only.
- **UX spec deviation (intentional):** UX-DR79 says deep links skip the join screen entirely and go straight to lobby. Since display name entry is required and no lobby screen exists yet (Story 2.1), deep links route to the join screen with code pre-filled and read-only. Revisit when lobby is built.
- **`setState` is acceptable for local widget state** — the anti-pattern below ("DO NOT use `setState`") applies to business logic only. Local UI state like readOnly toggle and controller pre-fill in `_JoinFormViewState` appropriately uses `setState`, consistent with the existing implementation.
- **Cold-start AND warm-start deep links:** The `appRouter` is a top-level `final GoRouter` instance attached to `MaterialApp.router`. This handles both cold-start (app launched via URL) and warm-start (app already running, user taps link) deep links via `go_router`'s internal platform channel listener.

### Existing Code to Build On (DO NOT Recreate)

- **`app_router.dart`** (`lib/core/routing/app_router.dart`) — already has `/join` route with `MultiBlocProvider` setup for `WebSocketCubit` and `RoomBloc`. Add `/join/:code` route alongside it following the same pattern.
- **`JoinRoomPage`** (`lib/features/lobby/view/join_room_page.dart`) — fully implemented join form with 4-char code input, display name input, error handling, loading state, success state. Modify to accept optional `initialCode` parameter.
- **`_JoinFormView`** — StatefulWidget with `_codeControllers`, `_codeFocusNodes`, `_nameController`, `_nameFocusNode`. Pre-fill `_codeControllers` in `initState()` when `initialCode` is provided.
- **`_CodeCharField`** — existing single-character TextField widget. Add `readOnly` support by passing through to the inner `TextField`.
- **`RoomBloc`** — `JoinRoom` event, `RoomJoining`/`RoomCreatedState`/`RoomError` states all exist.
- **`RoomApiService.joinRoom()`** — POST to `/rooms/:code/join`, returns JWT. Fully implemented.
- **`WebSocketCubit.connect()`** — establishes WebSocket connection with JWT. Fully implemented.
- **`DeviceIdentityService`** — `getHashedDeviceId()`. Fully implemented.
- **`AppConfig`** — `apiBaseUrl` and `wsBaseUrl`. Fully implemented across flavors.
- **Design system** — all typography, colors, spacing tokens in `lib/core/theme/`.

### Key Technical Decisions

- **`/join/:code` is a separate route from `/join`**: go_router matches routes by specificity. `/join/:code` captures deep links with a code in the path. `/join` (no params) handles manual navigation from the home screen. Both use `JoinRoomPage` with different `initialCode` values.
- **Pre-filled code fields are read-only**: When arriving via deep link, the 4-character code is shown but non-editable. This prevents accidental modification and makes it clear the code came from the link. On error, fields unlock for manual correction.
- **No `FlutterDeepLinkingEnabled` Info.plist key**: When using `go_router`, it manages its own deep link stream internally. Adding `FlutterDeepLinkingEnabled` would cause double-handling. Do NOT add it.
- **Deferred deep linking is MVP-scoped as best-effort**: Full deferred deep linking (preserving code through App Store install + first launch) requires either a third-party service (Branch, Firebase Dynamic Links — now deprecated) or custom server-side logic. For MVP, focus on the app-already-installed path. Document the deferred strategy for Phase 1.5.
- **Universal Links / App Links require server-side files**: `apple-app-site-association` and `assetlinks.json` must be hosted on `rackup.app`. These are deployment concerns. The Flutter and platform configuration in this story prepares the client side. Until the server files are deployed, deep links will fall back to browser (iOS) or show an app chooser (Android) — still functional, just not seamless.
- **Room code in URL is case-insensitive**: The router passes whatever is in the URL. `JoinRoomPage` uppercases the `initialCode` before pre-filling. Server room codes are A-Z only, and the existing join handler is case-insensitive.
- **URL-decoded path parameters**: `go_router` automatically URL-decodes path parameters. `/join/AB%43D` becomes `initialCode: 'ABCD'`. The 4-alpha-char validation in `initState` handles all edge cases including spaces, empty strings, and special characters.

### File Structure

```
rackup/lib/
├── core/routing/
│   └── app_router.dart           # MODIFY: Add /join/:code route for deep links
├── features/lobby/view/
│   └── join_room_page.dart       # MODIFY: Add initialCode param, pre-fill logic, read-only mode

rackup/ios/Runner/
├── Runner.entitlements            # NEW: Associated Domains for universal links
└── Runner.release.entitlements    # NEW: Same for release builds

rackup/ios/Runner.xcodeproj/
└── project.pbxproj               # MODIFY: Reference entitlements files

rackup/android/app/src/main/
└── AndroidManifest.xml           # MODIFY: Add intent-filter for deep links

rackup/test/
├── core/routing/
│   └── app_router_test.dart      # NEW: Router tests for deep link route
└── features/lobby/view/
    └── join_room_page_test.dart  # MODIFY: Add deep link pre-fill tests
```

### Project Structure Notes

- All paths align with architecture spec and established patterns from Stories 1.5 and 1.6
- No new packages needed — `go_router` (already at 17.1.0) handles deep links natively
- No new Blocs, services, or protocol types — this story extends existing UI with platform configuration

### Anti-Patterns to Avoid

- **DO NOT** use `uni_links`, `app_links`, or `firebase_dynamic_links` packages — `go_router` handles deep links natively
- **DO NOT** add `FlutterDeepLinkingEnabled` to Info.plist — it conflicts with `go_router`'s internal deep link handling
- **DO NOT** create a new Bloc or service for deep links — reuse `RoomBloc` with existing `JoinRoom` event
- **DO NOT** auto-submit the join form on deep link — user must still enter display name and tap Join (per AC #1)
- **DO NOT** hardcode `rackup.app` domain in Dart code — it belongs in platform config (entitlements, manifest) only
- **DO NOT** use `setState` for business logic — Bloc/Cubit only. Local widget display state (readOnly toggle, focus management) may use `setState` as established in existing `_JoinFormViewState`
- **DO NOT** use Material `ElevatedButton` or `OutlinedButton` — follow established custom button pattern (InkWell + DecoratedBox)
- **DO NOT** use `showDialog` for errors — display inline on the same screen
- **DO NOT** navigate away on error — keep user on join screen with editable inputs

### NFR Compliance Checklist

| NFR | Requirement | How to Verify |
|-----|-------------|---------------|
| NFR8 | Deep link to lobby < 4 seconds | Measure from link tap to join screen render with pre-filled code |
| NFR9 | TLS 1.2+ | Railway provides TLS by default; deep links use HTTPS scheme |
| NFR11 | No account/email/phone required | Deep link flow only requires display name |
| NFR23 | Clear error messages | Invalid code shows "Room not found" inline |

### Previous Story Intelligence (Story 1.6)

Key learnings from Story 1.6 implementation:
- `JoinRoomPage` is fully implemented with 4-char code input, auto-advance, auto-backspace, uppercase enforcement, display name input, inline error display, loading state, and success view.
- `_CodeCharField` uses `KeyboardListener` for backspace detection and `TextInputFormatter` for uppercase/alpha-only enforcement.
- `RoomBloc` handles `JoinRoom` event: emit `RoomJoining` → call API → emit `RoomCreatedState` or `RoomError`.
- Error mapping: `ROOM_NOT_FOUND` → "Room not found — check the code and try again", `ROOM_FULL` → "Room is full (max 8 players)".
- `go_router` routes `/join` with `MultiBlocProvider` wrapping `WebSocketCubit` and `RoomBloc`.
- All 157 Flutter tests pass. Test patterns use `mocktail`, `bloc_test`, `when().thenAnswer()`.
- `_PlaceholderScreen` was removed in Story 1.6 — all routes now have real implementations.

### Git Intelligence (Recent Commits)

```
fec259a Add join room via code with code review fixes (Story 1.6)
94b0de2 Add room creation with code review fixes (Story 1.5)
9aec649 Fix code review findings for Story 1.4
02b8e53 Fix code review findings for Story 1.3 and CI path filters
35b84ab Add device identity & app home screen (Story 1.4)
```

Patterns: single commit per story, code review fixes as follow-up commits. Story 1.6 established the complete join flow — this story adds platform deep link handling on top.

### Test Baseline

Current baseline: 157 Flutter tests pass (from Story 1.6). After this story, expect ~165+ (router tests + widget test additions). Verify no regressions.

### References

- [Source: _bmad-output/planning-artifacts/epics.md — Epic 1, Story 1.7: Join Room via Deep Link]
- [Source: _bmad-output/planning-artifacts/architecture.md — go_router deep link handling (line 243, 629), app_router.dart config, HTTP endpoints POST /rooms/:code/join]
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md — Deep link flow (lines 819-837), join screen specs, deferred deep linking, 15-second join target, error recovery patterns]
- [Source: _bmad-output/planning-artifacts/prd.md — FR3 (deep link join), NFR8 (deep link < 4s), deferred deep linking strategy]
- [Source: _bmad-output/implementation-artifacts/1-6-join-room-via-code.md — JoinRoomPage implementation, RoomBloc join flow, router configuration, test patterns]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

None — all tasks completed without errors.

### Completion Notes List

- Task 1: Created iOS Universal Links entitlements (`Runner.entitlements`, `Runner.release.entitlements`) with `applinks:rackup.app`. Updated `project.pbxproj` with file references, group entries, and `CODE_SIGN_ENTITLEMENTS` across all 9 Runner build configs (Debug/Release/Profile x production/development/staging). Documented AASA JSON structure in entitlements comment.
- Task 2: Added `<intent-filter android:autoVerify="true">` to `AndroidManifest.xml` for `https://rackup.app/join/` deep links. Documented `assetlinks.json` structure in XML comment.
- Task 3: Added `/join/:code` GoRoute to `app_router.dart` alongside existing `/join` route. Extracts `code` path parameter and passes as `initialCode` to `JoinRoomPage`. Same `MultiBlocProvider` pattern as existing `/join` route.
- Task 4: Modified `JoinRoomPage` to accept optional `initialCode` parameter. Pre-fills 4-char code fields (uppercased), sets read-only mode with dimmed text, auto-focuses name field. On error state, unlocks fields for manual correction. Heading changes to "Join via Link" when deep link code present. Invalid codes (wrong length, non-alpha) are silently ignored.
- Task 5: Documented deferred deep linking strategy as `TODO(phase-1.5)` comment in `app_router.dart`. MVP handles app-already-installed case only.
- Task 6: Added 3 router tests (`app_router_test.dart`) and 9 widget tests (added to `join_room_page_test.dart`). All 170 tests pass (13 new, 157 existing). Zero regressions.

### Change Log

- 2026-03-27: Story 1.7 implementation complete — iOS/Android deep link platform config, go_router `/join/:code` route, JoinRoomPage deep link pre-fill UX, comprehensive tests (170/170 pass)

### File List

- rackup/ios/Runner/Runner.entitlements (NEW)
- rackup/ios/Runner/Runner.release.entitlements (NEW)
- rackup/ios/Runner.xcodeproj/project.pbxproj (MODIFIED)
- rackup/android/app/src/main/AndroidManifest.xml (MODIFIED)
- rackup/lib/core/routing/app_router.dart (MODIFIED)
- rackup/lib/features/lobby/view/join_room_page.dart (MODIFIED)
- rackup/test/core/routing/app_router_test.dart (NEW)
- rackup/test/features/lobby/view/join_room_page_test.dart (MODIFIED)
