import 'dart:async';

import 'package:flutter/services.dart';

class DeviceInfoPlugin {
  DeviceInfoPlugin();

  static const MethodChannel channel = const MethodChannel('device_info_plugin');

  /// This information does not change from call to call. Cache it.
  AndroidDeviceInfo? _cachedAndroidDeviceInfo;

  /// Information derived from `android.os.Build`.
  ///
  /// See: https://developer.android.com/reference/android/os/Build.html
  Future<AndroidDeviceInfo> get androidInfo async => _cachedAndroidDeviceInfo ??=
      AndroidDeviceInfo._fromMap(await channel.invokeMapMethod<String, dynamic>('getAndroidDeviceInfo'));

  /// This information does not change from call to call. Cache it.
  IosDeviceInfo? _cachedIosDeviceInfo;

  /// Information derived from `UIDevice`.
  ///
  /// See: https://developer.apple.com/documentation/uikit/uidevice
  Future<IosDeviceInfo> get iosInfo async => _cachedIosDeviceInfo ??=
      IosDeviceInfo._fromMap(await channel.invokeMapMethod<String, dynamic>('getIosDeviceInfo'));

}

/// Information derived from `android.os.Build`.
///
/// See: https://developer.android.com/reference/android/os/Build.html
class AndroidDeviceInfo {
  AndroidDeviceInfo._({
    this.version,
    this.board,
    this.bootloader,
    this.brand,
    this.device,
    this.display,
    this.fingerprint,
    this.hardware,
    this.host,
    this.id,
    this.manufacturer,
    this.model,
    this.product,
    this.tags,
    this.type,
    this.uuid,
    this.runtimesize,
    this.screenWidthPX,
    this.screenHeightPX,
    this.versionName,
    this.versionCode,
    this.packageName,
    this.deviceRegion,
    this.isFirstInstall,
  });

  final bool? isFirstInstall;

  final String? deviceRegion;

  /// Android operating system version values derived from `android.os.Build.VERSION`.
  final AndroidBuildVersion? version;

  /// The name of the underlying board, like "goldfish".
  final String? board;

  /// The system bootloader version number.
  final String? bootloader;

  /// The consumer-visible brand with which the product/hardware will be associated, if any.
  final String? brand;

  /// The name of the industrial design.
  final String? device;

  /// A build ID string meant for displaying to the user.
  final String? display;

  /// A string that uniquely identifies this build.
  final String? fingerprint;

  /// The name of the hardware (from the kernel command line or /proc).
  final String? hardware;

  /// Hostname.
  final String? host;

  /// Either a changelist number, or a label like "M4-rc20".
  final String? id;

  /// The manufacturer of the product/hardware.
  final String? manufacturer;

  /// The end-user-visible name for the end product.
  final String? model;

  /// The name of the overall product.
  final String? product;

  /// Comma-separated tags describing the build, like "unsigned,debug".
  final String? tags;

  /// The type of build, like "user" or "eng".
  final String? type;

  /// The Android hardware device ID that is unique between the device + user and app signing.
  final String? uuid;
  final String? runtimesize;
  final String? screenWidthPX;
  final String? screenHeightPX;
  final String? versionName;
  final String? versionCode;
  final String? packageName;

  /// Deserializes from the message received from [_kChannel].
  static AndroidDeviceInfo _fromMap(Map<String, dynamic>? map) {
    return AndroidDeviceInfo._(
      version: AndroidBuildVersion._fromMap(map!['version']?.cast<String, dynamic>()),
      board: map['board'],
      bootloader: map['bootloader'],
      brand: map['brand'],
      device: map['device'],
      display: map['display'],
      fingerprint: map['fingerprint'],
      hardware: map['hardware'],
      host: map['host'],
      id: map['id'],
      manufacturer: map['manufacturer'],
      model: map['model'],
      product: map['product'],
      tags: map['tags'],
      type: map['type'],
      uuid: map['uuid'],
      runtimesize: map['runtimesize'],
      screenWidthPX: map['screenWidthPX'],
      screenHeightPX: map['screenHeightPX'],
      versionName: map['versionName'],
      versionCode: map['versionCode'],
      packageName: map['packageName'],
      deviceRegion: map['deviceRegion'],
      isFirstInstall: map['isFirstInstall'],
    );
  }
}

/// Version values of the current Android operating system build derived from
/// `android.os.Build.VERSION`.
///
/// See: https://developer.android.com/reference/android/os/Build.VERSION.html
class AndroidBuildVersion {
  AndroidBuildVersion._({
    this.baseOS,
    this.codename,
    this.incremental,
    this.previewSdkInt,
    this.release,
    this.sdkInt,
    this.securityPatch,
  });

  /// The base OS build the product is based on.
  final String? baseOS;

