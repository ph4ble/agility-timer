---
name: Known Issues & Fixes
description: Bugs encountered and their fixes in the agility-timer project across both platforms
type: project
originSessionId: de9e3a89-5ff8-4de8-ba30-422c1c9936ff
---
### WeChat Mini Program Issues & Fixes

1. **`btoa is not defined` error** — WeChat mini program runtime lacks the browser `btoa` function. Fixed by implementing a manual base64 encoder in `audioManager.ts` (`toBase64()` function using BASE64_CHARS lookup table).

2. **BPM slider unresponsive** — Custom `<View>` with `onTouchMove` doesn't work in mini program WebView. Fixed by replacing with Taro's native `<Slider>` component.

3. **Training controls below visible area** — `.center-area` had `flex: 1` with `min-height: 300px`, pushing controls off-screen. Fixed by changing to `height: 100vh` on `.training-page`, `min-height: 0` on `.center-area`, and `flex-shrink: 0` on controls.

4. **Training page stuck on "加载中..."** — `useDidShow` hook's callback timing didn't properly trigger React re-renders for state changes from `engine.start()`. Fixed by switching to `useLoad` hook which receives route params directly and fires at the correct lifecycle point.

5. **npm cache root-owned files (EACCES)** — `~/.npm` contained root-owned cache files. Fixed by running `sudo chown -R 501:20 ~/.npm`.

6. **Missing `@tarojs/plugin-framework-react`** — Not auto-installed with Taro template. Fixed with `npm install @tarojs/plugin-framework-react`.

7. **`defineConfig` not found** — Taro 4.2 config uses plain `export default {}` not `defineConfig()`. Fixed by removing the wrapper.

8. **Missing `babel-preset-taro`** — Not installed by default. Fixed with `npm install babel-preset-taro`.

9. **Cannot share to friends / Moments (转发/朋友圈无效)** — WeChat mini program sharing is opt-in per page. With no `onShareAppMessage` the "转发" menu item is disabled, and with no `onShareTimeline` the "分享到朋友圈" item never appears. Fixed by adding Taro's `useShareAppMessage` + `useShareTimeline` hooks to both `pages/index/index.tsx` and `pages/training/index.tsx`. Note: 朋友圈 only shows on Android WeChat (platform limitation, not fixable in code).

10. **Screen auto-dims during training (自动熄屏)** — The mini program never called the keep-screen-on API (the Flutter version uses `wakelock_plus`, but the Taro port omitted the equivalent). Fixed by calling `Taro.setKeepScreenOn({ keepScreenOn: true })` on active training phases (countIn/running/rest) in `pages/training/index.tsx`, and resetting to `false` on pause/finish and on page unmount.

### Flutter Android Issues & Fixes

1. **audioplayers_android compileSdk 33 incompatible** — Plugin forced compileSdk 33 while dependencies required 34+. Fixed by editing `~/.pub-cache/hosted/pub.dev/audioplayers_android-4.0.3/android/build.gradle` to compileSdk 36.

2. **Java 26 incompatible with AGP** — Installed openjdk@17 via Homebrew, set JAVA_HOME.

3. **Gradle 8.14 incompatible with AGP 9.0.1** — Updated gradle-wrapper.properties to Gradle 9.1.0.

4. **Java 26 unsupported class file major version 70** — Gradle 9.1.0 doesn't support Java 26. Use Java 17 via Homebrew: set `JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home` before building.
