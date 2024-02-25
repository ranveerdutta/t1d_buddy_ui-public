
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class FormValidator{
  static String? pincodeLengthValidator(String? pinCode) {
    if (pinCode!.length != 6) {
      return 'The Pincode must have 6 digits';
    }
    return null;
  }

  static String? onlyNumbers(String? str) {
    if(str!.isEmpty) return null;

    RegExp regExp = new RegExp(r'^[0-9.]+$');
    if (regExp.hasMatch(str)) {
      return null;
    } else {
      return 'Please enter only numbers';
    }
  }

  static String? greaterThanZero(TimeOfDay timeOfDay) {

    if (timeOfDay.minute > 0 || timeOfDay.hour > 0) {
      return null;
    } else {
      return 'Please enter duration';
    }
  }

  static String? onlyAlphanumeric(String? str) {
    if(str!.isEmpty) return null;

    RegExp regExp = new RegExp(r'^[0-9A-Za-z@_-]+$');
    if (regExp.hasMatch(str)) {
      return null;
    } else {
      return 'Avatar name can only have alphabets, number, @, _ or -';
    }
  }

  static String? validYoutubeUrl(String? str){
    if(str == null || str!.isEmpty) return null;

    if(YoutubePlayerController.convertUrlToId(str) != null){
      return null;
    }else{
      return "Invalid Youtube url";
    }
  }
}