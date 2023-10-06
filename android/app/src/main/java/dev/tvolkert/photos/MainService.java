package dev.tvolkert.photos;

import android.annotation.TargetApi;
import android.content.ContentResolver;
import android.os.Build;
import android.provider.Settings;
import android.provider.Settings.SettingNotFoundException;
import android.service.dreams.DreamService;
import android.util.Log;
import android.view.KeyEvent;
import android.view.Window;
import android.view.WindowManager.LayoutParams;

import java.io.FileDescriptor;
import java.io.PrintWriter;

import io.flutter.FlutterInjector;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.embedding.engine.plugins.util.GeneratedPluginRegister;

@TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
public class MainService extends DreamService {
    private static final LayoutParams matchParent =
        new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);

    private static final int MAX_BRIGHTNESS = 255;

    private FlutterEngine flutterEngine;
    private FlutterView flutterView;
    private PhotosChannel photosChannel;

    private int existingBrightnessMode;
    private int existingBrightness;

    @Override
    public void onCreate() {
        super.onCreate();
        final FlutterLoader loader = FlutterInjector.instance().flutterLoader();
        loader.startInitialization(getApplicationContext());
        loader.ensureInitializationComplete(getApplicationContext(), new String[] {});
        flutterEngine = new FlutterEngine(this);
        GeneratedPluginRegister.registerGeneratedPlugins(flutterEngine);
        photosChannel = new PhotosChannel(flutterEngine, getApplicationContext(), this);
        photosChannel.register();
    }

    private void setScreenBrightness() {
        if (Settings.System.canWrite(this)) {
            ContentResolver resolver = getContentResolver();
            Window window = getWindow();
            try {
                existingBrightnessMode = Settings.System.getInt(resolver, Settings.System.SCREEN_BRIGHTNESS_MODE);
                Settings.System.putInt(resolver, Settings.System.SCREEN_BRIGHTNESS_MODE, Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL);
                existingBrightness = Settings.System.getInt(resolver, Settings.System.SCREEN_BRIGHTNESS);
                Settings.System.putInt(resolver, Settings.System.SCREEN_BRIGHTNESS, MAX_BRIGHTNESS);
                LayoutParams layoutParams = window.getAttributes();
                layoutParams.screenBrightness = MAX_BRIGHTNESS / 255f;
                window.setAttributes(layoutParams);
            } catch (SettingNotFoundException e) {
                // Throw an error case it couldn't be retrieved
                Log.e("Error", "Cannot access system brightness");
                e.printStackTrace();
            }
        }
    }

    private void restoreScreenBrightness() {
        ContentResolver resolver = getContentResolver();
        Settings.System.putInt(resolver, Settings.System.SCREEN_BRIGHTNESS_MODE, existingBrightnessMode);
        Settings.System.putInt(resolver, Settings.System.SCREEN_BRIGHTNESS, existingBrightness);
    }

    @Override
    public void onAttachedToWindow() {
        super.onAttachedToWindow();
        setInteractive(true);
        setFullscreen(true);
        setScreenBright(true);
        setScreenBrightness();
        flutterView = new FlutterView(this);
        flutterView.setLayoutParams(matchParent);
        flutterView.attachToFlutterEngine(flutterEngine);
        photosChannel.setFlutterView(flutterView);
        setContentView(flutterView);
        flutterEngine.getLifecycleChannel().appIsInactive();
    }

    @Override
    public void onDetachedFromWindow() {
        restoreScreenBrightness();
        flutterView.detachFromFlutterEngine();
        flutterView = null;
        flutterEngine.getLifecycleChannel().appIsDetached();
        super.onDetachedFromWindow();
    }

    @Override
    public void onDestroy() {
        flutterEngine.destroy();
        flutterEngine = null;
        super.onDestroy();
    }

    @Override
    public void onDreamingStarted() {
        super.onDreamingStarted();
        flutterEngine.getDartExecutor().executeDartEntrypoint(new DartExecutor.DartEntrypoint(
            FlutterInjector.instance().flutterLoader().findAppBundlePath(), "dream"
        ));
        flutterEngine.getLifecycleChannel().appIsResumed();
    }

    @Override
    public void onDreamingStopped() {
        flutterEngine.getLifecycleChannel().appIsPaused();
        super.onDreamingStopped();
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        // This key event will propagate to Dart, where it is up to the Dart
        // side to call wakeUp() when appropriate.
        return getWindow().superDispatchKeyEvent(event);
    }

    @Override
    protected void dump(FileDescriptor fd, PrintWriter pw, String[] args) {
        pw.println("PHOTOS SCREENSAVER");
        pw.print("  Is executing Dart? ");
        pw.println(flutterEngine.getDartExecutor().isExecutingDart());
        if (flutterEngine.getDartExecutor().isExecutingDart()) {
            pw.print("  Has rendered first frame? ");
            pw.println(flutterView.hasRenderedFirstFrame());
            if (flutterView.hasRenderedFirstFrame()) {
                pw.println("  <dumping render tree>");
                // TODO: dump render tree
            }
        }
    }
}
