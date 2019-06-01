package com.stefaney.photos;

import android.service.dreams.DreamService;
import android.view.WindowManager.LayoutParams;

import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.view.FlutterMain;

public class MainService extends DreamService {
    private static final LayoutParams matchParent =
        new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);

    private FlutterEngine flutterEngine;
    private FlutterView flutterView;

    @Override
    public void onCreate() {
        super.onCreate();
        FlutterMain.startInitialization(getApplicationContext());
        FlutterMain.ensureInitializationComplete(getApplicationContext(), new String[] {});
    }

    @Override
    public void onAttachedToWindow() {
        super.onAttachedToWindow();

        setInteractive(false);
        setFullscreen(true);

        flutterEngine = new FlutterEngine(this);
        flutterView = new FlutterView(this);
        flutterView.setLayoutParams(matchParent);
        flutterView.attachToFlutterEngine(flutterEngine);
        setContentView(flutterView);
    }

    @Override
    public void onDetachedFromWindow() {
        super.onDetachedFromWindow();

        flutterView.detachFromFlutterEngine();
        flutterEngine.destroy();
        flutterView = null;
        flutterEngine = null;
    }

    @Override
    public void onDreamingStarted() {
        super.onDreamingStarted();

        final String appBundlePath = FlutterMain.findAppBundlePath(getBaseContext());
        if (appBundlePath != null) {
            flutterEngine.getDartExecutor().executeDartEntrypoint(new DartExecutor.DartEntrypoint(
                    getResources().getAssets(), appBundlePath, "main"
            ));
        }
    }
}
