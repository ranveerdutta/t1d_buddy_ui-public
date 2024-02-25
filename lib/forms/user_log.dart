import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:t1d_buddy_ui/utils/common_utils.dart';
import 'package:t1d_buddy_ui/utils/enumerations.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';
import 'package:t1d_buddy_ui/utils/form_validator.dart';

class UserLogFormBloc extends FormBloc<String, String> {

  late User user;

  final email = TextFieldBloc();

  final logType = SelectFieldBloc(items: [
    LogType.BG.name, LogType.EXERCISE.name, LogType.BOLUS.name, LogType.BASAL.name, LogType.ACCESSORY_CHANGE.name, LogType.PUMP_BASAL.name //, LogType.FOOD.name
  ], validators: [
    FieldBlocValidators.required,
  ], name: 'log_type', initialValue: LogType.BG.name);

  final bgValue = TextFieldBloc(
      validators: [
        FieldBlocValidators.required,
        FormValidator.onlyNumbers,
      ],
      name: 'bg_number');

  final bgUnit = SelectFieldBloc(
      items: ['MGDL', 'MMOL'],
      validators: [
        FieldBlocValidators.required,
      ],
      name: 'bg_unit');

  final logTime = InputFieldBloc<DateTime, Object>(
      validators: [
        FieldBlocValidators.required,
      ],
      initialValue: DateTime.now(),
      name: 'log_time',
      toJson: (value) => value.toUtc().toIso8601String());

  final insulinAmt = TextFieldBloc(
      validators: [
        FieldBlocValidators.required,
        FormValidator.onlyNumbers,
      ],
      name: 'insulin_amt');

  final insulinType = SelectFieldBloc(
      items: ['U40', 'U100'],
      validators: [
        FieldBlocValidators.required,
      ],
      name: 'insulin_type');

  final exercise = SelectFieldBloc(items: [
    ExerciseType.WALKING.name, ExerciseType.CYCLING.name, ExerciseType.RUNNING.name, ExerciseType.YOGA.name, ExerciseType.SPORTS.name, ExerciseType.SWIMMING.name, ExerciseType.GYM_WORKOUT.name, ExerciseType.OTHERS.name
  ], validators: [
    FieldBlocValidators.required,
  ], name: 'exercise', initialValue: 'Walking');

  final duration = TextFieldBloc(
      validators: [
        FieldBlocValidators.required,
        FormValidator.onlyNumbers,
      ],
      name: 'duration');


  final moreDetails = TextFieldBloc(
      name: 'more_details');

  final accessoryType = SelectFieldBloc(items: [
    AccessoryType.SYRINGE.name, AccessoryType.INFUSION_SET.name, AccessoryType.NEEDLE.name, AccessoryType.RESERVOIR.name, AccessoryType.CGM.name, AccessoryType.LANCET.name
  ], validators: [
    FieldBlocValidators.required,
  ], name: 'accessory_type', initialValue: null);


  final accessoryReminder = InputFieldBloc<DateTime, Object>(
      initialValue: DateTime.now(),
      name: 'reminder_time',
      toJson: (value) => value.toUtc().toIso8601String());


  //Fields for basal rate
  final basalRate00to02 = TextFieldBloc(
      validators: [
        FormValidator.onlyNumbers,
        FieldBlocValidators.required,

      ],
      name: 'basal_rate_00_02');

  final basalRate02to04 = TextFieldBloc(
      validators: [
        FormValidator.onlyNumbers,
        FieldBlocValidators.required,
      ],
      name: 'basal_rate_02_04');

  final basalRate04to06 = TextFieldBloc(
      validators: [
        FormValidator.onlyNumbers,
        FieldBlocValidators.required,
      ],
      name: 'basal_rate_04_06');

  final basalRate06to08 = TextFieldBloc(
      validators: [
        FormValidator.onlyNumbers,
        FieldBlocValidators.required,
      ],
      name: 'basal_rate_06_08');

  final basalRate08to10 = TextFieldBloc(
      validators: [
        FormValidator.onlyNumbers,
        FieldBlocValidators.required,
      ],
      name: 'basal_rate_08_10');

  final basalRate10to12 = TextFieldBloc(
      validators: [
        FormValidator.onlyNumbers,
        FieldBlocValidators.required,
      ],
      name: 'basal_rate_10_12');

  final basalRate12to14 = TextFieldBloc(
      validators: [
        FormValidator.onlyNumbers,
        FieldBlocValidators.required,
      ],
      name: 'basal_rate_12_14');

