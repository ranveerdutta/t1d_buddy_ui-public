
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:t1d_buddy_ui/forms/user_profile.dart';

class SharedPrefUtil{

  static late SharedPreferences sharedPref;

  static Future initSharedPref() async {
    sharedPref = await SharedPreferences.getInstance();
  }

  static void addUserProfile(UserProfile userProfile){
    sharedPref.setString('user_profile', jsonEncode(userProfile));
  }

  static void addUserProfileJson(String userProfileJson){
    sharedPref.setString('user_profile', userProfileJson);
  }

  static UserProfile getUserProfile(){
    String? userProfile = sharedPref.getString('user_profile');
    return UserProfile.fromJson(jsonDecode(userProfile!));
  }

  static void addPublicProfile(UserPublicProfile publicProfile){
    sharedPref.setString('public_profile', jsonEncode(publicProfile));
  }

  static void addPublicProfileJson(String publicProfileJson){
    sharedPref.setString('public_profile', publicProfileJson);
  }

  static UserPublicProfile getPublicProfile(){
    String? publicProfileJson = sharedPref.getString('public_profile');
    return UserPublicProfile.fromJson(jsonDecode(publicProfileJson!));
  }

  static void addDeviceInfo(String deviceInfo){
    sharedPref.setString('device_info', deviceInfo);
  }

  static Map<String, dynamic> getDeviceInfo(){
    return jsonDecode(sharedPref.getString('device_info')!);
  }

  static void addToSharedPref(String key, String value){
    sharedPref.setString(key, value);
  }

  static void removeFromSharedPref(String key){
    sharedPref.remove(key);
  }

  static String? getFromSharedPref(String key){
    return sharedPref.getString(key);
  }

  static Token getUserToken(){
    String? token = sharedPref.getString('user_token');
    return Token.fromJson(jsonDecode(token!));
  }

  static void addUserToken(Token token){
    sharedPref.setString('user_token', jsonEncode(token));
  }

  static void clear(){
    sharedPref.clear();
  }
}