import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';
import 'package:t1d_buddy_ui/forms/user_profile.dart';
import 'package:t1d_buddy_ui/utils/shared_preference_util.dart';

class Utils {

  static SnackBar customSnackBar({required String content}) {
    return SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        content,
        style: TextStyle(color: Colors.redAccent, letterSpacing: 0.5),
      ),
    );
  }

  static double convertDateTimeToHourMin(DateTime dateTime){
    return (dateTime.millisecondsSinceEpoch/1000/60).toDouble();
  }

  static String convertMinutesToHhMmString(int minutes){
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(minutes * 60 * 1000);

    return DateFormat('hh:mm a').format(dateTime.toLocal());
  }

  static String convertMinutesToHhMmStringTimeline(int minutes){
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(minutes * 60 * 1000);

    return DateFormat('hh:mm a').format(dateTime.toLocal()) + '\n' + DateFormat('dd-MMM').format(dateTime.toLocal());
  }

  static String convertDateTimeString(DateTime dateTime){
    return DateFormat('dd-MMM hh:mm a').format(dateTime.toLocal());
  }

  static Map<String, String> getHttpHeaders(String contentType, String? email, String? idToken){
    Map<String, dynamic> deviceInfo = SharedPrefUtil.getDeviceInfo();

    var header = <String, String>{
      'Content-Type': contentType,
      'os_version': deviceInfo['os_version'],
      'brand': deviceInfo['brand'],
      'device': deviceInfo['device'],
      'model': deviceInfo['model'],
      'device_id': deviceInfo['device_id'],
      'email' : email!,
      'app_id' : 'd32769ce913f9f8ce54f06b002ac920186f3d2cdb17a1dcc96f1a30f5e1430a7',
    };


    if(idToken != null){
      header.putIfAbsent('id_token', () => idToken);
    }

    return header;
  }

  static Future<String?> getIdToken(User? user) async{
    if(null == user){
      return null;
    }else{
      Token token = SharedPrefUtil.getUserToken();
      if(null == token){
        return null;
      }else{


        if((DateTime.now().millisecondsSinceEpoch/1000/60 - token.createdAt.millisecondsSinceEpoch/1000/60) > 50){
          String idToken = await user.getIdToken(true);
          if(idToken != token.idToken){
            SharedPrefUtil.addUserToken(new Token(idToken, DateTime.now()));
          }
          return idToken;
        }
        return token.idToken;
      }
    }
  }

  static Future<void> showLocalNotification(String? title, String? body, File? payload) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid = new AndroidInitializationSettings('notification_icon');
    var initializationSettings = new InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: notificationResponse);
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        't1d_buddy_channel', 't1d buddy Notifications',
        playSound: false, importance: Importance.max, priority: Priority.high);
    var platformChannelSpecifics = new NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(payload.hashCode, title, body, platformChannelSpecifics, payload: payload?.path);
  }

  static void notificationResponse(NotificationResponse response) async {
    await OpenFilex.open(response.payload);
  }

}