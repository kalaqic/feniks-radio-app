# Feniks Radio

Flutter app for the Feniks Radio live stream, with accounts, points, achievements and a leaderboard. Includes a web admin panel.

## App

- **Live radio** with now-playing info, volume and auto-play
- **Accounts**: username and password, change password, delete account
- **Feniks points**: 2 points per minute of real listening plus achievement points
- **35 achievements** for listening time, streaks, sessions, time of day, favorites and exploring the app
- **Leaderboard**: all-time top 3 and your own rank
- **Favorites**, dark mode, and 20 rotating daily reminders (one per day, at a time you choose)
- **Feedback** by email from Settings

## Admin panel

A web page for accounts listed in the Firestore `admins` collection (document ID = the user's UID). It shows:

- how many people are listening and how many are active in the app right now
- daily, weekly and monthly listeners, retention and new users
- listening minutes per day
- the most-earned achievements and the most-favorited songs
- the user list with each user's achievements

```bash
https://feniks-9cda4.web.app/
```

## Setup

Requires Flutter (SDK ^3.8.1) and the Firebase project `feniks-9cda4` with Email/Password auth and Firestore. Config files: `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`.

```bash
flutter pub get
flutter run
```

Firestore rules live in `firestore.rules` and are deployed with:

```bash
firebase deploy --only firestore:rules --project feniks-9cda4
```

## Checks

```bash
flutter analyze
flutter test
```

## Release

```bash
flutter build apk      # Android
flutter build ios      # iOS (macOS + Xcode)
```

## Structure

```
lib/
  admin/      admin panel (web)
  config/     stream URLs, routes
  models/     achievements, listening progress, player state
  pages/      app screens
  services/   auth, Firestore, sync, presence, notifications, settings
  theme/      colors and theme
  utils/      transitions, formatting, logging
  widgets/    shared UI
test/         unit tests
```
