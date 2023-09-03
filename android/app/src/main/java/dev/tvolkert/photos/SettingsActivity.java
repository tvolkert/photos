package dev.tvolkert.photos;

import android.content.pm.ActivityInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.content.res.Resources.Theme;
import android.os.Bundle;

import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterActivity;

public class SettingsActivity extends FlutterActivity {
    private PhotosChannel photosChannel;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
//        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        photosChannel = new PhotosChannel(getFlutterEngine(), getApplicationContext(), null);
        photosChannel.register();
        FlutterView flutterView = findViewById(FlutterActivity.FLUTTER_VIEW_ID);
        photosChannel.setFlutterView(flutterView);

//        try {
//            ActivityInfo activityInfo = getPackageManager().getActivityInfo(getComponentName(), PackageManager.GET_META_DATA);
//            int themeResId = activityInfo.theme;
//            String themeName = getResources().getResourceEntryName(themeResId);
//        } catch (NameNotFoundException e) {
//        }
    }
}
