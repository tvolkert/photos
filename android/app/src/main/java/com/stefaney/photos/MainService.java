package com.stefaney.photos;

import android.service.dreams.DreamService;
import android.view.WindowManager.LayoutParams;

import io.flutter.FlutterInjector;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry;
import io.flutter.embedding.engine.plugins.util.GeneratedPluginRegister;

public class MainService extends DreamService {
    private static final LayoutParams matchParent =
        new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);

    private FlutterEngine flutterEngine;
    private FlutterView flutterView;

    @Override
    public void onCreate() {
        super.onCreate();
        final FlutterLoader loader = FlutterInjector.instance().flutterLoader();
        loader.startInitialization(getApplicationContext());
        loader.ensureInitializationComplete(getApplicationContext(), new String[] {});
        flutterEngine = new FlutterEngine(this);
        GeneratedPluginRegister.registerGeneratedPlugins(flutterEngine);
    }

    @Override
    public void onAttachedToWindow() {
        super.onAttachedToWindow();
        setInteractive(false);
        setFullscreen(true);
        flutterView = new FlutterView(this);
        flutterView.setLayoutParams(matchParent);
        flutterView.attachToFlutterEngine(flutterEngine);
        setContentView(flutterView);
        flutterEngine.getLifecycleChannel().appIsInactive();
    }

    @Override
    public void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        flutterView.detachFromFlutterEngine();
        flutterView = null;
        flutterEngine.getLifecycleChannel().appIsDetached();
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
        super.onDreamingStopped();
        flutterEngine.getLifecycleChannel().appIsPaused();
    }
}
