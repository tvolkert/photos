package com.stefaney.photos;

import android.Manifest;
import android.annotation.TargetApi;
import android.app.ActivityManager;
import android.app.ActivityManager.MemoryInfo;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.pm.ConfigurationInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.opengl.GLES10;
import android.opengl.GLSurfaceView;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;
import android.service.dreams.DreamService;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.Map;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

@TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
public class PhotosChannel {
    private static final String CHANNEL_NAME = "photos.stefaney.com/channel";
    private static final String METHOD_NAME_WAKE_UP = "wakeUp";
    private static final String METHOD_NAME_TMP_GET_DOWNLOADS_DIRECTORY = "tmpGetDownloadsDirectory";
    private static final String METHOD_NAME_TMP_WRITE_FILE = "tmpWriteFile";
    private static final String METHOD_NAME_GET_DEVICE_INFO = "getDeviceInfo";

    @NonNull private final FlutterEngine flutterEngine;
    @NonNull private final Context applicationContext;
    @Nullable private final DreamService dreamService;
    @Nullable private MethodChannel channel;
    @Nullable private FlutterView flutterView;
    @Nullable private Map<String, Object> gpuInfo;

    public PhotosChannel(@NonNull FlutterEngine flutterEngine, @NonNull Context applicationContext, @Nullable DreamService dreamService) {
        this.flutterEngine = flutterEngine;
        this.applicationContext = applicationContext;
        this.dreamService = dreamService;
    }

    public void register() {
        if (channel != null) {
            // Already registered.
            return;
        }

        channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_NAME);
        channel.setMethodCallHandler((MethodCall methodCall, MethodChannel.Result result) -> {
            switch (methodCall.method) {
                case METHOD_NAME_WAKE_UP:
                    wakeUp(result);
                    break;
                case METHOD_NAME_TMP_GET_DOWNLOADS_DIRECTORY:
                    getDownloadsDirectory(result);
                    break;
                case METHOD_NAME_TMP_WRITE_FILE:
                    writeFile(methodCall, result);
                    break;
                case METHOD_NAME_GET_DEVICE_INFO:
                    getDeviceInfo(result);
                    break;
            }
        });
    }

    public FlutterView getFlutterView() {
        return flutterView;
    }

    public void setFlutterView(FlutterView flutterView) {
        this.flutterView = flutterView;
    }

    private void wakeUp(MethodChannel.Result result) {
        if (dreamService != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                dreamService.wakeUp();
            } else {
                dreamService.finish();
            }
        }
        result.success(null);
    }

    private void getDownloadsDirectory(MethodChannel.Result result) {
        // MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL);
        // Cursor cursor = null;
        // if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
        //     cursor = getApplicationContext().getContentResolver().query(
        //             MediaStore.Downloads.EXTERNAL_CONTENT_URI,
        //             projection,
        //             selection,
        //             selectionArgs,
        //             sortOrder
        //     );
        // }

        // while (cursor.moveToNext()) {
        //     // Use an ID column from the projection to get
        //     // a URI representing the media item itself.
        // }
        File file = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
        result.success(file.getPath());
    }

    private void writeFile(MethodCall methodCall, MethodChannel.Result result) {
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
    }

    private void getDeviceInfo(MethodChannel.Result result) {
        Map<String, Object> data = new HashMap<>();
        addProcessMemoryInfo(data);
        addSystemMemoryInfo(applicationContext, data);
        addGpuInfo(applicationContext, data);
        if (gpuInfo != null) {
            data.putAll(gpuInfo);
            result.success(data);
        } else if (flutterView != null) {
            AsyncGpuInfoRetriever retriever = new AsyncGpuInfoRetriever(result, flutterView, data);
            retriever.setListener(new AsyncGpuInfoRetrieverListener() {
                @Override
                public void onInfoRetrieved(Map<String, Object> gpuInfo) {
                    retriever.setListener(null);
                    PhotosChannel.this.gpuInfo = gpuInfo;
                    data.putAll(gpuInfo);
                    result.success(data);
                }
            });
        } else {
            // Skip adding GPU info.
            result.success(data);
        }
    }

    private static void addProcessMemoryInfo(Map<String, Object> data) {
        final long bytesPerMB = 1024 * 1024;
        final Runtime runtime = Runtime.getRuntime();
        final long usedMemInMB = (runtime.totalMemory() - runtime.freeMemory()) / bytesPerMB;
        final long maxHeapSizeInMB = runtime.maxMemory() / bytesPerMB;
        final long availHeapSizeInMB = maxHeapSizeInMB - usedMemInMB;
        data.put("maxHeapSizeMB", maxHeapSizeInMB);
        data.put("availHeapSizeMB", availHeapSizeInMB);
    }

    private static void addSystemMemoryInfo(@NonNull Context applicationContext, Map<String, Object> data) {
        final MemoryInfo memoryInfo = new MemoryInfo();
        final ActivityManager activityManager = (ActivityManager) applicationContext.getSystemService(Context.ACTIVITY_SERVICE);
        activityManager.getMemoryInfo(memoryInfo);
        final long availableMemMB = memoryInfo.availMem / 0x100000L;
        final long totalMemMB = memoryInfo.totalMem / 0x100000L;
        data.put("availableSystemRamMB", availableMemMB);
        data.put("totalSystemRamMB", totalMemMB);
    }

    private static void addGpuInfo(@NonNull Context applicationContext, Map<String, Object> data) {
        final ActivityManager activityManager = (ActivityManager) applicationContext.getSystemService(Context.ACTIVITY_SERVICE);
        final ConfigurationInfo configurationInfo = activityManager.getDeviceConfigurationInfo();
        data.put("gpuGlesVersion", configurationInfo.getGlEsVersion());
    }

    private interface AsyncGpuInfoRetrieverListener {
        void onInfoRetrieved(Map<String, Object> info);
    }

    private class AsyncGpuInfoRetriever implements GLSurfaceView.Renderer {
        private final MethodChannel.Result result;
        private final ViewGroup parentView;
        private final Map<String, Object> info;
        private final GLSurfaceView surfaceView;
        private AsyncGpuInfoRetrieverListener listener;

        AsyncGpuInfoRetriever(MethodChannel.Result result, ViewGroup parentView, Map<String, Object> info) {
            this.result = result;
            this.parentView = parentView;
            this.info = info;
            this.surfaceView = new GLSurfaceView(applicationContext);
            surfaceView.setRenderer(this);
            parentView.addView(surfaceView);
        }

        public void setListener(AsyncGpuInfoRetrieverListener listener) {
            this.listener = listener;
        }

        @Override
        public void onSurfaceCreated(GL10 gl, EGLConfig config) {
            info.put("glRenderer", gl.glGetString(GL10.GL_RENDERER));
            info.put("glVendor", gl.glGetString(GL10.GL_VENDOR));
            info.put("glVersion", gl.glGetString(GL10.GL_VERSION));
            info.put("glExtensions", gl.glGetString(GL10.GL_EXTENSIONS));

            new Handler(Looper.getMainLooper()).post(new Runnable() {
                @Override
                public void run() {
                    listener.onInfoRetrieved(info);
                    parentView.removeView(surfaceView);
                }
            });
        }

        @Override
        public void onSurfaceChanged(GL10 gl, int width, int height) {
        }

        @Override
        public void onDrawFrame(GL10 gl) {
        }
    }
}
