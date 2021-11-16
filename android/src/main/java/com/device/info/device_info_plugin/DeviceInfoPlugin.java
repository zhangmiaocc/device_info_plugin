package com.device.info.device_info_plugin;

import android.annotation.SuppressLint;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.LocaleList;
import android.provider.Settings;
import android.text.TextUtils;

import java.io.BufferedReader;
import java.io.FileReader;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * DeviceInfoPlugin
 */
public class DeviceInfoPlugin implements FlutterPlugin, MethodCallHandler {
    private ContentResolver contentResolver;
    static Context context;

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "device_info_plugin");
        channel.setMethodCallHandler(new DeviceInfoPlugin());
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        contentResolver = binding.getApplicationContext().getContentResolver();
        final MethodChannel channel = new MethodChannel(binding.getBinaryMessenger(), "device_info_plugin");
        channel.setMethodCallHandler(new DeviceInfoPlugin());
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        } else if (call.method.equals("getAndroidDeviceInfo")) {
            Map<String, Object> build = new HashMap<>();
            build.put("isFirstInstall", isFirstInstall());
            build.put("board", Build.BOARD);
            build.put("bootloader", Build.BOOTLOADER);
            build.put("brand", Build.BRAND);
            build.put("device", Build.DEVICE);
            build.put("display", Build.DISPLAY);
            build.put("fingerprint", Build.FINGERPRINT);
            build.put("hardware", Build.HARDWARE);
            build.put("host", Build.HOST);
            build.put("id", Build.ID);
            build.put("manufacturer", Build.MANUFACTURER);
            build.put("model", Build.MODEL);
            build.put("product", Build.PRODUCT);
            build.put("tags", Build.TAGS);
            build.put("type", Build.TYPE);
            build.put("uuid", getUuid());
            build.put("runtimesize", getTotalRam());
            build.put("screenWidthPX", getScreenWidth(context) + "");
            build.put("screenHeightPX", getScreenHeight(context) + "");
            build.put("versionName", getAppInfos(context, 1));
            build.put("versionCode", getAppInfos(context, 2));
            build.put("packageName", getAppInfos(context, 3));
            build.put("deviceRegion", getDeviceRegion());
            Map<String, Object> version = new HashMap<>();
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                version.put("baseOS", Build.VERSION.BASE_OS);
                version.put("previewSdkInt", Build.VERSION.PREVIEW_SDK_INT);
                version.put("securityPatch", Build.VERSION.SECURITY_PATCH);
            }
            version.put("codename", Build.VERSION.CODENAME);
            version.put("incremental", Build.VERSION.INCREMENTAL);
            version.put("release", Build.VERSION.RELEASE);
            version.put("sdkInt", Build.VERSION.SDK_INT);
            build.put("version", version);

            result.success(build);
        } else {
            result.notImplemented();
        }
    }

    private boolean isFirstInstall() {
        String devices_id = (String) SPUtils.get(context, "deviceid", "");
        if (TextUtils.isEmpty(devices_id)) {
           return true;
        }
        return false;
    }

    //获取APP版本号
    public static String getAppInfos(Context context, int flag) {
        try {
            PackageManager pm = context.getPackageManager();
            PackageInfo info = pm.getPackageInfo(context.getPackageName(), 0);

            if (flag == 1) {//版本号
                return info.versionName;
            }
            if (flag == 2) {//版本code
                return info.versionCode + "";
            }
            if (flag == 3) {//包名
                return info.packageName;
            }
        } catch (Exception e) {
            e.printStackTrace();
            return "";
        }
        return "";
    }

    private String getDeviceRegion() {
        Locale locale;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            locale = LocaleList.getDefault().get(0);
        } else {
            locale = Locale.getDefault();
        }
        //第一次进来的时候 获取REGION_REL 真实地区
        String country = locale.getCountry();
        return country;
    }

    private String getUuid() {
        String devices_id = (String) SPUtils.get(context, "deviceid", "");
        if (TextUtils.isEmpty(devices_id)) {
            devices_id = getAndroidId();
            SPUtils.putForDeviced(context, "deviceid", devices_id);
        }
        return devices_id;
    }

    @SuppressLint("HardwareIds")
    public static String getAndroidId() {
        String androidID = "";
        try {
            androidID = Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ANDROID_ID);
        } catch (Exception e) {
            /// 随机生成
            UUID uuid = UUID.randomUUID();
            androidID = uuid.toString();
        }
        return androidID;
    }

    //获取手机内存
    public static String getTotalRam() {//GB
        String path = "/proc/meminfo";
        String firstLine = null;
        int totalRam = 0;
        try {
            FileReader fileReader = new FileReader(path);
            BufferedReader br = new BufferedReader(fileReader, 8192);
            firstLine = br.readLine().split("\\s+")[1];
            br.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        if (firstLine != null) {
            totalRam = (int) Math.ceil((new Float(Float.valueOf(firstLine) / (1024 * 1024)).doubleValue()));
        }
        return totalRam + "GB";//返回1GB/2GB/3GB/4GB
    }

    //获取屏宽
    public static int getScreenWidth(Context context) {
        return context.getResources().getDisplayMetrics().widthPixels;
    }

    //获取屏高
    public static int getScreenHeight(Context context) {
        return context.getResources().getDisplayMetrics().heightPixels;
    }

}
