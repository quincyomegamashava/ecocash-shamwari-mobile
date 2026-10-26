# Shamwari Mobile

Shamwari is the EcoCash internal AI hackathon wallet: a friend inside a synthetic book. This Flutter app is the Android and iOS client. Money is integer cents. A payment stays pending until the person says a yes word and enters the PIN on the confirm pad. The PIN is sent only to the confirm endpoints.

The Flask server is not in this repo. The app talks to it at `/api/v1`, or it can run entirely offline.

Demo desks:

| Desk | Username | Password | Opens |
| --- | --- | --- | --- |
| Customer | `rudo` | `rudo-demo` | Wallet, voice pay, coach, scam check, receipts |
| Care team | `care` | `care-demo` | Customer pulse, onboarding buddy, ledger, AI log |

The demo PIN is `2580`. Yes words are `yes`, `hongu`, `yebo`, `ewe`, and `ehe`.

## Prerequisites (Windows, Git Bash, Android Studio)

1. Install [Flutter](https://docs.flutter.dev/get-started/install/windows) (stable) and make sure `flutter` is on your PATH in Git Bash.
2. Install Android Studio. In SDK Manager, install an Android SDK platform (API 35 or newer) and the Android SDK command-line tools.
3. Accept licenses and check the toolchain:

```bash
flutter doctor
flutter doctor --android-licenses
```

4. Create an emulator (Pixel-class, API 35) from Android Studio’s Device Manager, or plug in a phone with USB debugging.

iOS builds need a Mac with Xcode. The `ios/` project is included (usage strings and a local-dev ATS exception), but this Windows machine cannot compile it.

## Get the packages

From the repo root, in Git Bash:

```bash
flutter pub get
```

## Point the app at the Flask server

The login screen has a **Server** panel.

- **Android emulator** sets `http://10.0.2.2:8642` (the emulator’s alias for the computer’s localhost). This is the default.
- **iOS simulator** sets `http://127.0.0.1:8642`.
- **LAN IP for a real phone** is the computer’s address on the same Wi-Fi, for example `192.168.1.20`. The app stores `http://<that-ip>:8642`.

Start the Flask server so the emulator and a phone can both reach it. Bind every interface, not only localhost, on port **8642**:

```bash
python app.py --host 0.0.0.0 --port 8642
```

Use whatever command this hackathon’s backend actually uses, as long as it listens on `0.0.0.0:8642`. Then tap **Test connection** on the login screen.

Cleartext HTTP is allowed for this local prototype (Android network security config, and iOS `NSAllowsLocalNetworking`). Do not ship that to production.

**Offline mock** is the switch in the same Server panel. It answers from an in-memory book that follows the API contract, so the app can be demoed with no server. Leave it off when a real server is running.

The bearer token from `POST /api/v1/auth/login` is stored in `flutter_secure_storage`.

## Run on the emulator

Start the emulator from Android Studio, then:

```bash
flutter devices
flutter run
```

The default look is a sage glass theme: a grey-green field, frosted cards, and a forest-teal navigation pill. The moon icon on the login screen switches to a darker sage and remembers the choice. The accessibility icon, and the Accessibility screen after sign-in, turn on high-contrast black and yellow with larger type. EcoCash orange stays a small accent.

## Debug APK

```bash
flutter build apk --debug
```

The file is written to:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

That universal APK contains every CPU and is large. For a smaller file:

```bash
flutter build apk --debug --split-per-abi
```

`app-arm64-v8a-debug.apk` is the one for a phone. `app-x86_64-debug.apk` is the one for the usual Windows emulator.

Install it on a device with USB debugging:

```bash
flutter install
```

or copy the APK across and open it on the phone. A debug APK is signed with the debug key. It is for the hackathon demo, not for a store.

## Tests

```bash
flutter analyze
flutter test
```

`flutter test` covers the envelope, the Dio client (the PIN is only on confirm routes), the offline book, login, role walls, and the PIN pad. Screenshot goldens under `test/goldens/` are refreshed with:

```bash
flutter test test/screenshots_test.dart --update-goldens
```

## What the screens do

Customer: home (balance, week chart with the peak in orange, activity, coach insight), send money with a PIN pad, voice pay in Shona, Ndebele, and English (typed line or a microphone file posted to `voice/interpret`), coach chat, scam checker with the sample messages, receipt reader (camera, gallery, and sample slips), accessibility.

Care: live pulse charts from the JSON series, onboarding buddy and quiz, ledger, AI log.

**Walk Rudo's morning** on the login screen signs in as Rudo and starts the `/demo` script. Next, back, and stop sit on the demo bar. Steps 6 and 7 belong to the care token. The demo bar can continue as care, which signs into `care` / `care-demo` and moves that token’s script to the care step.

Search is the magnifying glass. Results come from `GET /api/v1/search`.

A small **Prototype · synthetic data** chip stays on the shell.

## Contract notes

These are gaps between the mobile contract and the web screens, handled explicitly:

- There is no top-up or request-money create endpoint. Send, pay, and airtime call `POST /api/v1/transfers`. Top-up and Request say they are booth actions.
- Demo progress is stored on the bearer token. The care steps need the care login.
- The offline mock cannot hear audio. An upload with no transcript returns `400 transcript_empty`. Type a phrase, or tap one of the fixed lines. A denied microphone permission is explained on the voice screen and does not crash.
- The customer payload has no scam-count field. Home shows spend, the savings mark, airtime share, and coach tips from the book.
- Accessibility `GET`/`PUT` is customer-only. Care staff high contrast is kept on the phone.
- A pay QR names a merchant and an amount. It does not send money.
- Care ledger rows leave `outgoing` null, as the contract does.
