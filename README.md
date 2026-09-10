# Open Stage Set 🎸🎹

> **Distraction-free, high-contrast monochrome live performance & setlist companion for gigging musicians.**

---

## 🌟 Key Features

### 1. 📋 Setlists & Live Stage View
- **Upcoming vs. Past Shows**: Automatic routing of concluded gigs into **Past Shows (Archive)** based on performance date (`date < today`) or manual gig completion.
- **Stage Display Teleprompter**: Clean, large-font stage mode with high-contrast active song spotlighting, custom stage chips (Capo, Tuning, Key, BPM), and live completion controls.
- **Set Duration Estimator**: Dynamic calculation of total gig length (`~32 min`) based on track tempos and standard durations.
- **Quick Actions**: Move songs up/down, duplicate setlists, edit venues, and re-open past shows into upcoming with one tap.

### 2. 🎼 Song Studio & Smart Transposition
- **Song Library**: Filter by key, tempo, author, and search instantly across custom stage fields.
- **Musical Transposer**: Transpose chord progressions with Roman numeral harmonic analysis and key modulation insights.
- **Interactive Chord Pattern Charts**: Visual piano roll and guitar chord fingerings for recommended substitutions and tensions.

### 3. 🔄 Music Theory Utilities
- **Interactive Circle of Fifths**: Explore relative minors, enharmonic equivalents, and dominant/subdominant relationships.
- **Harmonic Chord Recommender**: AI-assisted modal modulation and tension suggestions tailored for live composition.

---

## 💻 Supported Operating Systems

| Platform | Target Output | Description |
| :--- | :--- | :--- |
| **Android** | `.apk` & `.aab` | Universal standalone APK + Google Play App Bundle |
| **Windows** | `.zip` | Windows x64 portable standalone desktop build |
| **Linux** | `.tar.gz` | Linux x86_64 GTK desktop release bundle |
| **macOS** | `.zip` | macOS Universal application bundle (.app) |
| **Web** | `.tar.gz` | Static web bundle (deployable to GitHub Pages, Netlify, Vercel) |

---

## 🚀 GitHub Actions: Multi-OS Automated Builds

Two GitHub Actions workflows are included in `.github/workflows/`:

### 1. `release.yml` — Automated Multi-OS Release Workflow
Builds binaries for **Android, Linux, Windows, macOS, and Web** in parallel, packaging them as release assets.

#### How to Trigger:
- **Option A: Push a Version Tag (Recommended)**
  ```bash
  git tag v1.0.0
  git push origin v1.0.0
  ```
  GitHub Actions will immediately compile all 5 platform builds and create a GitHub Release with all downloadable assets attached.

- **Option B: Manual Trigger (`workflow_dispatch`)**
  1. Go to the **Actions** tab on your GitHub repository.
  2. Select **Multi-OS Build & Release** from the left sidebar.
  3. Click **Run workflow**, optionally toggling draft or pre-release flags.

#### Generated Release Assets:
- `open-stage-set-android.apk` (Direct install on Android phones & tablets)
- `open-stage-set-android.aab` (Google Play Store bundle)
- `open-stage-set-windows-x64.zip` (Portable Windows desktop app)
- `open-stage-set-linux-x64.tar.gz` (Linux desktop app)
- `open-stage-set-macos.zip` (macOS app bundle)
- `open-stage-set-web.tar.gz` (Static web production build)

---

### 2. `ci.yml` — Continuous Integration
Automatically runs `flutter analyze` and `flutter test` on every pull request and push to `main`/`master` to ensure zero regressions before merging.

---

## 🛠️ Local Development

### Prerequisites
- Flutter SDK (3.24.x or later)
- Dart SDK (3.5.x or later)

### Run Locally
```bash
# Run on web
flutter run -d web-server --web-port 8765 --web-hostname 0.0.0.0

# Run on Android device/emulator
flutter run -d android

# Run on Desktop (Linux / macOS / Windows)
flutter run -d linux   # On Linux
flutter run -d windows # On Windows
flutter run -d macos   # On macOS
```

### Static Analysis
```bash
flutter analyze lib/
```
