import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:t1d_buddy_ui/screens/loading_dialog.dart';
import 'package:t1d_buddy_ui/utils/common_utils.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';

class Reminder extends StatefulWidget {
  const Reminder({Key? key, required User user})
      : _user = user,
        super(key: key);

  final User _user;

  @override
  _ReminderState createState() => _ReminderState();
}

class _ReminderState extends State<Reminder> {

  late User _user;
  late List<ReminderType> reminderTypeList;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _typeAheadController = new TextEditingController();
  final TextEditingController _dateTimeController = new TextEditingController();
  final TextEditingController _moreDetailsController = new TextEditingController();
  late String _reminderTypeCode;
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late DateTime reminderDateTime;

  late List<ReminderDetail> _reminderDetailList;
  final List<Widget> reminderCards = [];


  void reloadPage() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => this.widget));
  }

  void resetForm(){
    _typeAheadController.clear();
    _dateTimeController.clear();
    _moreDetailsController.clear();
    selectedDate = DateTime.now();
    selectedTime = TimeOfDay.now();
    reminderDateTime = DateTime.now();
  }

  @override
  void initState() {
    super.initState();
    _user = widget._user;
    resetForm();
  }

  @override
  void dispose() {
    super.dispose();
    _typeAheadController.dispose();
    _dateTimeController.dispose();
    _moreDetailsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Reminders"),
        ),
        body: FutureBuilder<void>(
            future: fetchReminderData(),
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: Text('loading...'));
              } else {
                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));
                else
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        addReminderWidget(),
                        SizedBox(height: 20,),
                        reminderCards.length > 0 ? Text('Pending reminders:', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500, fontSize: 18),) : Text(''),
                        SizedBox(height: 10,),
                        Column(
                          children: reminderCards,
                        )
                      ]
                    )
                  );
              }
            }));
  }


  Widget addReminderWidget(){
    return new Card(
        elevation: 10,
        child: Form(
          key: this._formKey,
          child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Column(
              children: <Widget>[
                TypeAheadFormField(
                  textFieldConfiguration: TextFieldConfiguration(
                      controller: this._typeAheadController,
                      decoration: InputDecoration(
                          labelText: 'Reminder type*'
                      )
                  ),
                  suggestionsCallback: (pattern) {
                    this._reminderTypeCode = '';
                    return reminderTypeList.where((reminderType) => reminderType.name.toLowerCase().contains(pattern.toLowerCase())).toList();
                  },
                  itemBuilder: (context, ReminderType suggestion) {
                    return ListTile(
                      title: Text(suggestion==null ? '' : suggestion.name),
                    );
                  },
                  transitionBuilder: (context, suggestionsBox, controller) {
                    return suggestionsBox;
                  },
                  onSuggestionSelected: (ReminderType suggestion) {
                    this._typeAheadController.text = suggestion.name;
                    this._reminderTypeCode = suggestion.code;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty || this._reminderTypeCode.isEmpty) {
                      return 'Please select a valid reminder type';
                    }
                    return null;
                  },
                ),
                //SizedBox(height: 10.0,),
                GestureDetector(
                  onTap: () => _selectDateTime(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      onSaved: (val) {
                        //task.date = selectedDate;
                      },
                      controller: _dateTimeController,
                      decoration: InputDecoration(
                        labelText: "When*",
                        icon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (value!.isEmpty)
                          return "Please enter a valid date";
                        return null;
                      },
                    ),
                  ),
                ),
                //SizedBox(height: 10.0,),
                TextFormField(
                  controller: _moreDetailsController,
                  maxLength: 30,
                  decoration: InputDecoration(
                    labelText: 'More details',
                  ),
                ),
                //SizedBox(height: 10.0,),
                ElevatedButton(
                  onPressed: () async {
                    if (this._formKey.currentState!.validate()) {
                      this._formKey.currentState!.save();
                      LoadingDialog.show(context);
                      bool isSuccess = await createNewReminder();
                      LoadingDialog.hide(context);
                      if(isSuccess){
                        reloadPage();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Reminder created', style: TextStyle(color: Colors.white))));
                      }else{
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error while creating reminder, try again.', style: TextStyle(color: Colors.red))));
                      }
                    }
                  },
                  child: Text('Add new reminder'),
                ),
              ],
            ),
          )
        )
    );
  }


  Future _selectDateTime(BuildContext context) async {
    final date = await _selectDate(context);
    if (date == null) return;

    final time = await _selectTime(context);

    if (time == null) return;

    reminderDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    _dateTimeController.text = DateFormat('dd-MM-yyyy hh:mm a').format(reminderDateTime);
  }

  Future<DateTime> _selectDate(BuildContext context) async {
    final selected = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100));

    if (selected != null && selected != selectedDate) {
      selectedDate = selected;
    }
    return selectedDate;
  }

  Future<TimeOfDay> _selectTime(BuildContext context) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (selected != null && selected != selectedTime) {
      selectedTime = selected;
    }
    return selectedTime;
  }

  Future<void> fetchReminderData() async {
    await fetchReminderTypeList();
    await fetchReminderDetailList();
  }

  Future<void> fetchReminderTypeList() async {
    final response = await http.get(
      Uri.parse(Environment().config.apiHost +
          '/reminder-type'),
      headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this._user.email!, await Utils.getIdToken(_user)),
    );


    if (response.statusCode == 200) {
      List t = json.decode(response.body);
      reminderTypeList = t.map((item) => ReminderType.fromJson(item)).toList();
    } else {
      throw Exception(response.body);
    }
  }

  Future<void> fetchReminderDetailList() async {
    final response = await http.get(
      Uri.parse(Environment().config.apiHost +
          '/user/' + this._user.email! + '/reminder/pending'),
      headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this._user.email!, await Utils.getIdToken(_user)),
    );


    if (response.statusCode == 200) {
      List t = json.decode(response.body);
      _reminderDetailList = t.map((item) => ReminderDetail.fromJson(item)).toList();
      reminderCards.clear();
      List<Widget> generatedCards = new List.generate(_reminderDetailList.length, (i)=>new ReminderCard(reminderDetailList: _reminderDetailList, index: i, user: _user, reloadPage: reloadPage)).toList();
      reminderCards.addAll(generatedCards);
    } else {
      throw Exception(response.body);
    }
  }

  Future<bool> createNewReminder() async {
    try{
      Map<String, dynamic> reqBody = {
        'reminder_type': {
          'code': _reminderTypeCode
        },
        'reminder_time': reminderDateTime.toUtc().toIso8601String(),
        'more_details': _moreDetailsController.text,
      };
      String inputJson = JsonEncoder.withIndent('    ').convert(reqBody);
      final response = await http.post(
          Uri.parse(Environment().config.apiHost + '/user/' + _user.email! + '/reminder'),
          headers: Utils.getHttpHeaders('application/json; charset=UTF-8', _user.email, await Utils.getIdToken(_user)),
          body: inputJson
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    }catch(e){
      return false;
    }

  }
}


