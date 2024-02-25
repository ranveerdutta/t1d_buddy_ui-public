import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:t1d_buddy_ui/utils/shared_preference_util.dart';

class DeviceInfoService {


  static addDeviceInfoToSharedPref() async {
    Map<String, dynamic> deviceInfo = await getDeviceInfo();
    SharedPrefUtil.addDeviceInfo(jsonEncode(deviceInfo));
  }

  static Future<Map<String, dynamic>> getDeviceInfo() async {

      WidgetsFlutterBinding.ensureInitialized();

      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        AndroidDeviceInfo info = await deviceInfo.androidInfo;
        return readAndroidBuildMap(info);
      } else if (Platform.isIOS) {
        IosDeviceInfo info = await deviceInfo.iosInfo;
        return readIosDeviceInfo(info);
      } else {
        throw Exception('Device not supported');
      }

    }

  static Map<String, dynamic> readAndroidBuildMap(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'os_version': build.version.release,
      'brand': build.brand,
      'device': build.device,
      'model': build.model,
      'device_id': build.id,
    };
  }

  static Map<String, dynamic> readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'model': data.model,
      'localizedModel': data.localizedModel,
    };
  }

}