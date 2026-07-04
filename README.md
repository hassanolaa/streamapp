# StreamApp

A cross-platform, feature-rich media streaming application built with Flutter. StreamApp allows users to explore, stream, and manage multiple types of media content including Videos, Movies, Series, Podcasts, and IPTV.

## 🚀 Key Features

* **Multi-Content Categories:** Dedicated sections for Home, Videos, Movies, Series, Podcasts, and IPTV.
* **Advanced Media Playback:** Powered by `media_kit` for robust and high-performance video streaming.
* **Smart Search & Filtering:** Filter searches by content type (videos, channels, playlists) and sort them by relevance, upload date, views, and ratings.
* **Content Moderation:** Built-in content filtering service to block harmful or explicit content.
* **Recommendations:** Local search history and recommendation engine.
* **Localization:** Full support for multi-language interfaces (English and Arabic natively supported via `easy_localization`).
* **Deep Linking / CLI Navigation:** Launch specific screens or media URLs directly via command-line arguments.
* **Theming:** Light and Dark mode with responsive, adaptive UI.

## 🛠 Tech Stack

* **Framework:** [Flutter](https://flutter.dev/) (SDK ^3.7.2)
* **Architecture:** Feature-first modular architecture
* **State Management:** BLoC / Cubit (`flutter_bloc`)
* **Dependency Injection:** `get_it`
* **Local Storage / Caching:** `hive` & `get_storage`
* **Media Player:** `media_kit` & `media_kit_video`
* **Localization:** `easy_localization`
* **Machine Learning:** `onnxruntime` (for advanced content filtering or recommendations)

## 📂 Project Structure

The project follows a modular, feature-based architecture pattern:

```
lib/
├── core/                  # Core infrastructure and shared utilities
│   ├── cache/             # Local data caching and storage mechanisms
│   ├── config/            # App configurations and constants
│   ├── di/                # Dependency injection setup (service locator)
│   ├── navigation/        # Routing and navigation logic
│   ├── services/          # Core services (e.g., ContentFilterService)
│   ├── theme/             # App themes (Light/Dark)
│   └── utils/             # Helper functions and extensions
│
├── features/              # Feature modules containing presentation, domain, and data layers
│   ├── home/              # Main dashboard and navigation shell
│   ├── iptv/              # IPTV player and playlist management
│   ├── movies/            # Movies catalog and streaming
│   ├── podcasts/          # Podcasts discovery and playback
│   ├── series/            # TV Series catalog and streaming
│   ├── video_player/      # Shared video player and UI controls
│   └── videos/            # YouTube/Invidious-style video browsing, search, and details
│
└── main.dart              # Application entry point
```

## 🎮 CLI Arguments (Deep Linking)

StreamApp supports opening specific pages directly from the command line using arguments. This is particularly useful for desktop environments (Linux/Windows/macOS).

**Usage:**
```bash
flutter run -d <device> --args "<args>"
```
*Alternatively, if running the compiled executable, pass them directly:*
```bash
./streamapp -s video -u "https://example.com/video.mp4"
```

**Supported Arguments:**
* `--screen` or `-s`: The screen to launch (e.g., `home`, `search`, `playlist`, `video`, `channel`, `videos`, `movies`, `series`, `iptv`, `test`).
* `--url` or `-u`: The URL of the media (required for `playlist`, `video`, and `channel` screens).
* `--query` or `-q`: The initial search query (used with the `search` screen).

**Examples:**
* Open the Search page with a query:
  `--screen search --query "Flutter development"`
* Open a specific Video:
  `--screen video --url "https://example.com/stream.m3u8"`
* Open the IPTV page:
  `--screen iptv`

## 🏁 Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (^3.7.2 or higher)
* Depending on your target platform, make sure to install the required `media_kit` native dependencies. (e.g., `mpv` and `libmpv` for Linux/Windows).

### Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd streamapp
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate required code (Hive adapters, etc.):**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

## 🌍 Localization

To add new translations or update existing ones, modify the JSON files located in `assets/translations/`.

## 📜 License

This project is licensed under the MIT License.
