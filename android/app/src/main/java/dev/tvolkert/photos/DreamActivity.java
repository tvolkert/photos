package dev.tvolkert.photos;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.view.WindowManager.LayoutParams;

import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterView;

public class DreamActivity extends FlutterActivity {
    private PhotosChannel photosChannel;

    private static final String PACKAGE_URI_PREFIX = "package:";

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(LayoutParams.FLAG_KEEP_SCREEN_ON);
        photosChannel = new PhotosChannel(getFlutterEngine(), getApplicationContext(), null);
        photosChannel.register();
        FlutterView flutterView = findViewById(FlutterActivity.FLUTTER_VIEW_ID);
        photosChannel.setFlutterView(flutterView);
	if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
	    if (!Settings.System.canWrite(this)) {
	        try {
		    Intent intent = new Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS);
		    intent.setData(Uri.parse(PACKAGE_URI_PREFIX + getPackageName()));
                    startActivity(intent);
	        } catch (ActivityNotFoundException e) {
	        }
	    }
	}
    }
}
