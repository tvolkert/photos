package dev.tvolkert.photos;

import android.os.Bundle;
import android.view.WindowManager.LayoutParams;

import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterView;

public class DreamActivity extends FlutterActivity {
    private PhotosChannel photosChannel;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(LayoutParams.FLAG_KEEP_SCREEN_ON);
        photosChannel = new PhotosChannel(getFlutterEngine(), getApplicationContext(), null);
        photosChannel.register();
        FlutterView flutterView = findViewById(FlutterActivity.FLUTTER_VIEW_ID);
        photosChannel.setFlutterView(flutterView);
    }
}
