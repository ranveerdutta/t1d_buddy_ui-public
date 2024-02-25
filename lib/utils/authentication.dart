import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:t1d_buddy_ui/forms/user_profile.dart';
import 'package:t1d_buddy_ui/screens/home.dart';
import 'package:t1d_buddy_ui/screens/network.dart';
import 'package:t1d_buddy_ui/screens/registration.dart';
import 'package:t1d_buddy_ui/screens/reminder.dart';
import 'package:t1d_buddy_ui/utils/common_utils.dart';
import 'package:http/http.dart' as http;
import 'package:t1d_buddy_ui/utils/environment.dart';
import 'package:t1d_buddy_ui/services/user_services.dart';
import 'package:t1d_buddy_ui/utils/shared_preference_util.dart';

class Authentication {
  static Future<FirebaseApp> initializeFirebase({
    required BuildContext context,
  }) async {
    FirebaseApp firebaseApp = await Firebase.initializeApp();

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await initializeFirebaseMessaging(user);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => Home(
            user: user,
          ),
        ),
      );
    }

    return firebaseApp;
  }

  static Future<void> initializeFirebaseMessaging(User _user) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    messaging.getToken().then((value){
      UserProfile userProfile = SharedPrefUtil.getUserProfile();
      if(userProfile.fcmToken == null || userProfile.fcmToken != value){
        UserService.updateNewFcmToken(userProfile, value!);
      }
    });

    FirebaseMessaging.onMessage.listen(_messageHandler);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      /*if(message.notification?.title == 'Reminder'){
        Reminder(user: _user);
      }else if(message.notification?.title == 'New connection'){
        Network(user: _user);
      }*/
      //print('Message clicked!');
    });

    FirebaseMessaging.onBackgroundMessage(_backgorundMessageHandler);

  }

  static Future<void> _backgorundMessageHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    await _messageHandler(message);
  }

  static Future<void> _messageHandler(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    AndroidNotificationChannel channel = const AndroidNotificationChannel(
      't1d_buddy_channel', // id
      't1d buddy Notifications', // title
      importance: Importance.high,
    );
    if (notification != null && android != null && !kIsWeb) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: 'notification_icon',
            color: Colors.blue,
          ),
        ),
      );
    }
  }

  static Future<User?> signInWithGoogle({required BuildContext context}) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    if (kIsWeb) {
      GoogleAuthProvider authProvider = GoogleAuthProvider();

      try {
        final UserCredential userCredential =
        await auth.signInWithPopup(authProvider);

        user = userCredential.user;
      } catch (e) {
        print(e);
      }
    } else {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleSignInAccount =
      await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        try {
          final UserCredential userCredential =
          await auth.signInWithCredential(credential);

          user = userCredential.user;
          await validateUser(context: context, user: user);
          user = FirebaseAuth.instance.currentUser;

          await UserService.addUseTokenToSharedPref(user);

          await UserService.addUserProfileToSharedPref(user?.email, user);

          await UserService.addPublicProfileToSharedPref(user?.email, user);

        } on FirebaseAuthException catch (e) {
          if (e.code == 'account-exists-with-different-credential') {
            ScaffoldMessenger.of(context).showSnackBar(
              Utils.customSnackBar(
                content:
                'The account already exists with a different credential',
              ),
            );
          } else if (e.code == 'invalid-credential') {
            ScaffoldMessenger.of(context).showSnackBar(
              Utils.customSnackBar(
                content:
                'Error occurred while accessing credentials. Try again.',
              ),
            );
          }
        } catch (e) {
          if (!kIsWeb) {
            await googleSignIn.signOut();
          }
          await FirebaseAuth.instance.signOut();
          String content = 'Error occurred using Google Sign In. Try again.';
          if('Exception: Not a registered user' == e.toString()){
            //content = 'Not a registered user';
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder:(context) => Registration(email: user!.email, noInviteFlow: true,)));
          }else{
            ScaffoldMessenger.of(context).showSnackBar(
              Utils.customSnackBar(
                content: content,
              ),
            );
          }
          return null;
        }
      }

    }
    return user;

  }

  static Future<void> signOut({required BuildContext context}) async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      if (!kIsWeb) {
        await googleSignIn.signOut();
      }
      SharedPrefUtil.clear();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        Utils.customSnackBar(
          content: 'Error signing out. Try again.',
        ),
      );
    }
  }

  static Future<void> validateUser({required BuildContext context, required User? user}) async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

      final response = await http.get(
        Uri.parse(Environment().config.apiHost +
            '/user/' +
            user!.email! +
            '/validate'),
        headers: Utils.getHttpHeaders('application/json; charset=UTF-8', user.email!, null),
      );

      if (response.statusCode == 200) {
        bool isRegistered = jsonDecode(response.body)['is_registered'];
        if(isRegistered){
          return;
        }else{
          throw Exception("Not a registered user");
        }
      } else {
        throw Exception(response.body);
      }

  }


}