class ReminderType{

  late String code;

  late String name;

  ReminderType(this.code, this.name);

  Map<String, dynamic> toJson() => {
    'code' : code,
    'name': name
  };

  ReminderType.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    name = json['name'];
  }
}

class ReminderDetail{

  late int reminderId;

  late String code;

  late String name;

  late String status;

  late String moreDetails;

  late DateTime reminderTime;

  ReminderDetail.fromJson(Map<String, dynamic> json) {
    reminderId = json['id'];
    code = json['reminder_type']['code'];
    name = json['reminder_type']['name'];
    status = json['status'];
    moreDetails = json['more_details'];
    reminderTime = DateTime.parse(json['reminder_time']);
  }
}

class ReminderCard extends StatelessWidget {

  const ReminderCard({Key? key, required List<ReminderDetail> reminderDetailList, required int index, required User user, required Function reloadPage})
      : _reminderDetailList = reminderDetailList,
        _index = index,
        _user = user,
        _reloadPage = reloadPage,
        super(key: key);

  final List<ReminderDetail> _reminderDetailList;
  final int _index;
  final User _user;
  final Function _reloadPage;
  
  @override
  Widget build(BuildContext context) {
    return new Card(
      elevation: 10,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.alarm, color: _reminderDetailList[_index].reminderTime.isBefore(DateTime.now()) ? Colors.red : Colors.blue),
              title: Text(this._reminderDetailList[_index].name + getIfNotEmpty(this._reminderDetailList[_index].moreDetails)),
              subtitle: Text('Remind at: ' + DateFormat('dd-MM-yyyy hh:mm a').format(_reminderDetailList[_index].reminderTime.toLocal())),
              //trailing: Text(_reminderDetailList[_index].status, style: TextStyle(color: Colors.blue),),
              trailing: ElevatedButton(
                child: Text('Done'),
                style: ButtonStyle(backgroundColor: _reminderDetailList[_index].reminderTime.isBefore(DateTime.now()) ? MaterialStateProperty.all(Colors.red) : MaterialStateProperty.all(Colors.blue)),
                onPressed: () async {
                  LoadingDialog.show(context);
                  bool isSuccess = await markReminderDone(_reminderDetailList[_index].reminderId);
                  LoadingDialog.hide(context);
                  if(isSuccess){
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Reminder marked as done.', style: TextStyle(color: Colors.white))));
                  }else{
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error while marking reminder as done.', style: TextStyle(color: Colors.red))));
                  }
                  this._reloadPage();
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String getIfNotEmpty(String str){
    if(str.isEmpty || str == 'null') return '';
    else return ' (' + str + ')';
  }

  Future<bool> markReminderDone(int reminderId) async {
    try{
      Map<String, dynamic> reqBody = {
      };
      String inputJson = JsonEncoder.withIndent('    ').convert(reqBody);
      final response = await http.put(
          Uri.parse(Environment().config.apiHost + '/user/' + _user.email! + '/reminder/' + reminderId.toString() + '/status/Done'),
          headers: Utils.getHttpHeaders('application/json; charset=UTF-8', _user.email, await Utils.getIdToken(_user)),
          body: inputJson
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    }catch(e){
      return false;
    }

  }
  
}
