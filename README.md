# photos

A Google Photos leanback experience

## Supported platforms

This is currently only designed to run on Android TV. I develop locally on macOS
desktop, but there's currently no Google Sign-In plugin for macOS, so you can
only run the signed-out experience. It should also run fine on Android phones,
but there's no home screen launcher; you authenticate via the screen saver
settings, and you run it by starting the screensaver.

## How to run during development

The `main` method in `lib/main.dart` can be edited to point to either
`settingsMain` to run the settings for the app, or `dream` to run the
screensaver.

Once you run the app, the following keyboard shortcuts in the app are useful:
1. `0` will enable a debug overlay that includes the Flutter performance overlay
   as well as some platform info (screen size, device pixel ratio, max heap
   size, available heap size, total system RAM, available system RAM, GLES
   version, GL vendor, GL renderer, GL version, and image cache size)
1. `8` will enable a small panel that will show the performance metrics that
   have been collected (via [`SchedulerBinding.addTimingsCallback`](https://api.flutter.dev/flutter/scheduler/SchedulerBinding/addTimingsCallback.html)). The
   metrics that drive the average times (build, raster, total frame) reset every
   100 frames, but the other metrics (worst times and missed frames) persist.
   If you want to reset all metrics, dismiss the panel by pressing `8` again
   and bring it back up by pressing `8` again (every time the panel comes up,
   it resets the metrics that have been collected).
