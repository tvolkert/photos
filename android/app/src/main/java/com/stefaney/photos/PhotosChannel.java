package com.stefaney.photos;

import android.Manifest;
import android.annotation.TargetApi;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.service.dreams.DreamService;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

@TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
public class PhotosChannel {
    private static final String CHANNEL_NAME = "photos.stefaney.com/channel";
    private static final String METHOD_NAME_WAKE_UP = "wakeUp";
    private static final String METHOD_NAME_TMP_GET_DOWNLOADS_DIRECTORY = "tmpGetDownloadsDirectory";
    private static final String METHOD_NAME_TMP_WRITE_FILE = "tmpWriteFile";

    static void register(@NonNull FlutterEngine flutterEngine, @NonNull Context applicationContext, @Nullable DreamService dreamService) {
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
                case METHOD_NAME_TMP_GET_DOWNLOADS_DIRECTORY:
//
//                    MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL);
//                    Cursor cursor = null;
//                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
//                        cursor = getApplicationContext().getContentResolver().query(
//                                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
//                                projection,
//                                selection,
//                                selectionArgs,
//                                sortOrder
//                        );
//                    }
//
//                    while (cursor.moveToNext()) {
//                        // Use an ID column from the projection to get
//                        // a URI representing the media item itself.
//                    }
                    File file = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
                    result.success(file.getPath());
                    break;
                case METHOD_NAME_TMP_WRITE_FILE:
                    String basename = methodCall.argument("basename");
                    byte[] bytes = methodCall.argument("bytes");

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        System.err.println("Using newer than Android Q");
                        ContentResolver resolver = applicationContext.getContentResolver();
                        ContentValues values = new ContentValues();
                        values.put(MediaStore.MediaColumns.DISPLAY_NAME, basename);
                        values.put(MediaStore.MediaColumns.MIME_TYPE, "text/plain");
                        values.put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS);
                        Uri uri = resolver.insert(MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL), values);
                        try (OutputStream out = resolver.openOutputStream(uri, "wt")) {
                            out.write(bytes);
                            out.flush();
                        } catch (IOException ex) {
                            System.err.println("uh oh 0");
                            System.err.println(ex.toString());
                            ex.printStackTrace();
                        }
                    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.FROYO) {
                        System.err.println("Using older than Android Q");
                        boolean hasPermission = true;
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            int permissionCheck = applicationContext.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE);
                            hasPermission &= (permissionCheck == PackageManager.PERMISSION_GRANTED);
                        }

                        if (hasPermission) {
                            File downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
                            String outputPath = downloadsDir.getAbsolutePath() + "/" + basename;
                            try (OutputStream out = new BufferedOutputStream(new FileOutputStream(outputPath))) {
                                out.write(bytes);
                            } catch (IOException ex) {
                                System.err.println("uh oh 1");
                                System.err.println(ex.toString());
                                ex.printStackTrace();
                            } catch (Throwable ex) {
                                System.err.println("uh oh 2");
                                System.err.println(ex.toString());
                                ex.printStackTrace();
                            }
                        } else {
                            System.err.println("Don't have permission!");
                        }
                    }

                    System.err.println("success");
                    result.success(null);
                    break;
            }
        });
    }
}
