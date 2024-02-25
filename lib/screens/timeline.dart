import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:t1d_buddy_ui/forms/user_log.dart';
import 'package:t1d_buddy_ui/forms/user_profile.dart';
import 'package:t1d_buddy_ui/screens/add_log.dart';
import 'package:t1d_buddy_ui/screens/bg_line_chart.dart';
import 'package:t1d_buddy_ui/screens/home.dart';
import 'package:t1d_buddy_ui/utils/common_utils.dart';
import 'package:t1d_buddy_ui/utils/enumerations.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';
import 'package:t1d_buddy_ui/utils/shared_preference_util.dart';

enum TimelineFilter { daily, weekly }

class Timeline extends StatefulWidget {
  const Timeline({Key? key, required User user})
      : _user = user,
        super(key: key);

  final User _user;

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  late User _user;

  late UserProfile _userProfile;

  DateTime _endTime = DateTime.now();

  int _durationInHours = 24;

  late List<UserLog> _bgLogList;

  late List<UserLog> _insulinLogList;

  late List<UserLog> _exerciseLogList;

  late List<UserLog> _accessoryLogList;

  late List<BasalRate> _basalRateList;

  double _currentBasalRate = 0.0;

  late UserLogStat _userLogStat;

  late TimelineFilter filter;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder<void>(
          future: fetchLogData(_user.email, _endTime,
              _durationInHours),
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            _userProfile = SharedPrefUtil.getUserProfile();
            DateFormat dateFormat = DateFormat("dd-MMM-yy hh:mm aaa");
            String endTime = dateFormat.format(_endTime);
            String startTime = dateFormat.format(
                _endTime.subtract(Duration(hours: this._durationInHours)));
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: Text('loading...'));
            } else {
              if (snapshot.hasError)
                return Center(child: Text('Error: ${snapshot.error}'));
              else
                return SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          new Radio<TimelineFilter>(
                            fillColor: MaterialStateColor.resolveWith((states) => Colors.blue),
                            focusColor: MaterialStateColor.resolveWith((states) => Colors.blue),
                            value: TimelineFilter.daily,
                            groupValue: filter,
                            autofocus: true,
                            onChanged: (TimelineFilter? value) {
                              setState(() {
                                filter = value!;
                                _durationInHours = 24;
                              });
                            },
                          ),
                          new Text(
                            'Daily',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          SizedBox(width: 100,),
                          new Radio<TimelineFilter>(
                            fillColor: MaterialStateColor.resolveWith((states) => Colors.blue),
                            focusColor: MaterialStateColor.resolveWith((states) => Colors.blue),
                            value: TimelineFilter.weekly,
                            groupValue: filter,
                            onChanged: (TimelineFilter? value) {
                              setState(() {
                                filter = value!;
                                _durationInHours = 24 * 7;
                              });
                            },
                          ),
                          new Text(
                            'Weekly',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ],
                      ),
                      new Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            new Flexible(
                              child: IconButton(
                                icon: Icon(Icons.arrow_back_rounded),
                                iconSize: 50,
                                color: Colors.blue,
                                onPressed: () {
                                  setState(() {
                                    this._endTime = _endTime.subtract(
                                        Duration(hours: this._durationInHours));
                                  });
                                },
                              ),
                            ),
                            new Flexible(
                              child: IconButton(
                                icon: Icon(Icons.refresh),
                                iconSize: 40,
                                color: Colors.blue,
                                onPressed: () {
                                  setState(() {
                                    _endTime = DateTime.now();
                                  });
                                },
                              ),
                            ),
                            new Flexible(
                              child: IconButton(
                                icon: Icon(Icons.arrow_forward_rounded),
                                iconSize: 50,
                                color: Colors.blue,
                                onPressed: () {
                                  setState(() {
                                    this._endTime = _endTime.add(
                                        Duration(hours: this._durationInHours));
                                  });
                                },
                              ),
                            ),
                          ]),
                      Text(
                        '$startTime  To  $endTime',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight:
                        FontWeight.bold,
                            color: Colors.blue,
                            decoration: TextDecoration.underline),
                      ),
                      SizedBox(height: 18),
                      BgLineChart(_bgLogList, _endTime.subtract(
                          Duration(hours: this._durationInHours)), _endTime, filter,
                          this._userProfile),
                      SizedBox(height: 18),
                      if(_bgLogList.length > 0 && _bgLogList[0].rawBg != 0.0) Text(
                        '*BG values inside brackets are raw CGM readings without calibration', style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                      if(_bgLogList.length > 0) Container(
                          margin: const EdgeInsets.symmetric(vertical: 20.0),
                          height: 100.0,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: bgLogCards(),
                          )),
                      if(_insulinLogList.length > 0) Container(
                          margin: const EdgeInsets.symmetric(vertical: 20.0),
                          height: 100.0,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: insulinLogCards(),
                          )),
                      if(_basalRateList.length > 0) Container(
                          margin: const EdgeInsets.symmetric(vertical: 20.0),
                          height: 100.0,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: basalRateLogLogCards(),
                          )),
                      if(_exerciseLogList.length > 0) Container(
                          margin: const EdgeInsets.symmetric(vertical: 20.0),
                          height: 100.0,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: exerciseLogCards(),
                          )),
                      if(_accessoryLogList.length > 0) Container(
                          margin: const EdgeInsets.symmetric(vertical: 20.0),
                          height: 100.0,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: accessoryLogCards(),
                          )),
                    ],
                  ),
                );
            }
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () =>
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AddLog(user: _user))),
          tooltip: 'Add',
          isExtended: true,
          icon: Icon(Icons.add),
          label: Text('Add'),
        ));
  }

  Future<void> fetchLogData(String? email, DateTime endDate,
      int durationInHours) async {
    DateTime startDate = endDate.subtract(Duration(hours: durationInHours));
    final response = await http.get(
        Uri.parse(Environment().config.apiHost +
            '/user/' +
            email! +
            '/log?start_date=' +
            startDate.toUtc().toIso8601String() +
            '&end_date=' +
            endDate.toUtc().toIso8601String()),
        headers: Utils.getHttpHeaders('application/json; charset=UTF-8', email, await Utils.getIdToken(_user))
    );

    if (response.statusCode == 200) {
      List t = json.decode(response.body)['bg_log'];
      _bgLogList = t.map((item) => UserLog.fromBgJson(item)).toList();

      t = json.decode(response.body)['insulin_log'];
      _insulinLogList = t.map((item) => UserLog.fromInsulinJson(item)).toList();

      t = json.decode(response.body)['exercise_log'];
      _exerciseLogList =
          t.map((item) => UserLog.fromExerciseJson(item)).toList();

      t = json.decode(response.body)['accessory_log'];
      _accessoryLogList =
          t.map((item) => UserLog.fromAccessoryJson(item)).toList();

      t = json.decode(response.body)['basal_rate_log'];
      _basalRateList =
          t.map((item) => BasalRate.fromJson(item)).toList();

      _userLogStat = UserLogStat.fromJson(json.decode(response.body));
    } else {
      throw Exception(response.body);
    }
  }

  @override
  void initState() {
    super.initState();
    _user = widget._user;
    filter = TimelineFilter.daily;
  }

  List<LogDetailsCard> bgLogCards(){
    List<LogDetailsCard> bgLogCardList = [];
    bgLogCardList.add(
        LogDetailsCard(
          title: 'Within range: ' + _userLogStat.bgInRange + '%',
          subTitle: 'Average: ' + _userLogStat.bgReadingAvg + ' ' +  _userProfile.bgUnit!,
          icon: Icon(Icons.bloodtype, color: Colors.red),
          logTime: DateTime.now(),
          logId: -1,
          logType: 'BG',
          user: _user,

    ));

    bgLogCardList.addAll(new List.generate(
        _bgLogList.length, (i) =>
    new LogDetailsCard(
        title: _bgLogList[i].bgValue.toString() + ' ' +
            _bgLogList[i].bgUnit.toString() + (_bgLogList[i].rawBg == 0.0 ? '' : ' (' + _bgLogList[i].rawBg.toString() + ') '),
        subTitle: Utils.convertDateTimeString(
            _bgLogList[i].logTime),
        icon: Icon(Icons.bloodtype, color: Colors.red),
        logId: _bgLogList[i].logId,
        logType: _bgLogList[i].logType,
        logTime: _bgLogList[i].logTime,
        user: _user)).toList());
    return bgLogCardList;

  }

  List<LogDetailsCard> insulinLogCards(){
    List<LogDetailsCard> insulinLogCardList = [];
    insulinLogCardList.add(
        LogDetailsCard(
          title: 'Bolus units: ' + _userLogStat.totalBolus,
          subTitle: 'Basal units: ' + _userLogStat.totalBasal,
          icon: Icon(Icons.medical_services, color: Colors.black),
          logTime: DateTime.now(),
          logId: -1,
          logType: 'BG',
          user: _user,

        ));

    insulinLogCardList.addAll(new List.generate(_insulinLogList
        .length, (i) =>
    new LogDetailsCard(
        title: _insulinLogList[i].insulinAmt
            .toString() + ' ' +
            _insulinLogList[i].insulinType.toString() +
            ' ' + _insulinLogList[i].insulinDoseType
            .toString(),
        subTitle: Utils.convertDateTimeString(
            _insulinLogList[i].logTime),
        icon: Icon(Icons.medical_services,
            color: Colors.black),
        logId: _insulinLogList[i].logId,
        logType: _insulinLogList[i].logType,
        logTime: _insulinLogList[i].logTime,
        user: _user)).toList());
    return insulinLogCardList;

  }

  List<LogDetailsCard> exerciseLogCards(){
    List<LogDetailsCard> exerciseLogCardList = [];
    exerciseLogCardList.add(
        LogDetailsCard(
          title: 'Total Duration',
          subTitle: _userLogStat.exerciseDurationInMins  + ' mins',
          icon: Icon(Icons.sports_gymnastics, color: Colors.black),
          logTime: DateTime.now(),
          logId: -1,
          logType: 'BG',
          user: _user,

        ));

    exerciseLogCardList.addAll(new List.generate(_exerciseLogList
        .length, (i) =>
    new LogDetailsCard(
        title: _exerciseLogList[i].exercise.toString() +
            '\n for '
            + _exerciseLogList[i].duration.toString() +
            ' mins',
        subTitle: Utils.convertDateTimeString(
            _exerciseLogList[i].logTime),
        icon: Icon(Icons.sports_gymnastics,
            color: Colors.black),
        logId: _exerciseLogList[i].logId,
        logType: _exerciseLogList[i].logType,
        logTime: _exerciseLogList[i].logTime,
        user: _user)).toList());
    return exerciseLogCardList;

  }

  List<LogDetailsCard> accessoryLogCards(){
    List<LogDetailsCard> accessoryLogCardList = [];
    accessoryLogCardList.add(
        LogDetailsCard(
          title: 'Accessories changed',
          subTitle: _accessoryLogList.length.toString(),
          icon: Icon(Icons.settings, color: Colors.black),
          logTime: DateTime.now(),
          logId: -1,
          logType: 'BG',
          user: _user,

        ));

    accessoryLogCardList.addAll(new List.generate(_accessoryLogList
        .length, (i) =>
    new LogDetailsCard(
        title: _accessoryLogList[i].accessoryType
            .toString(),
        subTitle: Utils.convertDateTimeString(
            _accessoryLogList[i].logTime),
        icon: Icon(Icons.settings, color: Colors.black),
        logId: _accessoryLogList[i].logId,
        logType: _accessoryLogList[i].logType,
        logTime: _accessoryLogList[i].logTime,
        user: _user)).toList());
    return accessoryLogCardList;

  }

  List<LogDetailsCard> basalRateLogLogCards(){
    List<LogDetailsCard> basalRateLogCardList = [];

    TimeOfDay currentTime = TimeOfDay.now();
    int currentMin = currentTime.hour * 60 + currentTime.minute;
    for(BasalRate basalRate in _basalRateList){
      int startMin = basalRate.startTime.hour * 60 + basalRate.startTime.minute;
      int endMin = (basalRate.endTime.hour == 0 ? 24 : basalRate.endTime.hour) * 60 + basalRate.endTime.minute;
      if( currentMin >= startMin && currentMin < endMin){
        this._currentBasalRate = basalRate.quantity;
        break;
      }
    }

    basalRateLogCardList.add(
        LogDetailsCard(
          title: '24 hrs Pump Basal: ' + _userLogStat.totalPumpBasal  + ' units',
          subTitle: 'Current basal rate: ' + _currentBasalRate.toString() + ' units/hr',
          icon: Icon(Icons.medical_services, color: Colors.black),
          logTime: DateTime.now(),
          logId: -1,
          logType: 'Pump basal',
          user: _user,

        ));

    basalRateLogCardList.addAll(new List.generate(_basalRateList
        .length, (i) =>
    new LogDetailsCard(
        title: _basalRateList[i].quantity.toString() + ' ' + "units/hr",
        subTitle: _basalRateList[i].getTime(),
        icon: Icon(Icons.medical_services, color: Colors.black),
        logId: -2,
        logType: 'Pump basal',
        logTime: DateTime.now(),
        user: _user)).toList());
    return basalRateLogCardList;

  }


}

