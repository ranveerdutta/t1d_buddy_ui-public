import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:t1d_buddy_ui/forms/user_profile.dart';
import 'package:t1d_buddy_ui/screens/common_widgets.dart';
import 'package:t1d_buddy_ui/screens/edit_profile.dart';
import 'package:t1d_buddy_ui/services/user_services.dart';
import 'package:t1d_buddy_ui/utils/shared_preference_util.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({Key? key, required User user, required String? email})
      : _loggedInUser = user,
        _email = email,
        super(key: key);

  final User _loggedInUser;
  
  final String? _email;

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  late User _loggedInUser;

  late UserProfile _loggedInUserProfile;
  
  late String _email;

  late UserPublicProfile _publicProfile;

  TextStyle textStyleHeader = TextStyle(color: Colors.blue, fontSize: 14, fontStyle: FontStyle.normal);

  TextStyle textStyleValue = TextStyle(color: Colors.blue, fontSize: 16, fontStyle: FontStyle.italic);

  @override
  void initState() {
    _loggedInUser = widget._loggedInUser;
    _email = widget._email!;
    _loggedInUserProfile = SharedPrefUtil.getUserProfile();
    super.initState();
  }

  Future<void> getPublicProfile() async {
    if(_loggedInUserProfile.email == _email){
      _publicProfile = SharedPrefUtil.getPublicProfile();
    }else{
      _publicProfile = await UserService.getPublicProfile(_email, _loggedInUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: FutureBuilder<void>(
        future: getPublicProfile(),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Text('loading...'));
          } else {
            if (snapshot.hasError)
              return Center(child: Text('Error: ${snapshot.error}'));
            else
              return SingleChildScrollView(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        SizedBox(height: 20),
                        new Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              new Flexible(
                                child: CommonWidget.getProfileImage(_publicProfile.photoId),
                              ),
                              SizedBox(width: 10.0),
                              new Flexible(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    Text(_publicProfile.firstName! + ' ' + (_publicProfile.lastName == null ? '' : _publicProfile.lastName!),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.blue, fontSize: 26)),
                                    Text('(' + _publicProfile.gender! + '/' + _publicProfile.age!.toString() + ' yrs)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.blue, fontSize: 20)),
                                    if(_publicProfile.relationship != 'Self')
                                      Text('*managed by ' + _publicProfile.relationship!,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.blue, fontSize: 12)),
                                ]
                              ))]),

                        SizedBox(height: 30.0),
                        getAboutInfo(),
                        SizedBox(height: 30.0),
                        Table(
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          border:TableBorder.all(width: 0.5,color: Colors.blue),
                          /*columnWidths: const <int, TableColumnWidth>{
                            0: FixedColumnWidth(64),
                          },*/
                          children: [
                            TableRow(
                                children: [
                                  Text('Diaversary', style: textStyleHeader, textAlign: TextAlign.center),
                                  diaversaryInfo(),
                                ]
                            ),
                            TableRow(
                              children: [
                                Text('Location', style: textStyleHeader, textAlign: TextAlign.center),
                                locationInfo(),
                              ]
                            ),
                            TableRow(
                                children: [
                                  Text(' Normal BG range ', style: textStyleHeader, textAlign: TextAlign.center),
                                  bgInfo(),
                                ]
                            ),
                            TableRow(
                                children: [
                                  Text(' Injection method ', style: textStyleHeader, textAlign: TextAlign.center),
                                  injectionMethodInfo(),
                                ]
                            ),
                            TableRow(
                                children: [
                                Text(' Accessories ', style: textStyleHeader, textAlign: TextAlign.center),
                                  accessoryInfo(),
                                ]
                            ),
                          ],
                        ),
                        SizedBox(height: 30,),
                        _loggedInUserProfile.email == _email ?
                        ElevatedButton(onPressed: () =>
                            showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                  Center( //child: Container(height: 600,
                                      child: AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5.0))),
                                        contentPadding: EdgeInsets.all(0.0),
                                        elevation: 5,
                                        content: Text('\n\n You can send an email to t1d.buddy.care@gmail.com from your registered email account to delete your profile',
                                            style: TextStyle(color: Colors.blue), textAlign: TextAlign.center),
                                        actions: [
                                          ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text('Ok', textAlign: TextAlign.center,))
                                        ],
                                      )),

                            ), child: Icon(Icons.delete, color: Colors.white))
                            :Container()

                      ],
              ));
          }}

    ),
    floatingActionButton: getEditButton());
  }


  Widget getEditButton(){
    if(_loggedInUserProfile.email == _email) {
      return FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => EditProfile(user: this._loggedInUser))),
        tooltip: 'Edit',
        icon: Icon(Icons.edit),
        label: Text('Edit profile'),
      );
    }else{
      return Container();
    }
  }

  Widget getAboutInfo(){
    TextStyle style = TextStyle(color: Colors.blue, fontSize: 18, fontStyle: FontStyle.italic);
    return
      _publicProfile.about!.isNotEmpty?
      Text('"' + _publicProfile.about! + '"', style: style, textAlign: TextAlign.center,)
          :
      Text('');
  }

  Widget locationInfo(){
    //TextStyle style = TextStyle(color: Colors.blue, fontSize: 16);
    return //_publicProfile.city == _loggedInUserProfile.city && _email != _loggedInUser.email ?
    Text(_publicProfile.city! + ', ' + _publicProfile.cityState! + ', '
        + _publicProfile.country! + '.',
        textAlign: TextAlign.center,
        style: textStyleValue)
        /*:
    Text(_publicProfile.city! + ', ' + _publicProfile.cityState! + ', '
        + _publicProfile.country! + '.',
        textAlign: TextAlign.center,
        style: style)*/;
  }

  Widget bgInfo(){
    //TextStyle style = TextStyle(color: Colors.blue, fontSize: 16);
    return //_publicProfile.normalBgMin == _loggedInUserProfile.normalBgMin
              //&& _publicProfile.normalBgMax == _loggedInUserProfile.normalBgMax  && _email != _loggedInUser.email ?
    Text(_publicProfile.normalBgMin!.toString() + '-'
        + _publicProfile.normalBgMax!.toString() + ' ' + _publicProfile.bgUnit!,
        textAlign: TextAlign.center,
        style: textStyleValue)
        /*:
    Text(_publicProfile.normalBgMin!.toString() + '-'
        + _publicProfile.normalBgMax!.toString() + ' ' + _publicProfile.bgUnit!,
        textAlign: TextAlign.center,
        style: style)*/;
  }

  Widget injectionMethodInfo(){
    //TextStyle style = TextStyle(color: Colors.blue, fontSize: 16);
    return //_publicProfile.sameInjectionType(_loggedInUserProfile.injectionType!) && _email != _loggedInUser.email ?
    Text(_publicProfile.injectionType!,
        textAlign: TextAlign.center,
        style: textStyleValue)
        /*:
    Text(_publicProfile.injectionType!,
        textAlign: TextAlign.center,
        style: style)*/;
  }

  Widget accessoryInfo(){
    //TextStyle style = TextStyle(color: Colors.blue, fontSize: 16);
    String accessoryInfo = '';
    if(_publicProfile.glucometerType!.isNotEmpty){
      if(_publicProfile.glucometerType == _loggedInUserProfile.glucometerType && _email != _loggedInUser.email){
        accessoryInfo = accessoryInfo + _publicProfile.glucometerType!;
      }else{
        accessoryInfo = accessoryInfo + _publicProfile.glucometerType!;
      }
      accessoryInfo = accessoryInfo + ', ';
    }

    if(_publicProfile.pumpType!.isNotEmpty){
      if(_publicProfile.pumpType == _loggedInUserProfile.pumpType && _email != _loggedInUser.email){
        accessoryInfo = accessoryInfo + _publicProfile.pumpType!;
      }else{
        accessoryInfo = accessoryInfo + _publicProfile.pumpType!;
      }
      accessoryInfo = accessoryInfo + ', ';
    }

    if(_publicProfile.onCgm!){
      if(_publicProfile.onCgm == _loggedInUserProfile.onCgm && _email != _loggedInUser.email){
        accessoryInfo = accessoryInfo + 'CGM';
      }else{
        accessoryInfo = accessoryInfo + 'CGM';
      }
    }

    return
      Text(accessoryInfo,
          textAlign: TextAlign.center,
          style: textStyleValue);

  }

  Widget diaversaryInfo(){
    return _publicProfile.diaversary.isNotEmpty ?
      Text(_publicProfile.diaversary,
          textAlign: TextAlign.center,
          style: textStyleValue)
        :
      Text('');
  }

}