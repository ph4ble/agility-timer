---
name: Project Architecture
description: Overall architecture of the agility-timer project including both Flutter (Android) and Taro (WeChat Mini Program) versions
type: project
originSessionId: de9e3a89-5ff8-4de8-ba30-422c1c9936ff
---
## Project: 敏捷训练计时器 (Agility Training Timer)

A sports agility training timer app built for two platforms, sharing the same feature set and design language.

**Why:** The user wanted to distribute to both Android users (APK) and WeChat users (mini program, no install required). The Flutter version targets Android. The Taro version targets WeChat Mini Program.

**How to apply:** When making feature changes, both platforms should be updated. The engines (metronome, tone generator, training state machine) have the same logic but different implementations due to platform constraints.

### GitHub Repo: https://github.com/ph4ble/agility-timer

- **main** branch contains both versions
- Root: Flutter Android app (V0.1, V0.2)
- `wechat-mini-program/`: Taro mini program (V0.1-mini)

### Flutter Android Version (Root directory)

Path: `/Users/ywwl/Desktop/随机事件定时器项目/`

| Component | Path | Role |
|-----------|------|------|
| Entry | `lib/main.dart` | App entry point |
| Home Screen | `lib/screens/home_screen.dart` | Settings page, single screen no scroll |
| Training Screen | `lib/screens/training_screen.dart` | Count-in, beat ring, direction arrow, pause/stop |
| Config Model | `lib/models/training_config.dart` | Enums, TrainingConfig, defaults |
| Training Engine | `lib/engines/training_engine.dart` | State machine: idle→countIn→running→rest→paused→finished |
| Metronome Engine | `lib/engines/metronome_engine.dart` | Timer-based metronome |
| Tone Generator | `lib/engines/tone_generator.dart` | WAV audio synthesis in Dart |
| Audio Service | `lib/services/audio_service_mobile.dart` | audioplayers-based audio pool |
| BPM Control | `lib/widgets/bpm_control.dart` | Compact BPM slider with +/- buttons |
| Beat Ring | `lib/widgets/beat_ring.dart` | Animated pulsing ring |
| Direction Overlay | `lib/widgets/direction_overlay.dart` | Arrow pop animation |
| Android Build | `android/` | compileSdk=36, AGP 9.0.1, Gradle 9.1.0, Java 17 |
| WakeLock | `wakelock_plus` | Keep screen on during training |

### Taro Mini Program Version

Path: `/Users/ywwl/Desktop/wechat-agility-timer/`
Repo: `wechat-mini-program/`

| Component | Path | Role |
|-----------|------|------|
| App Entry | `src/app.tsx` | Root component |
| App Config | `src/app.config.ts` | Pages config (index, training) |
| App Styles | `src/app.scss` | Dark theme CSS variables |
| Home Page | `src/pages/index/index.tsx` | Settings: mode, BPM, direction, signal, volumes |
| Training Page | `src/pages/training/index.tsx` | Timer, beat ring, direction arrow, controls |
| Config Model | `src/models/config.ts` | Same enums/types as Flutter, ported to TS |
| Training Engine | `src/engines/trainingEngine.ts` | Same state machine, setInterval-based |
| Metronome | `src/engines/metronome.ts` | setInterval-driven metronome |
| Tone Generator | `src/engines/toneGenerator.ts` | Pure JS WAV synthesis (same algorithms as Dart) |
| Audio Manager | `src/engines/audioManager.ts` | Taro.createInnerAudioContext pool, custom base64 encoder |
| BPM Control | `src/components/BpmControl/index.tsx` | Taro Slider + +/- quick buttons |
| Beat Ring | `src/components/BeatRing/index.tsx` | CSS @keyframes pulse animation |
| Direction Arrow | `src/components/DirectionArrow/index.tsx` | CSS pop/fade animation |
| Build Config | `config/index.ts` | Taro 4.2, webpack5, designWidth 375 |
| Build Output | `dist/` | WeChat mini program compiled output |

### Core Feature Set (Both Platforms)

- **4 Training Modes**: Free, Timed, Progressive (BPM ramp), Interval (work/rest cycles)
- **Metronome**: 20-300 BPM, configurable beats per bar
- **Random Direction Signals**: Within configurable beat intervals, 2-4 directions
- **Dual Sound Types**: Generic alert tone / direction-specific tones (voice-like)
- **Random BPM Variation**: Configurable % range, changes every few bars
- **Count-in**: 3-2-1-Go audio + beat sequence
- **Countdown Warning**: 10s beep + red flash animation
- **End Bell**: 4-note chime when training completes
- **Pause/Resume**: Full pause support with audio/timer management
- **Screen Keep-On**: Wakelock prevents screen sleep during active training (disables on pause/stop)
- **Dark Theme**: `#1A1A2E` background, `#E91E63` accent, `#00E5FF` cyan highlights

### Technical Decisions & Tradeoffs

- **Taro over uni-app**: Better React support, community, and mini program compatibility
- **setInterval metronome**: Less precise than Flutter's timer API but workable for mini programs
- **CSS animations over JS**: Beat ring pulse and direction arrow use CSS keyframes instead of JS animation loops (better performance in mini program WebView)
- **WAV generation over audio files**: Pure JS WAV synthesis means no external audio assets needed, all sounds generated from math
- **Custom base64 encoder**: WeChat runtime doesn't have `btoa()`, so a manual base64 implementation was needed
- **GitHub push via API**: `github.com` is blocked from the user's network; `api.github.com` works, so commits are pushed via Git Data API
- **`useLoad` not `useDidShow`**: In Taro 4.x, `useLoad` is the correct hook for receiving page route params on initial load
- **Sharing via Taro hooks**: `useShareAppMessage` (转发好友) + `useShareTimeline` (朋友圈) registered on both pages; sharing is opt-in per page in WeChat, and 朋友圈 only appears on Android WeChat
- **`setKeepScreenOn` for wakelock**: Mini program equivalent of Flutter's `wakelock_plus`; enabled on active training phases, disabled on pause/finish/unmount