  /// The current development codename, or the string "REL" if this is a release build.
  final String? codename;

  /// The internal value used by the underlying source control to represent this build.
  final String? incremental;

  /// The developer preview revision of a prerelease SDK.
  final int? previewSdkInt;

  /// The user-visible version string.
  final String? release;

  /// The user-visible SDK version of the framework.
  ///
  /// Possible values are defined in: https://developer.android.com/reference/android/os/Build.VERSION_CODES.html
  final int? sdkInt;

  /// The user-visible security patch level.
  final String? securityPatch;

  /// Deserializes from the map message received from [_kChannel].
  static AndroidBuildVersion _fromMap(Map<String, dynamic> map) {
    return AndroidBuildVersion._(
      baseOS: map['baseOS'],
      codename: map['codename'],
      incremental: map['incremental'],
      previewSdkInt: map['previewSdkInt'],
      release: map['release'],
      sdkInt: map['sdkInt'],
      securityPatch: map['securityPatch'],
    );
  }
}

/// Information derived from `UIDevice`.
///
/// See: https://developer.apple.com/documentation/uikit/uidevice
class IosDeviceInfo {
  IosDeviceInfo._({
    this.bundleId,
    this.appName,
    this.uuid,
    this.adid,
    this.appversion,
    this.screenWidthPX,
    this.screenHeightPX,
    this.runtimesize,
    this.realRegion,
    this.devieceUserName,
    this.deviceModelName,
    this.systemName,
    this.systemVersion,
    this.localizedModel,
    this.identifierForVendor,
    this.isPhysicalDevice,
    this.utsname,
    this.deviceRegion,
    this.isFirstInstall,
  });

  /// app bundle identifier
  final String? bundleId;

  /// app name
  final String? appName;

  /// Device Unique identifier
  final String? uuid;

  /// Device ad identifier
  final String? adid;

  /// app version
  final String? appversion;

  /// Device screen size dp_dp
  final String? screenWidthPX;
  final String? screenHeightPX;

  /// Device physicalMemory size
  final String? runtimesize;

  final String? realRegion;

  /// Device name.
  final String? devieceUserName;

  /// Device model name . Such sa iPhone 8 plus
  final String? deviceModelName;

  /// The name of the current operating system. Such sa iOS
  final String? systemName;

  /// The current operating system version. Such as 13.3.1
  final String? systemVersion;

  /// Localized name of the device model.
  final String? localizedModel;

  /// Unique UUID value identifying the current device.
  final String? identifierForVendor;

  /// `false` if the application is running in a simulator, `true` otherwise.
  final bool? isPhysicalDevice;
  final String? deviceRegion;

  /// Operating system information derived from `sys/utsname.h`.
  final IosUtsname? utsname;

  /// is first install the App, if you uninstall the app, and then reinstall , return false.
  final bool? isFirstInstall;

  /// Deserializes from the map message received from [_kChannel].
  static IosDeviceInfo _fromMap(Map<String, dynamic>? map) {
    return IosDeviceInfo._(
      bundleId: map!['bundleId'],
      appName: map['appName'],
      uuid: map['uuid'],
      adid: map['adid'],
      appversion: map['appversion'],
      screenWidthPX: map['screenWidthPX'],
      screenHeightPX: map['screenHeightPX'],
      runtimesize: map['runtimesize'],
      realRegion: map['realRegion'],
      devieceUserName: map['devieceUserName'],
      deviceModelName: map['deviceModelName'],
      systemName: map['systemName'],
      systemVersion: map['systemVersion'],
      localizedModel: map['localizedModel'],
      identifierForVendor: map['identifierForVendor'],
      isPhysicalDevice: map['isPhysicalDevice'] == 'true',
      deviceRegion: map['deviceRegion'],
      utsname: IosUtsname._fromMap(map['utsname']?.cast<String, dynamic>()),
      isFirstInstall: map['isFirstInstall'],
    );
  }
}

/// Information derived from `utsname`.
/// See http://pubs.opengroup.org/onlinepubs/7908799/xsh/sysutsname.h.html for details.
class IosUtsname {
  IosUtsname._({
    this.sysname,
    this.nodename,
    this.release,
    this.version,
    this.machine,
  });

  /// Operating system name.
  final String? sysname;

  /// Network node name.
  final String? nodename;

  /// Release level.
  final String? release;

  /// Version level.
  final String? version;

  /// Hardware type (e.g. 'iPhone7,1' for iPhone 6 Plus).
  final String? machine;

  /// Deserializes from the map message received from [_kChannel].
  static IosUtsname _fromMap(Map<String, dynamic> map) {
    return IosUtsname._(
      sysname: map['sysname'],
      nodename: map['nodename'],
      release: map['release'],
      version: map['version'],
      machine: map['machine'],
    );
  }
}
