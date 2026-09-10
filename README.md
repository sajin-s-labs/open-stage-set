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

## 💻 Supported Operating Systems & Packages

| Platform | Target Formats | Description |
| :--- | :--- | :--- |
| 🤖 **Android** | `.apk` & `.aab` | Universal standalone APK + Google Play App Bundle |
| 🪟 **Windows** | `.exe` (Setup) & `.zip` (Portable) | Inno Setup wizard installer + standalone portable x64 zip |
| 🐧 **Linux** | `.deb`, `.rpm`, `.pkg.tar.zst`, `.AppImage`, `.flatpak`, `.tar.gz` | Debian/Ubuntu, Fedora/RHEL, Arch Linux, AppImage, Flatpak & Tarball |
| 🌐 **Web** | `.tar.gz` | Static web bundle (deployable to GitHub Pages, Netlify, Vercel, Nginx) |

---

## 🚀 GitHub Actions: Multi-OS Automated Builds

Two GitHub Actions workflows are included in `.github/workflows/`:

### 1. `release.yml` — Automated Multi-OS Release Workflow
Builds packages for **Android, Windows, Linux, and Web** in parallel, generating native installers and publication formats.

#### How to Trigger:
- **Option A: Push to Release Branch (Recommended)**
  ```bash
  git checkout -b rel/v1.0.0
  git push origin rel/v1.0.0
  ```
  GitHub Actions will immediately compile all platform builds and publish a GitHub Release tagged `v1.0.0` with all downloadable assets attached.

- **Option B: Push a Version Tag**
  ```bash
  git tag v1.0.0
  git push origin v1.0.0
  ```

- **Option C: Manual Trigger (`workflow_dispatch`)**
  1. Go to the **Actions** tab on your GitHub repository.
  2. Select **Multi-OS Build & Release** from the left sidebar.
  3. Click **Run workflow**, optionally toggling draft or pre-release flags.

#### Generated Release Assets:
- 🤖 **Android**: `open-stage-set-android.apk` (Install on phones/tablets) & `open-stage-set-android.aab` (Play Store)
- 🪟 **Windows**: `open-stage-set-windows-x64-setup.exe` (Setup Installer) & `open-stage-set-windows-x64-portable.zip` (Portable)
- 🐧 **Linux**: `open-stage-set-linux-amd64.deb` (Debian/Ubuntu), `open-stage-set-linux-x86_64.rpm` (Fedora/RHEL), `open-stage-set-linux-x86_64.pkg.tar.zst` (Arch), `open-stage-set-x86_64.AppImage` (Universal AppImage), `open-stage-set.flatpak` (Flatpak), `open-stage-set-linux-x64.tar.gz` (Tarball)
- 🌐 **Web**: `open-stage-set-web.tar.gz` (Static web production build)

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
