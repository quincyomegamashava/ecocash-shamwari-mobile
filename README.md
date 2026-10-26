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

The login screen keeps server settings behind the gear icon. The default base URL is the live v9 book, with no trailing slash:

`https://shamwari.3xm7hvreng89r.eu-west-2.cs.amazonlightsail.com`

That host reseeds the synthetic book on every restart. The app talks to it over HTTPS at `/api/v1`.

The same panel can override the host:

- **Production** puts the Lightsail URL back.
- **Android emulator** sets `http://10.0.2.2:8642` (the emulator’s alias for the computer’s localhost).
- **iOS simulator** sets `http://127.0.0.1:8642`.
- **LAN IP for a real phone** is the computer’s address on the same Wi-Fi, for example `192.168.1.20`. The app stores `http://<that-ip>:8642`.

A pasted URL is trimmed, `http://` is added only when the scheme is missing, and a trailing slash is removed, so `https://host/` and `https://host` are the same server.

To run the Flask server yourself, bind every interface on port **8642**:

```bash
python app.py --host 0.0.0.0 --port 8642
```

Then pick the emulator, simulator, or LAN chip and tap **Test connection**.

Cleartext HTTP is allowed for a local prototype (Android network security config, and iOS `NSAllowsLocalNetworking`). The production host is HTTPS.

**Offline mock** is the switch in that gear sheet. It answers from an in-memory book that follows the API contract, so the app can be demoed with no server. Leave it off when you want the live book.

The bearer token from `POST /api/v1/auth/login` is stored in `flutter_secure_storage`.

## Run on the emulator

Start the emulator from Android Studio, then:

```bash
flutter devices
flutter run
```

The default look is a sky-blue field with deep navy glass cards and a floating navy navigation pill. Sign-in is only the mark, a tagline, and the form. Server settings, including the production host and the Offline mock switch, sit behind the gear. Dark mode and high-contrast black and yellow live on the Account screen.

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

`flutter test` covers the envelope, the Dio client (the PIN is only on confirm routes), the offline book, login, role walls, the PIN pad, and the v9 flows: sample clips, the prize-desk warning, chat, USSD, impact, copilot, and the audit log. GitHub Actions runs `flutter analyze` and `flutter test` on push and pull request to `main` (`.github/workflows/ci.yml`). Screenshot goldens under `test/goldens/` are refreshed with:

```bash
flutter test test/screenshots_test.dart --update-goldens
```

## What the screens do

Customer: home (balance, week chart, activity, coach insight), send money with a PIN pad, voice pay in Shona, Ndebele, and English (typed line, a microphone file posted as multipart `audio` to `voice/interpret`, or the sample clips `tumira-5-tendai` and `thumela-5-tendai`), scam warning before confirm, chat channel, USSD `*151#`, coach chat, scam checker, receipt reader, accessibility.

Care: live pulse with an impact card (`GET /api/v1/impact`: minutes saved, tickets deflected, scams blocked, AI transfers, each with the Simulated label the API returns), copilot on a pulse case (draft, edit, approve and send, or discard), audit log, onboarding buddy and quiz, ledger, AI log.

**Walk Rudo's morning** on the login screen signs in as Rudo and starts the `/demo` script. Next, back, and stop sit on the demo bar. Steps 6 and 7 belong to the care token. The demo bar can continue as care, which signs into `care` / `care-demo` and moves that token’s script to the care step.

### Demo script for the v9 screens

Offline mock can run this with no server. With mock off, the same taps hit the live API.

1. Sign in as `rudo` / `rudo-demo`. Open **Voice pay**. Tap **Shona · tumira $5 kuna Tendai** (or the Ndebele clip). Prepare pending, say `hongu`, enter PIN `2580`.
2. Still on Voice pay, tap **Load the prize-desk scam warning**. Read the reasons. Tap **I understand the warning — continue**, then yes and `2580`. Cancelling instead logs a blocked scam.
3. Open **Chat channel** from the menu. Send `tumira $5 kuna Tendai`, then `hongu`, then `2580`. The reply never prints the PIN.
4. Open **USSD *151#**. Reply `1` for the balance, `2` then an amount and a name to send, `0` to leave.
5. Sign out. Sign in as `care` / `care-demo`. The pulse home shows **Impact this week** with Simulated labels.
6. Open a live note (Open copilot). Edit the reply if you want, then **Approve & send**, **Edit**, or **Discard**.
7. Open **Audit log**. The decision is the newest row.

The server URL stays in the login Server panel. The default is the Lightsail HTTPS host above. Offline mock stays a switch in that panel.

Search is the magnifying glass. Results come from `GET /api/v1/search`.

A small **Prototype · synthetic data** chip stays on the shell.

## Contract notes

These are gaps between the mobile contract and the web screens, handled explicitly:

- There is no top-up or request-money create endpoint. Send, pay, and airtime call `POST /api/v1/transfers`. Top-up and Request say they are booth actions.
- Demo progress is stored on the bearer token. The care steps need the care login.
- The offline mock cannot hear arbitrary audio. An upload that is not one of the two demo clips returns `400 transcript_empty`. Type a phrase, or tap **Shona sample** / **Ndebele sample**. A denied microphone permission is explained on the voice screen and does not crash.
- A high-risk row stays pending until confirm includes `risk_ack` together with the yes word and the PIN. `risk_ack_required` means nothing was posted.
- Chat and USSD are generic text channels. They are not a WhatsApp client. The public name on the server is “Chat channel (WhatsApp-style mock)”; the phone UI does not use that brand.
- The customer payload has no scam-count field. Home shows spend, the savings mark, airtime share, and coach tips from the book.
- Accessibility `GET`/`PUT` is customer-only. Care staff high contrast is kept on the phone.
- A pay QR names a merchant and an amount. It does not send money.
- Care ledger rows leave `outgoing` null, as the contract does.
