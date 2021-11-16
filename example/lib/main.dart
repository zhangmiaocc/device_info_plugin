import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:device_info_plugin/device_info_plugin.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  bool? _isFirstInstall = true;
  String _uuid          = '';
  String _bundleId      = '';
  String _appName       = '';
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    bool? isFirstInstall = true;
    String uuid = '';
    String bundleId = '';
    String appName = '';
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      if (Platform.isAndroid) {
        DeviceInfoPlugin deviceinfoplugin = new DeviceInfoPlugin();
        AndroidDeviceInfo androidDeviceInfo = await deviceinfoplugin.androidInfo;
        isFirstInstall = androidDeviceInfo.isFirstInstall!;
        uuid           = androidDeviceInfo.uuid!;
        // platformVersion = androidDeviceInfo.deviceRegion!;
      } else {
        DeviceInfoPlugin deviceinfoplugin = new DeviceInfoPlugin();
        IosDeviceInfo iosInfo = await deviceinfoplugin.iosInfo;
        isFirstInstall = iosInfo.isFirstInstall;
        uuid           = iosInfo.uuid!;
        bundleId      = iosInfo.bundleId ??'';
        appName       = iosInfo.appName ?? '';
      }
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _isFirstInstall = isFirstInstall;
      _uuid           = uuid;
      _bundleId       = bundleId;
      _appName        = appName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_appName\n'),
        ),
      ),
    );
  }
}
