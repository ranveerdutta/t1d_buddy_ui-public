import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:t1d_buddy_ui/forms/user_profile.dart';
import 'package:t1d_buddy_ui/utils/common_utils.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';
import 'package:t1d_buddy_ui/utils/shared_preference_util.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CgmConnection extends StatefulWidget {
  const CgmConnection({Key? key, required User user})
      : _user = user,
        super(key: key);

  final User _user;

  @override
  _CgmConnectionState createState() => _CgmConnectionState();
}

class _CgmConnectionState extends State<CgmConnection> {

  late User _user;
  late UserProfile _userProfile;
  late String _apiSecret;

  @override
  void initState() {
    super.initState();
    _user = widget._user;
    _userProfile = SharedPrefUtil.getUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("CGM connection"),
      ),
        body: FutureBuilder<void>(
            future: fetchApiSecret(),
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: Text('loading...'));
              } else {
                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));
                else
                  return glimpContent();
              }})
    );
  }

  Future<void> _copyWebsiteToClipboard() async {
    await Clipboard.setData(ClipboardData(text: Environment().config.nightscoutHost));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Website copied to clipboard'),
    ));
  }

  Future<void> _copyApiSecretToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _apiSecret));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('API secret copied to clipboard'),
    ));
  }

  Widget glimpContent(){
    return SingleChildScrollView(
        child: Column(
        children: <Widget>[
          SizedBox(height: 30,),
          Center( child: Text('Glimp Integration', style: TextStyle(fontSize: 20, color: Colors.blue, decoration: TextDecoration.underline))),
          SizedBox(height: 30,),
          Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                new Flexible(
                  child: Text('Website: ', style: TextStyle(color: Colors.blue),),
                ),
                new Flexible(
                  child: Text(Environment().config.nightscoutHost, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                new Flexible(
                    child: InkWell(child: Icon(Icons.copy), onTap: _copyWebsiteToClipboard)
                ),
              ]),
          SizedBox(height: 30,),
          Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                new Flexible(
                  child: Text('API Secret: ', style: TextStyle(color: Colors.blue),),
                ),
                new Flexible(
                  child: Text(_apiSecret, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                new Flexible(
                    child: InkWell(child: Icon(Icons.copy), onTap: _copyApiSecretToClipboard)
                ),
              ]),
          SizedBox(height: 50,),
          Text('Below steps will configure the Glimp app to send the BG readings to the T1D-Buddy app, everytime you scan you CGM sensor using Glimp', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center,),
          SizedBox(height: 30,),
          Center(
            child: Text('Open your Glimp app and go to', style: TextStyle(color: Colors.blue)),
          ),
          Center(
            child: Text('Settings -> Cloud', style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 10,),
          Text('Under the Nightscout header(marked in red), paste "Website" and "API Secret" values from the above section', style: TextStyle(color: Colors.blue), textAlign: TextAlign.center,),
          Text('then click on "Test connection"', style: TextStyle(color: Colors.blue), textAlign: TextAlign.center,),
          SizedBox(height: 30,),
          Image.asset('assets/images/glimp.jpg'),

        ]));
  }

  Future<void> fetchApiSecret() async {
    final response = await http.post(
      Uri.parse(Environment().config.apiHost +
          '/user/' + this._user.email! +
          '/api-secret'),
      headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this._user.email!, await Utils.getIdToken(_user)),
    );


    if (response.statusCode == 200) {
      _apiSecret = json.decode(response.body)['api_secret'];
    } else {
      throw Exception(response.body);
    }
  }

}