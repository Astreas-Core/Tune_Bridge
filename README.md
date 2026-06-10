<div align="center">
  <img src="assets/images/app_logo.png" alt="TuneBridge Logo" width="120" />
  <h1>TuneBridge</h1>
  <p><strong>A sleek, ad-free mobile application that syncs with your Spotify library and streams audio directly from YouTube.</strong></p>
  <p>
    <a href="https://github.com/Astreas-Core/Tune_Bridge/releases/latest">Download Latest APK</a>
    ·
    <a href="https://saregx.vercel.app/">SAREGX (Web App Companion)</a>
  </p>
</div>

<hr />

## ✨ Features

- 🎧 **Ad-Free Streaming**: Enjoy unlimited, uninterrupted music sourced directly from YouTube's vast library.
- 🔄 **Spotify Integration**: Import your playlists, liked songs, and library directly from Spotify using OAuth authentication.
- ☁️ **Cross-Platform Sync**: Search history and recently played tracks sync in real-time across devices via Firebase Firestore. 
- 🌐 **Web Companion**: TuneBridge seamlessly integrates with its web counterpart, [SAREGX](https://github.com/Astreas-Core/SAREGX), sharing the same robust backend and sync engine.
- 🎯 **Smart Recommendations**: A completely rebuilt, Spotify-style recommendation engine that learns what you love. It strictly caps artists to ensure a diverse feed, deduplicates titles intelligently, and updates continuously as you listen.
- 💾 **Offline Caching**: Locally cache your favorite tracks and playlists for seamless listening, even on slow connections.
- 🎨 **Sleek UI/UX**: Built with Flutter and a custom design system featuring dynamic micro-animations, glassmorphism, and a highly polished dark mode.
- 🔔 **In-App Updater**: Built-in GitHub release checker so you never miss an update.

## 🚀 Installation

### Android Users (Quick Install)
1. Go to the [Releases](https://github.com/Astreas-Core/Tune_Bridge/releases) page.
2. Download the latest `app-release.apk`.
3. Open the file on your Android device and install (you may need to "Allow from this source").

### Developers
To build and run TuneBridge from source, you'll need:
- Flutter 3.41.4+
- Dart 3.11.1+

1. Clone the repository:
   ```bash
   git clone https://github.com/Astreas-Core/Tune_Bridge.git
   cd Tune_Bridge
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run on an emulator or connected device:
   ```bash
   flutter run
   ```

## 🏗️ Architecture & Sync

TuneBridge uses a combination of **Hive** for fast local storage and **Firebase Firestore** for real-time synchronization with the SAREGX web app.

- `LocalLibraryService`: A facade over Hive boxes, managing the local cache, offline files, and providing instant UI updates.
- `FirebaseSyncService`: Listens for real-time remote updates from `history`, `searches`, `likes`, and `playlists` collections, keeping the mobile device and web application perfectly mirrored.
- `SearchBloc` & `BLoc` Architecture: Predictable, testable state management across the app.

## 🌐 Companion Web App

Love TuneBridge? Use it on your desktop browser! 
Check out **[SAREGX](https://github.com/Astreas-Core/SAREGX)** — the React-powered web application that syncs perfectly with your TuneBridge mobile app.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
