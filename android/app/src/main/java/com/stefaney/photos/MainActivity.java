package com.stefaney.photos;

import android.os.Bundle;
import android.view.WindowManager;

import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterView;

public class MainActivity extends FlutterActivity {
    private PhotosChannel photosChannel;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        photosChannel = new PhotosChannel(getFlutterEngine(), getApplicationContext(), null);
        photosChannel.register();
        FlutterView flutterView = findViewById(FlutterActivity.FLUTTER_VIEW_ID);
        photosChannel.setFlutterView(flutterView);
    }
}