  final basalRate14to16 = TextFieldBloc(
      validators: [
        FormValidator.onlyNumbers,
        FieldBlocValidators.required,
      ],
      name: 'basal_rate_14_16');

  final basalRate16to18 = TextFieldBloc(
      validators: [
        FormValidator.onlyNumbers,
        FieldBlocValidators.required,
      ],
      name: 'basal_rate_16_18');

  final basalRate18to20 = TextFieldBloc(
      validators: [
        FormValidator.onlyNumbers,
        FieldBlocValidators.required,
      ],
      name: 'basal_rate_18_20');

  final basalRate20to22 = TextFieldBloc(
      validators: [
        FormValidator.onlyNumbers,
        FieldBlocValidators.required,
      ],
      name: 'basal_rate_20_22');

  final basalRate22to00 = TextFieldBloc(
      validators: [
        FormValidator.onlyNumbers,
        FieldBlocValidators.required,
      ],
      name: 'basal_rate_22_24');


  UserLogFormBloc(User _user) {
    this.user = _user;
    addFieldBlocs(
      fieldBlocs: [
        logType,
        logTime,
        bgValue,
        bgUnit,
      ],
    );

    logType.onValueChanges(
      onData: (previous, current) async* {
        removeFieldBlocs(
          fieldBlocs: [
            bgValue,
            bgUnit,
            insulinAmt,
            insulinType,
            exercise,
            duration,
            moreDetails,
            accessoryType,
            accessoryReminder,
            basalRate00to02, basalRate02to04, basalRate04to06, basalRate06to08, basalRate08to10, basalRate10to12,
            basalRate12to14, basalRate14to16, basalRate16to18, basalRate18to20, basalRate20to22, basalRate22to00,
          ],
        );
        if (current.value == LogType.BG.name) {
          addFieldBlocs(fieldBlocs: [bgValue, bgUnit]);
        }else if (current.value == LogType.BOLUS.name || current.value == LogType.BASAL.name) {
          addFieldBlocs(fieldBlocs: [insulinAmt, insulinType]);
        }else if (current.value == LogType.EXERCISE.name) {
          addFieldBlocs(fieldBlocs: [exercise, duration, moreDetails]);
        }else if (current.value == LogType.ACCESSORY_CHANGE.name) {
          addFieldBlocs(fieldBlocs: [accessoryType, accessoryReminder]);
        }else if (current.value == LogType.PUMP_BASAL.name){
          addFieldBlocs(fieldBlocs: [basalRate00to02, basalRate02to04, basalRate04to06, basalRate06to08, basalRate08to10, basalRate10to12,
            basalRate12to14, basalRate14to16, basalRate16to18, basalRate18to20, basalRate20to22, basalRate22to00]);
        }

      }

    );

    @override
    Future<void> close() {
      bgValue.close();
      bgUnit.close();
      insulinAmt.close();
      insulinType.close();
      exercise.close();
      duration.close();
      moreDetails.close();
      accessoryType.close();
      accessoryReminder.close();
      return super.close();
    }
  }

  Map<String, dynamic> toInputJson() {
    if(this.logType.value == LogType.BG.name){
      return bgLogToJson();
    }else if(this.logType.value == LogType.BOLUS.name){
      return insulinLogToJson('BOLUS');
    }else if(this.logType.value == LogType.BASAL.name){
      return insulinLogToJson('BASAL');
    }else if(this.logType.value == LogType.EXERCISE.name){
      return exerciseLogToJson();
    }else if(this.logType.value == LogType.ACCESSORY_CHANGE.name){
      return accessoryLogToJson();
    }else{
      throw Exception('wrong log type');
    }

  }

  Map<String, dynamic> insulinLogToJson(String doseType) => <String, dynamic>{
    'insulin_dose_type': doseType,
    'taken_at': this.logTime.state.toJson(),
    'insulin_dose':{
      'quantity': this.insulinAmt.valueToDouble,
      'insulin_type': this.insulinType.value
    }
  };

  Map<String, dynamic> bgLogToJson() => <String, dynamic>{
    'bg_reading_source': 'GLUCOMETER',
    'measured_at': this.logTime.state.toJson(),
    'bg_level' : {
      "bg_number": this.bgValue.valueToDouble,
      "bg_unit": this.bgUnit.value
    }
  };

  Map<String, dynamic> exerciseLogToJson() => <String, dynamic>{
    'done_at': this.logTime.state.toJson(),
    'duration_in_minutes': this.duration.value,
    'more_details': this.moreDetails.value,
    'exercise_type':{
      'type': getExerciseType(this.exercise.value)
    }
  };

