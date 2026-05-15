# ASHU – Advanced Streaming Hub for Users

A Spotify-inspired Flutter music streaming app with smart 10-second packet buffering, UPI donations, and a premium dark UI.

## Quick Start

### 1. Prerequisites
- Flutter SDK 3.22+ (stable channel)
- Android Studio Hedgehog or newer
- A physical Android device or emulator (API 26+)

### 2. Configure API keys

Open `lib/core/constants/api_constants.dart` and replace:

| Constant | Where to get it |
|---|---|
| `supabaseUrl` | Supabase dashboard → Settings → API → Project URL |
| `supabaseAnonKey` | Supabase dashboard → Settings → API → anon public |
| `jamendoClientId` | https://devportal.jamendo.com → My Applications |
| `googleWebClientId` | Google Cloud Console → OAuth 2.0 Client IDs |
| `upiId` | Your personal UPI ID e.g. `yourname@upi` |

### 3. Supabase database setup

1. Go to your Supabase project → SQL Editor
2. Open `supabase/migrations/001_initial_schema.sql`
3. Paste the entire file and click **Run**

### 4. Google Sign-In setup

1. Go to https://console.firebase.google.com
2. Add Android app with package name `com.ashu.music`
3. Download `google-services.json`
4. Place it in `android/app/google-services.json`

### 5. Run the app

```bash
cd ashu
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── core/           # Theme, router, network, constants
├── features/
│   ├── auth/       # Google, Email, Phone OTP login
│   ├── home/       # Featured tracks, genre rows
│   ├── search/     # Jamendo search + genre browse
│   ├── player/     # Full player + smart streaming
│   ├── playlist/   # CRUD playlists (Supabase)
│   ├── library/    # Liked songs, recently played
│   ├── profile/    # User profile + settings
│   └── support/    # UPI donation screen
├── shared/         # MiniPlayer, SongTile, MainScaffold
└── services/       # AudioHandler (background playback)
```

## Smart Streaming System

- Splits audio into 10-second segments using HTTP byte-range requests
- Maintains 20–40 second adaptive buffer based on network speed
- Buffer visualizer on the player screen shows live segment status
- Pre-loads next song's first segment before current song ends

## UPI Donations

- No API key or registration needed
- Opens GPay / PhonePe / Paytm directly via `upi_india` package
- Preset amounts: ₹29, ₹49, ₹99, ₹199 + custom
- Configure your UPI ID in `api_constants.dart`
