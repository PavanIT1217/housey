# Housey for Android and iOS

The Housey game as a native Flutter app, with the same features as the website:

- **The game:** a cloth bag of wooden coins, paper tickets you dab with ink, the printed caller's board, and computer players who race you to claim prizes. It's saved as you go, so closing the app doesn't lose it: the setup card offers **Resume game**.
- **The caller:** says just the number by default ("Number 22"), or the digits too, or the traditional calls. Choose the voice, speaking speed and pitch, and set the time between calls with presets or a slider, even mid-game (the ⚙ button).
- **Number caller:** calls numbers for a game on paper tickets, with undo and a ticket checker for prize claims.
- **My tickets:** open a printed ticket by scanning its QR code or typing its code, and dab it on the phone.
- **Print tickets:** as many tickets as you need, in your colours and layout or from a preset, as a PDF to print or share.

Every ticket has a code like `HNZV-C92Z`, and a code makes the same ticket here and on the website. The app runs entirely on the phone, with no internet connection or account needed.

## What's different from the web version

- The caller's voice uses the phone's text-to-speech engine. It prefers Indian English, then British English, then any English voice.
- Sounds are small WAV files made by `tool/make_sounds.py`. They use the same recipes the web version plays live with Web Audio.
- Dabbing a number, a number of yours being called and winning a prize all give a buzz.
- The screen stays on during a game.
- Calling pauses when you switch away from the app.
- Printing makes a PDF and opens the phone's print or share sheet.
- The camera is used only to read ticket QR codes, on the phone. Nothing is recorded or sent.
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

The tests cover ticket generation and ticket codes (including `../tests/fixtures/ticket-codes.json`, which the website's tests also check, so both make identical tickets from a code), the prize rules and call styles, the caller, pausing, speed changes, manual draws, claims and bogeys, auto-dab, saving and resuming, full games against computer players on a fake clock, the number caller, my tickets, print options and the PDF. Widget tests tap through the setup card, a first draw and each tool screen.

## Layout

```
lib/core/                 rules with no Flutter: ticket codes, tickets, prizes, calls, the bag, print options
                          (ported step for step from ../js/core so codes give the same tickets)
lib/services/             storage, settings, sound and voice (fx), ticket lookup, the ticket PDF
lib/game/                 controllers: the game, the number caller, my tickets
lib/ui/                   screens and widgets: the table, caller's mat, tickets, board, setup card,
                          speed and voice controls, number caller, my tickets, print tickets, QR scanner
lib/app_services.dart     what every screen shares (storage, settings, sound and voice)
assets/sounds/            sound effects (made by tool/make_sounds.py)
assets/fonts/             the web version's fonts as TTF (SIL Open Font License, see OFL.txt)
assets/icon/              adaptive launcher icon layers, made from ../icons/icon-512.png
```

To change the launcher icon, replace `../icons/icon-512.png` (and the layers in `assets/icon/`), then run `dart run flutter_launcher_icons`.

## Store listing

The website has the pages both stores ask for:

| Store field | URL |
| --- | --- |
| Privacy policy (App Store and Google Play) | https://housey.webappslab.com/privacy.html |
| Support URL (App Store) | https://housey.webappslab.com/support.html |
| Terms of use (optional) | https://housey.webappslab.com/terms.html |
| Marketing URL (App Store, optional) | https://housey.webappslab.com/ |

Answers for the privacy forms (Google Play "Data safety", App Store "App Privacy"), which match the privacy policy:

- **Data collected:** none. **Data shared:** none. No account, so no account deletion is needed.
- **Camera:** used only to read ticket QR codes on the phone; no photos or video are stored or sent.
- **Tracking / ads / analytics:** none.
- **Content rating / gambling questions:** no real money, no purchases, prizes are points only. The other players are computer-controlled.
- **Contact email:** pavan@webappslab.com