  Map<String, dynamic> accessoryLogToJson() => <String, dynamic>{
    'changed_at': this.logTime.state.toJson(),
    'reminder_time': this.accessoryReminder.state.toJson(),
    'accessory_type':{
      'type': getAccessoryType(this.accessoryType.value)
    }
  };

   Set<Map<String, dynamic>> basalRateToJson() => {
     {"start_time": "00:00",
      "end_time": "02:00",
       "insulin_dose": {
         "quantity": basalRate00to02.valueToDouble
       }
      },
      {"start_time": "02:00",
      "end_time": "04:00",
        "insulin_dose": {
          "quantity": basalRate02to04.valueToDouble
        }
      },
      {"start_time": "04:00",
      "end_time": "06:00",
        "insulin_dose": {
          "quantity": basalRate04to06.valueToDouble
        }
      },
      {"start_time": "06:00",
      "end_time": "08:00",
        "insulin_dose": {
          "quantity": basalRate06to08.valueToDouble
        }
      },
      {"start_time": "08:00",
      "end_time": "10:00",
        "insulin_dose": {
          "quantity": basalRate08to10.valueToDouble
        }
      },
      {"start_time": "10:00",
      "end_time": "12:00",
        "insulin_dose": {
          "quantity": basalRate10to12.valueToDouble
        }
      },
      {"start_time": "12:00",
      "end_time": "14:00",
        "insulin_dose": {
          "quantity": basalRate12to14.valueToDouble
        }
      },
      {"start_time": "14:00",
      "end_time": "16:00",
        "insulin_dose": {
          "quantity": basalRate14to16.valueToDouble
        }
      },
      {"start_time": "16:00",
      "end_time": "18:00",
        "insulin_dose": {
          "quantity": basalRate16to18.valueToDouble
        }
      },
      {"start_time": "18:00",
      "end_time": "20:00",
        "insulin_dose": {
          "quantity": basalRate18to20.valueToDouble
        }
      },
      {"start_time": "20:00",
      "end_time": "22:00",
        "insulin_dose": {
          "quantity": basalRate20to22.valueToDouble
        }
      },
      {"start_time": "22:00",
      "end_time": "00:00",
        "insulin_dose": {
          "quantity": basalRate22to00.valueToDouble
        }
      }
  };

  static String getExerciseType(String? name){
    for(ExerciseType type in ExerciseType.values){
      if(type.name == name) return type.value;
    }

    throw Exception('wrong exercise type');
  }

  static String getAccessoryType(String? name){
    for(AccessoryType type in AccessoryType.values){
      if(type.name == name) return type.value;
    }

    throw Exception('wrong accessory type');
  }

  String getUrl(){
    if(this.logType.value == LogType.BG.name){
      return '/user/' + this.email.value + '/bg-reading';
    }else if(this.logType.value == LogType.BOLUS.name || this.logType.value == LogType.BASAL.name){
      return '/user/' + this.email.value + '/insulin-dose';
    }else if(this.logType.value == LogType.EXERCISE.name){
      return '/user/' + this.email.value + '/exercise';
    }else if(this.logType.value == LogType.ACCESSORY_CHANGE.name){
      return '/user/' + this.email.value + '/accessory-change';
    }else if(this.logType.value == LogType.PUMP_BASAL.name){
      return '/user/' + this.email.value + '/basal-rate';
    }else{
      throw Exception('wrong log type');
    }
  }

  @override
  Future<void> onSubmitting() async {

    try{
      String inputJson = JsonEncoder.withIndent('    ').convert(this.logType.value == LogType.PUMP_BASAL.name ? basalRateToJson().toList() : toInputJson());
      final response = await http.post(
          Uri.parse(Environment().config.apiHost + getUrl()),
          headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this.email.value, await Utils.getIdToken(user)),
          body: inputJson
      );

      if (response.statusCode == 200) {
        emitSuccess(
            successResponse: 'Log added successfully');
      } else {
        emitFailure(failureResponse: 'Error occurred, please try again');
      }
    }catch(e){
      emitFailure(failureResponse: 'Error occurred, please try again');
    }

  }
}

class UserLog{

