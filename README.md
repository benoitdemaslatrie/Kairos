# Kairos

A minimal daily activity manager built with Flutter. Log activities by voice dictation or manual input, and review everything you accomplished today at a glance.

## Features

- **Voice dictation** — capture activities hands-free using speech-to-text
- **Daily summary** — see today's activity count at a glance
- **Local storage** — all data stored on-device with Hive (no account required)
- **Clean UI** — glassmorphism design with a light gradient theme

## Tech stack

- Flutter 3 / Dart
- [Hive](https://pub.dev/packages/hive) — local NoSQL database
- [speech_to_text](https://pub.dev/packages/speech_to_text) — voice input
- [google_fonts](https://pub.dev/packages/google_fonts) — typography
- [permission_handler](https://pub.dev/packages/permission_handler) — microphone permissions

## Getting started

```bash
flutter pub get
dart run build_runner build   # regenerate Hive adapters if needed
flutter run
```

Requires Flutter SDK `>=3.0.0`.
