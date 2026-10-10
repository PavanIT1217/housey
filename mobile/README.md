# Housey for Android and iOS

The Housey game as a native Flutter app. It plays the same as the web version: a cloth bag of wooden coins, paper tickets you dab with ink, the printed caller's board, computer players who race you to claim prizes, and a caller who reads out the traditional calls.

It runs entirely on the phone, with no internet connection or account needed.

## What's different from the web version

- The caller's voice uses the phone's text-to-speech engine. It prefers Indian English, then British English, then any English voice.
- Sounds are small WAV files made by `tool/make_sounds.py`. They use the same recipes the web version plays live with Web Audio.
- Dabbing a number, a number of yours being called and winning a prize all give a buzz.
- The screen stays on during a game.
- Calling pauses when you switch away from the app.
- Wide screens (tablets, landscape) put the tickets and the board side by side. Phones stack them under the caller's mat.

## Run it

Requirements: [Flutter](https://docs.flutter.dev/get-started/install) 3.47 or newer, plus Android Studio (for Android) or Xcode (for iOS).

```bash
cd mobile
flutter pub get
flutter run            # on a connected phone or emulator
```

## Build

```bash
flutter build apk --release      # Android: build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle          # Android: for Google Play
flutter build ipa                # iOS: needs a Mac, Xcode and an Apple developer account
```

Release builds are signed with the debug key so they install on any phone for testing. Before publishing to Google Play, set up a release key ([Flutter's guide](https://docs.flutter.dev/deployment/android#sign-the-app)).

The `Mobile app` GitHub workflow analyses, tests and builds the APK on every push that touches `mobile/`. You can download the APK from the workflow run's artifacts.

## Checks

```bash
dart format lib test
flutter analyze
flutter test
```

The tests cover ticket generation (500 seeded tickets checked against the rules), the prize rules, the caller, pausing, manual draws, claims and bogeys, auto-dab, and full games against computer players on a fake clock. They also tap through the setup card and a first draw.

## Layout

```
lib/game/rules.dart       calls, prizes, ticket generation and prize checks
lib/game/controller.dart  the caller, computer players, dabs and claims
lib/game/settings.dart    table settings, saved between launches
lib/game/fx.dart          sounds, voice, vibration, keep-screen-on
lib/ui/                   the table: caller's mat, tickets, board, cards
assets/sounds/            sound effects (made by tool/make_sounds.py)
assets/fonts/             the web version's fonts as TTF (SIL Open Font License, see OFL.txt)
assets/icon/              adaptive launcher icon layers, made from ../icons/icon-512.png
```

To change the launcher icon, replace `../icons/icon-512.png` (and the layers in `assets/icon/`), then run `dart run flutter_launcher_icons`.