  late final int logId;
  late final String logType;
  late final DateTime logTime;
  late final double bgValue;
  late final String bgUnit;
  late final double rawBg;
  late final double insulinAmt;
  late final String insulinType;
  late final String insulinDoseType;
  late final String exercise;
  late final int duration;
  late final String moreDetails;
  late final String accessoryType;
  DateTime? startTime;
  DateTime? endTime;
  DateTime? accessoryReminder;

  UserLog.fromBgJson(Map<String, dynamic> json) {
    logId = json['log_id'];
    logType = LogType.BG.name;
    logTime = DateTime.parse(json['measured_at']);
    bgValue = json['bg_number'];
    bgUnit = json['bg_unit'];
    rawBg = json['raw_bg'] == null ? 0.0 : json['raw_bg'];
  }

  UserLog.fromInsulinJson(Map<String, dynamic> json) {
    logId = json['log_id'];
    if(json['insulin_dose_type'] == 'BASAL') logType = LogType.BASAL.name;
    else if(json['insulin_dose_type'] == 'BOLUS') logType = LogType.BOLUS.name;
    else logType = LogType.BOLUS.name;

    logTime = DateTime.parse(json['taken_at']);
    insulinAmt = json['quantity'];
    insulinType = json['insulin_type'];
    insulinDoseType = json['insulin_dose_type'];
  }

  UserLog.fromExerciseJson(Map<String, dynamic> json) {
    logId = json['log_id'];
    logType = LogType.EXERCISE.name;
    logTime = DateTime.parse(json['done_at']);
    int durationInMinute = json['duration_in_minutes'];
    duration = durationInMinute;
    moreDetails = json['more_details'];
    exercise = json['exercise_type'];
  }

  UserLog.fromAccessoryJson(Map<String, dynamic> json) {
    logId = json['log_id'];
    logType = LogType.ACCESSORY_CHANGE.name;
    logTime = DateTime.parse(json['changed_at']);
    accessoryType = json['accessory_type'];
  }

  String getTitleText(){
      if(this.logType == LogType.BG.name){
        return this.bgValue.toString() + " " + this.bgUnit;
      }else if(this.logType == LogType.BOLUS.name || this.logType == LogType.BASAL.name){
        return this.insulinAmt.toString() + " units ";
      }else if(this.logType == LogType.EXERCISE.name){
        return this.exercise;
      }else if(this.logType == LogType.ACCESSORY_CHANGE.name){
        return this.accessoryType;
      } else{
        return 'NA';
      }
  }

  String getSubTitleText(){
    if(this.logType == LogType.EXERCISE.name){
      return "for " + this.duration.toString() + ' mins';
    } else{
      return '';
    }
  }
}

class UserLogStat{

  late final String bgReadingCount;

  late final String bgReadingAvg;

  late final String bgInRange;

  late final String exerciseDurationInMins;

  late final String totalBolus;

  late final String totalBasal;

  late final String totalPumpBasal;

  UserLogStat.fromJson(Map<String, dynamic> json) {
    bgReadingCount = json['bg_stat']['reading_count'].toString();
    bgReadingAvg = json['bg_stat']['average_reading'] == 0.0 ? '_': json['bg_stat']['average_reading'].toString();
    bgInRange = json['bg_stat']['percentage_in_range'] == 0.0 ? '_': json['bg_stat']['percentage_in_range'].toString();

    exerciseDurationInMins = json['exercise_stat']['duration_in_minutes'].toString();

    totalBolus = json['insulin_stat']['total_bolus'].toString();
    totalBasal = json['insulin_stat']['total_basal'].toString();

    if(json['basal_rate_stat']['total_pump_basal'] != null){
      totalPumpBasal = json['basal_rate_stat']['total_pump_basal'];
    }
  }


}

class BasalRate{

  late final TimeOfDay startTime;

  late final TimeOfDay endTime;

  late final double quantity;

  BasalRate.fromJson(Map<String, dynamic> json){
    startTime = TimeOfDay(hour: int.parse(json['start_time'].toString().split(":")[0]), minute: int.parse(json['start_time'].toString().split(":")[1]));
    endTime = TimeOfDay(hour: int.parse(json['end_time'].toString().split(":")[0]), minute: int.parse(json['end_time'].toString().split(":")[1]));
    quantity = json['insulin_dose']['quantity'];
  }

  String getTime(){
    return getTimeStr(startTime.hour) + ":" + getTimeStr(startTime.minute) + '-' + getTimeStr(endTime.hour) + ":" + getTimeStr(endTime.minute) + 'Hrs';
  }

  String getTimeStr(int time){
    return time > 9 ? time.toString() : '0' + time.toString();
  }


}

