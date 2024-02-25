
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:t1d_buddy_ui/forms/user_profile.dart';
import 'package:t1d_buddy_ui/utils/common_utils.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';
import 'package:t1d_buddy_ui/utils/shared_preference_util.dart';

class UserService {
  static addUserProfileToSharedPref(String? email, User? user) async {
    String json = await getUserProfileJson(email, user);
    SharedPrefUtil.addUserProfileJson(json);
  }

  static Future<String> getUserProfileJson(String? email, User? user) async {
    try {
      final response = await http.get(
        Uri.parse(Environment().config.apiHost +
            '/user/email/' +
            email!),
        headers: Utils.getHttpHeaders('application/json; charset=UTF-8', email, await Utils.getIdToken(user)),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception('System error');
    }
  }

  static addPublicProfileToSharedPref(String? email, User? user) async {
    String json = await getPublicProfileJson(email, user);
    SharedPrefUtil.addPublicProfileJson(json);
  }

  static Future<String> getPublicProfileJson(String? email, User? user) async {
    try {
      final response = await http.get(
        Uri.parse(Environment().config.apiHost +
            '/user/' +
            email! +
            '/public-profile'),
        headers: Utils.getHttpHeaders('application/json; charset=UTF-8', user?.email, await Utils.getIdToken(user)),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception('System error');
    }
  }

  static Future<UserPublicProfile> getPublicProfile(String? email, User user) async {
    String json = await getPublicProfileJson(email, user);
    return UserPublicProfile.fromJson(jsonDecode(json));

  }

  static getProfilePhotoUrl(String? photoId) {
    if(photoId != null){
      return Environment().config.apiHost +
          '/image/' + photoId;
    }else{
      return null;
    }
  }

  static addUseTokenToSharedPref(User? user) async {
    Token token = await getUserTokenJson(user);
    SharedPrefUtil.addUserToken(token);
  }

  static Future<Token> getUserTokenJson(User? user) async {
    String? idToken = await user?.getIdToken(true);
    DateTime now = DateTime.now();
    return new Token(idToken!, now);
  }

  static updateNewFcmToken(UserProfile userProfile, String fcmToken) async {
    await updateFcmToken(userProfile, fcmToken);
    userProfile.fcmToken = fcmToken;
    SharedPrefUtil.addUserProfile(userProfile);
  }

  static Future<String> updateFcmToken(UserProfile userProfile, String fcmToken) async {
    try {
      final response = await http.put(
        Uri.parse(Environment().config.apiHost +
            '/user/' +
            userProfile.email! +
            '/fcm-token/' + fcmToken),
        headers: Utils.getHttpHeaders('application/json; charset=UTF-8', userProfile.email!, SharedPrefUtil.getUserToken().idToken),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception('System error');
    }
  }

}
