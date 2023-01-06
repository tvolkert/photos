package com.stefaney.photos;

import android.annotation.TargetApi;
import android.os.Build;
import android.service.dreams.DreamService;
import android.view.KeyEvent;
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

    private FlutterEngine flutterEngine;
    private FlutterView flutterView;
    private PhotosChannel photosChannel;

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

    @Override
    public void onAttachedToWindow() {
        super.onAttachedToWindow();
        setInteractive(true);
        setFullscreen(true);
        setScreenBright(true);
        flutterView = new FlutterView(this);
        flutterView.setLayoutParams(matchParent);
        flutterView.attachToFlutterEngine(flutterEngine);
        photosChannel.setFlutterView(flutterView);
        setContentView(flutterView);
        flutterEngine.getLifecycleChannel().appIsInactive();
    }

    @Override
    public void onDetachedFromWindow() {
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
