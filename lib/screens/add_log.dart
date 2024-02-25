import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:t1d_buddy_ui/forms/user_log.dart';
import 'package:t1d_buddy_ui/forms/user_profile.dart';
import 'package:t1d_buddy_ui/screens/home.dart';
import 'package:t1d_buddy_ui/screens/loading_dialog.dart';
import 'package:t1d_buddy_ui/utils/common_utils.dart';
import 'package:t1d_buddy_ui/utils/enumerations.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';
import 'package:t1d_buddy_ui/utils/shared_preference_util.dart';
import 'package:http/http.dart' as http;

class AddLog extends StatefulWidget {
  const AddLog({Key? key, required User user})
      : _user = user,
        super(key: key);

  final User _user;

  @override
  _AddLogState createState() => _AddLogState();
}

class _AddLogState extends State<AddLog> {
  late User _user;

  late UserProfile _userProfile;

  String? _logType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Add log"),
        ),
        body: BlocProvider(
            create: (context) => UserLogFormBloc(_user),
            child: Builder(builder: (context) {
              final formBloc = BlocProvider.of<UserLogFormBloc>(context);
              formBloc.email.updateInitialValue(_user.email!);
              formBloc.bgUnit.updateInitialValue(_userProfile.bgUnit);
              formBloc.insulinType.updateInitialValue(_userProfile.insulinType);
              _logType = formBloc.logType.value;
              return Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: InputDecorationTheme(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  child: Scaffold(
                      body: FormBlocListener<UserLogFormBloc, String, String>(
                          onSubmitting: (context, state) {
                            LoadingDialog.show(context);
                          },
                          onSuccess: (context, state) {
                            LoadingDialog.hide(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(state.successResponse!)));
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (_) => Home(user: _user)));
                          },
                          onFailure: (context, state) {
                            LoadingDialog.hide(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(state.failureResponse!)));
                          },
                          child: SingleChildScrollView(
                              physics: ClampingScrollPhysics(),
                              child: Padding(
                                  padding: const EdgeInsets.all(40.0),
                                  child: Column(children: <Widget>[
                                    RadioButtonGroupFieldBlocBuilder<String>(
                                        selectFieldBloc: formBloc.logType,
                                        canDeselect: false,
                                        numberOfItemPerRow: 2,
                                        decoration: InputDecoration(
                                          labelText: 'Log type*',
                                          prefixIcon: SizedBox(),
                                        ),
                                        itemBuilder: (context, item) =>
                                            FieldItem(child: Text(item),
                                                onTap: () => {
                                                  setState(() {
                                                    _logType = item;
                                                    if(_logType == LogType.PUMP_BASAL.name){
                                                      fetchCurrentBasalRate(formBloc);
                                                    }
                                                  })
                                                })),
                                    Text("*BG: Blood glucose/sugar level.                                         ", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 10)),
                                    Text("*Bolus: Quick acting insulin. Usually taken before meal.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 10),),
                                    Text("*Basal: Long acting insulin.                                                   ", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 10),),
                                    SizedBox(height: 20.0),
                                    DateTimeFieldBlocBuilder(
                                      dateTimeFieldBloc: formBloc.logTime,
                                      canSelectTime: true,
                                      format: DateFormat('dd-MM-yyyy  hh:mm a'),
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now(),
                                      isEnabled: _logType == LogType.PUMP_BASAL.name? false:true,
                                      decoration: InputDecoration(
                                        labelText: 'Log time*',
                                        prefixIcon: Icon(Icons.date_range),
                                      ),
                                    ),
                                    Visibility(
                                      visible: _logType == LogType.BG.name,
                                        child: new Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              new Flexible(
                                                child: TextFieldBlocBuilder(
                                                  textFieldBloc: formBloc.bgValue,
                                                  autofocus: true,
                                                  keyboardType:
                                                  TextInputType.number,
                                                  decoration: InputDecoration(
                                                    labelText: 'BG*',
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 20.0),
                                              new Flexible(
                                                child: DropdownFieldBlocBuilder<
                                                    String>(
                                                    selectFieldBloc:
                                                    formBloc.bgUnit,
                                                    decoration: InputDecoration(
                                                      labelText: 'Unit*',
                                                    ),
                                                    itemBuilder: (context, item) =>
                                                        FieldItem(
                                                            child: Text(item))),
                                              )
                                            ]),
                                    ),
                                  Visibility(
                                      visible: _logType == LogType.BOLUS.name || _logType == LogType.BASAL.name,
                                      child: new Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            new Flexible(
                                              child: TextFieldBlocBuilder(
                                                textFieldBloc: formBloc.insulinAmt,
                                                autofocus: true,
                                                keyboardType:
                                                TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText: 'Insulin*',
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 20.0),
                                            new Flexible(
                                              child: DropdownFieldBlocBuilder<
                                                  String>(
                                                  selectFieldBloc:
                                                  formBloc.insulinType,
                                                  decoration: InputDecoration(
                                                    labelText: 'Type*',
                                                  ),
                                                  itemBuilder: (context, item) =>
                                                      FieldItem(
                                                          child: Text(item))),
                                            )
                                          ]),
                                  ),
                                    Visibility(
                                      visible: _logType == LogType.EXERCISE.name,
                                      child: Column(
                                          children: <Widget>[
                                            RadioButtonGroupFieldBlocBuilder<String>(
                                                selectFieldBloc: formBloc.exercise,
                                                canDeselect: false,
                                                numberOfItemPerRow: 2,
                                                decoration: InputDecoration(
                                                  labelText: 'Exercise*',
                                                  prefixIcon: SizedBox(),
                                                ),
                                                itemBuilder: (context, item) =>
                                                    FieldItem(child: Text(item))),
                                            TextFieldBlocBuilder(
                                              textFieldBloc: formBloc.duration,
                                              keyboardType:
                                              TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText: 'Duration(minutes)*',
                                              ),
                                              maxLength: 3,
                                            ),
                                            TextFieldBlocBuilder(
                                              textFieldBloc: formBloc.moreDetails,
                                              textCapitalization: TextCapitalization.words,
                                              decoration: InputDecoration(
                                                labelText: 'More details',
                                              ),
                                              maxLength: 20,
                                            ),
                                          ]
                                      )

                                    ),
                                  Visibility(
                                      visible: _logType == LogType.ACCESSORY_CHANGE.name,
                                    child: Column(
                                        children: <Widget>[
                                          RadioButtonGroupFieldBlocBuilder<String?>(
                                              selectFieldBloc: formBloc.accessoryType,
                                              canDeselect: false,
                                              numberOfItemPerRow: 2,
                                              decoration: InputDecoration(
                                                labelText: 'Accessory*',
                                                prefixIcon: SizedBox(),
                                              ),
                                              itemBuilder: (context, item) =>
                                                  FieldItem(child: Text(item!))),

                                          DateTimeFieldBlocBuilder(
                                            dateTimeFieldBloc: formBloc.accessoryReminder,
                                            canSelectTime: true,
                                            format: DateFormat('dd-MM-yyyy  hh:mm a'),
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime(2100),
                                            decoration: InputDecoration(
                                              labelText: 'Remind to change at',
                                              prefixIcon: Icon(Icons.date_range),
                                              helperText: '*Please provide a future date otherwise the reminder will not be created',
                                              helperMaxLines: 2
                                            ),
                                          ),

                                          ])

                                  ),
                                    Visibility(
                                      visible: _logType == LogType.PUMP_BASAL.name,
                                      child: getBasalRateWidget(formBloc),
                                    ),


                                    ElevatedButton(
                                      onPressed: formBloc.submit,
                                      child: Text('Submit'),
                                    ),
                                  ]))))));
            })));
  }

  @override
  void initState() {
    super.initState();
    _user = widget._user;
    _userProfile = SharedPrefUtil.getUserProfile();
  }

  Widget getBasalRateWidget(UserLogFormBloc formBloc){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("*Updating basal rate will remove the existing basal rate effective now for all the calculations.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),),
        SizedBox(height: 10),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new Flexible(
                child: Text("00:00 Hrs to 02:00 Hrs: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
              ),
              new Flexible(
                child: TextFieldBlocBuilder(
                  textFieldBloc: formBloc.basalRate00to02,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Units/Hour*',
                  ),
                ),
              ),
            ]),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new Flexible(
                child: Text("02:00 Hrs to 04:00 Hrs: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
              ),
              new Flexible(
                child: TextFieldBlocBuilder(
                  textFieldBloc: formBloc.basalRate02to04,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Units/Hour*',
                  ),
                ),
              ),
            ]),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new Flexible(
                child: Text("04:00 Hrs to 06:00 Hrs: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
              ),
              new Flexible(
                child: TextFieldBlocBuilder(
                  textFieldBloc: formBloc.basalRate04to06,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Units/Hour*',
                  ),
                ),
              ),
            ]),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new Flexible(
                child: Text("06:00 Hrs to 08:00 Hrs: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
              ),
              new Flexible(
                child: TextFieldBlocBuilder(
                  textFieldBloc: formBloc.basalRate06to08,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Units/Hour*',
                  ),
                ),
              ),
            ]),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new Flexible(
                child: Text("08:00 Hrs to 10:00 Hrs: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
              ),
              new Flexible(
                child: TextFieldBlocBuilder(
                  textFieldBloc: formBloc.basalRate08to10,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Units/Hour*',
                  ),
                ),
              ),
            ]),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new Flexible(
                child: Text("10:00 Hrs to 12:00 Hrs: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
              ),
              new Flexible(
                child: TextFieldBlocBuilder(
                  textFieldBloc: formBloc.basalRate10to12,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Units/Hour*',
                  ),
                ),
              ),
            ]),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new Flexible(
                child: Text("12:00 Hrs to 14:00 Hrs: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
              ),
              new Flexible(
                child: TextFieldBlocBuilder(
                  textFieldBloc: formBloc.basalRate12to14,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Units/Hour*',
                  ),
                ),
              ),
            ]),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new Flexible(
                child: Text("14:00 Hrs to 16:00 Hrs: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
              ),
              new Flexible(
                child: TextFieldBlocBuilder(
                  textFieldBloc: formBloc.basalRate14to16,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Units/Hour*',
                  ),
                ),
              ),
            ]),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new Flexible(
                child: Text("16:00 Hrs to 18:00 Hrs: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
              ),
              new Flexible(
                child: TextFieldBlocBuilder(
                  textFieldBloc: formBloc.basalRate16to18,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Units/Hour*',
                  ),
                ),
              ),
            ]),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new Flexible(
                child: Text("18:00 Hrs to 20:00 Hrs: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
              ),
              new Flexible(
                child: TextFieldBlocBuilder(
                  textFieldBloc: formBloc.basalRate18to20,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Units/Hour*',
                  ),
                ),
              ),
            ]),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new Flexible(
                child: Text("20:00 Hrs to 22:00 Hrs: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
              ),
              new Flexible(
                child: TextFieldBlocBuilder(
                  textFieldBloc: formBloc.basalRate20to22,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Units/Hour*',
                  ),
                ),
              ),
            ]),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new Flexible(
                child: Text("22:00 Hrs to 24:00 Hrs: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
              ),
              new Flexible(
                child: TextFieldBlocBuilder(
                  textFieldBloc: formBloc.basalRate22to00,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Units/Hour*',
                  ),
                ),
              ),
            ]),
      ],
    );
  }

  void fetchCurrentBasalRate(UserLogFormBloc formBloc) async {
    try{
      LoadingDialog.show(context);
      final response = await http.get(
          Uri.parse(Environment().config.apiHost + "/user/" + this._user.email! + "/basal-rate/active"),
          headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this._user.email!, await Utils.getIdToken(_user)),
          );

      if (response.statusCode == 200) {
        List t = json.decode(response.body);
        if(t.isNotEmpty){
          List<BasalRate> basalRateList = t.map((item) => BasalRate.fromJson(item)).toList();
          for(BasalRate basalRate in basalRateList){
            if(basalRate.startTime.hour==0 && basalRate.endTime.hour == 2){
              formBloc.basalRate00to02.updateInitialValue(basalRate.quantity.toString());
            }else if(basalRate.startTime.hour==2 && basalRate.endTime.hour == 4){
              formBloc.basalRate02to04.updateInitialValue(basalRate.quantity.toString());
            }else if(basalRate.startTime.hour==4 && basalRate.endTime.hour == 6){
              formBloc.basalRate04to06.updateInitialValue(basalRate.quantity.toString());
            }else if(basalRate.startTime.hour==6 && basalRate.endTime.hour == 8){
              formBloc.basalRate06to08.updateInitialValue(basalRate.quantity.toString());
            }else if(basalRate.startTime.hour==8 && basalRate.endTime.hour == 10){
              formBloc.basalRate08to10.updateInitialValue(basalRate.quantity.toString());
            }else if(basalRate.startTime.hour==10 && basalRate.endTime.hour == 12){
              formBloc.basalRate10to12.updateInitialValue(basalRate.quantity.toString());
            }else if(basalRate.startTime.hour==12 && basalRate.endTime.hour == 14){
              formBloc.basalRate12to14.updateInitialValue(basalRate.quantity.toString());
            }else if(basalRate.startTime.hour==14 && basalRate.endTime.hour == 16){
              formBloc.basalRate14to16.updateInitialValue(basalRate.quantity.toString());
            }else if(basalRate.startTime.hour==16 && basalRate.endTime.hour == 18){
              formBloc.basalRate16to18.updateInitialValue(basalRate.quantity.toString());
            }else if(basalRate.startTime.hour==18 && basalRate.endTime.hour == 20){
              formBloc.basalRate18to20.updateInitialValue(basalRate.quantity.toString());
            }else if(basalRate.startTime.hour==20 && basalRate.endTime.hour == 22){
              formBloc.basalRate20to22.updateInitialValue(basalRate.quantity.toString());
            }else if(basalRate.startTime.hour==22 && basalRate.endTime.hour == 0){
              formBloc.basalRate22to00.updateInitialValue(basalRate.quantity.toString());
            }
          }
        }
      }
      LoadingDialog.hide(context);
    }catch(e){
      LoadingDialog.hide(context);
      throw e;
    }
  }
}