class LogDetailsCard extends StatelessWidget {

  const LogDetailsCard(
      {required this.title, required this.subTitle, required this.icon, required this.logId, required this.logType, required this.logTime, required this.user});

  final String title;
  final String subTitle;
  final Icon icon;
  final int logId;
  final String logType;
  final DateTime logTime;
  final User user;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      color: logId == -1 ? Theme
          .of(context)
          .colorScheme
          .surfaceVariant : Theme
          .of(context)
          .colorScheme
          .surfaceVariant,
      child: SizedBox(
        width: logId == -1 ? 270 : 150,
        height: logId == -1 ? 180 : 180,
        child: Column(
            children: <Widget>[
              ListTile(
                leading: logId == -1 ? icon : null,
                title: Text(this.title, style: TextStyle(color: logId == -1 ? Colors.blueGrey : Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                subtitle: Text(this.subTitle, style: TextStyle(color: logId == -1 ? Colors.blueGrey : Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                onLongPress: () =>
                {
                  logId < 0 ? null: showAlertDialog(context, logId, logType, logTime, user)
                },
              ),
              //const SizedBox(height: 10),
            ]),
      ),
    );
  }

  showAlertDialog(BuildContext context, int logId, String logType, DateTime logTime, User user) async{

    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () async {
        await deleteLog(logId, logType, logTime, user.email);
            Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => Home(user: user)));
        },
    );

    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed: () { Navigator.of(context).pop();},
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Confirmation"),
      content: Text("Delete this log?"),
      actions: [
        cancelButton,
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }


  Future<void> deleteLog(int logId, String logType, DateTime logTime, String? email) async {
    final response = await http.delete(
      Uri.parse(Environment().config.apiHost +
          '/user/' +
          email! +
          '/log'),
      headers: Utils.getHttpHeaders('application/json; charset=UTF-8', email, await Utils.getIdToken(this.user)),
        body: JsonEncoder.withIndent('    ').convert(
                          <String, dynamic>{
                            'log_id': logId,
                            'log_time': logTime.toUtc().toIso8601String(),
                            'log_type': getLogType(logType)
                          }
        )
    );

    if (response.statusCode == 200) {
      return null;
    } else {
      throw Exception(response.body);
    }
  }

  String getLogType(String? name){
    if(name == LogType.BG.name) return 'BG';
    else if(name == LogType.BOLUS.name) return 'INSULIN';
    else if(name == LogType.BASAL.name) return 'INSULIN';
    else if(name == LogType.EXERCISE.name) return 'EXERCISE';
    else if(name == LogType.ACCESSORY_CHANGE.name) return 'ACCESSORY_CHANGE';

    throw Exception('wrong log type');
  }


}

