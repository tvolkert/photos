package com.stefaney.photos;

import android.annotation.TargetApi;
import android.os.Build;
import android.service.dreams.DreamService;
import android.view.KeyEvent;
import android.view.WindowManager.LayoutParams;

import io.flutter.FlutterInjector;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.embedding.engine.plugins.util.GeneratedPluginRegister;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;

@TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
public class MainService extends DreamService {
    private static final String CHANNEL_NAME = "photos.stefaney.com/channel";
    private static final String METHOD_NAME_WAKE_UP = "wakeUp";
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
        MethodChannel channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_NAME);
        channel.setMethodCallHandler((MethodCall methodCall, Result result) -> {
            switch (methodCall.method) {
                case METHOD_NAME_WAKE_UP:
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        wakeUp();
                    } else {
                        finish();
                    }
                    result.success(null);
                    break;
            }
        });
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

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        // This key event will propagate to Dart, where it is up to the Dart
        // side to call wakeUp() when appropriate.
        return getWindow().superDispatchKeyEvent(event);
    }
}
