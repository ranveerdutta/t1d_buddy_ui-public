

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:t1d_buddy_ui/forms/user_profile.dart';
import 'package:t1d_buddy_ui/main.dart';
import 'package:t1d_buddy_ui/screens/reminder.dart';
import 'package:t1d_buddy_ui/screens/user_info_screen.dart';
import 'package:t1d_buddy_ui/services/user_services.dart';
import 'package:t1d_buddy_ui/utils/authentication.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';

class CommonWidget{

  static AppBar getCommonHeader(BuildContext context, User _user, UserPublicProfile _publicProfile){
    return AppBar(
      elevation: 0,
      leading: InkWell(
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => UserInfoScreen(user: _user, email: _user.email)));
        },
        child: _publicProfile.photoId != null
            ? ClipOval(
          child: Material(
            child: CachedNetworkImage(
              imageUrl: Environment().config.apiHost +
                  '/image/' + _publicProfile.photoId!,
              fit: BoxFit.fitHeight,
              errorWidget: (context,url,error) => new Icon(Icons.question_mark),
            ),
          ),
        )
            : ClipOval(
          child: Material(
            child: Icon(
              Icons.person,
            ),
          ),
        ),
      ),

      //},
      //),
      title: Text('T1D-Buddy'),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.alarm, color: Colors.white),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => Reminder(user: _user))),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async{
            await Authentication.signOut(context: context);
            Navigator.of(context)
                .pushReplacement(_routeToSignInScreen());
          },
        ),
      ],
    );
  }

  static Route _routeToSignInScreen() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => MyApp(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(-1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  static Widget getProfileImage(String? photoId){
    return
      UserService.getProfilePhotoUrl(photoId) != null?
      ClipOval(
        child: Material(
            child: CachedNetworkImage(
              imageUrl: UserService.getProfilePhotoUrl(photoId),
              fit: BoxFit.fitHeight,
              placeholder: (context,url) => CircularProgressIndicator(),
              errorWidget: (context,url,error) => new Icon(Icons.error),
            )
        ),
      )
          : ClipOval(
        child: Material(
          child: Padding(padding: const EdgeInsets.all(16.0),
            child: Icon(Icons.person,size: 60),
          ),
        ),
      );
  }

  static CachedNetworkImage getImage(String imageId){
    String imageUrl = Environment().config.apiHost +
        '/image/' + imageId;
    try{
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.fitHeight,
        placeholder: (context,url) => CircularProgressIndicator(),
        errorWidget: (context,url,error) => new Icon(Icons.error_outline_rounded, color: Colors.red),
      );
    }catch(e){
      throw Exception("Error while downloading image");
    }

  }

}