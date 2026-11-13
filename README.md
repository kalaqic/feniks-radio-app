# Feniks Radio

Flutter app for the Feniks Radio live stream, with accounts, points, achievements and a leaderboard. Includes a web admin panel.

## Design

Colors, font and style come from [radiofeniks.com](https://radiofeniks.com): Lexend, raspberry, coral and blue, flat blocks and no shadows. The app shows only what each screen needs, and puts details one tap away. It uses small animations and haptic feedback throughout.

- **Landing screen** on every launch: a play button that wiggles and changes color (brush wipe), then flies into the home header when tapped
- **Logged-out state everywhere**: sign-in prompts in place of badges, favorites and the leaderboard; badges unlock only for logged-in users
- **Brand stripe** (three colors) on screens without the bottom navigation
- **Drawers** (leaderboard details, newsletter email) open with a staggered fold-down animation (`RevealDrawer`)
- **Haptics** follow one rule: the bigger the consequence of a tap, the stronger the feel (`lib/utils/haptics.dart`)

## App

- **Live radio**
  - Now-playing title, with a sound wave in the header while it plays. Volume is left to the phone's buttons.
  - The song updates instantly from the stream while playing, and every 3 s from the Icecast status page when stopped.
  - Upload labels such as "(Official Video)" or "HD" are removed from titles.
  - Studio announcements with the phone number are shown with "Feniks Radio" as the artist and cannot be saved.
- **Ranije na Feniksu**: the last 4 songs that played while the app was open, each with a heart to save it
- **Favorites**, newest first. The heart flies onto the "Moj profil" tab, which then shows a dot until the favorites are opened.
- **Accounts**: username and password, change password, delete account (under Settings → Nalog)
- **Feniks points**: 2 points per minute of real listening, plus achievement points
- **35 achievements** for listening time, streaks, sessions, time of day, favorites and exploring the app
- **Streak popup**: at most once a day, and only when yesterday was a listening day. A day counts after 5 minutes of listening.
- **Leaderboard**: your points and rank, with details on tap; all-time top 3
- **Profile**: points, rank and listening stats; badges and favorites one tap away
- **Settings**: dark mode, 20 rotating daily reminders at a time you choose, auto-play and feedback by email

## Admin panel

A web page for accounts listed in the Firestore `admins` collection (document ID = the user's UID). It uses the same design as the app. It shows:

- how many people are listening and how many are active in the app right now (live, in the header)
- daily, weekly and monthly listeners, retention and new users
- listeners and listening minutes per day for the last 14 days
- the most-earned achievements and the most-favorited songs
- the user list (search and sort); each user's details in a popup, with the 5 newest favorites and a button to show all

```bash
flutter run -d chrome -t lib/admin/admin_main.dart          # run locally
flutter build web -t lib/admin/admin_main.dart              # build
firebase deploy --only hosting --project feniks-9cda4       # publish
```

## Setup

Requires Flutter (SDK ^3.8.1) and the Firebase project `feniks-9cda4` with Email/Password auth and Firestore. Config files: `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`. iOS needs deployment target 15.0 or higher.

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
  assets/     logos and the Lexend font
  config/     stream URLs, routes
  models/     achievements, listening progress, player state
  pages/      app screens
  services/   auth, Firestore, sync, presence, notifications, settings, now playing
  theme/      brand colors, light/dark colors and theme
  utils/      haptics, transitions, text formatting, logging
  widgets/    shared UI (ui.dart), header, footer, cards, popups
test/         unit tests
```
