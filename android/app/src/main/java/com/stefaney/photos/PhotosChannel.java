package com.stefaney.photos;

import android.annotation.TargetApi;
import android.content.Context;
import android.os.Build;
import android.service.dreams.DreamService;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

@TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
public class PhotosChannel {
    private static final String CHANNEL_NAME = "photos.stefaney.com/channel";
    private static final String METHOD_NAME_WAKE_UP = "wakeUp";

    static void register(FlutterEngine flutterEngine, Context applicationContext, DreamService dreamService) {
        MethodChannel channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_NAME);
        channel.setMethodCallHandler((MethodCall methodCall, MethodChannel.Result result) -> {
            switch (methodCall.method) {
                case METHOD_NAME_WAKE_UP:
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        dreamService.wakeUp();
                    } else {
                        dreamService.finish();
                    }
                    result.success(null);
                    break;
            }
        });
    }
}
