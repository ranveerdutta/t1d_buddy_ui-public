import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:t1d_buddy_ui/utils/common_utils.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';

class RecordFormBloc extends FormBloc<String, String> {

  late User user;

  final email = TextFieldBloc();

  final description = TextFieldBloc(
      name: 'description',
      validators: [
        FieldBlocValidators.required,
      ]);

  final fileId = TextFieldBloc(
      /*validators: [
        FieldBlocValidators.required,
      ]*/);


  var consultationDate = InputFieldBloc<DateTime, Object>(validators: [
    FieldBlocValidators.required,
  ],
      initialValue: DateTime.now(),
      toJson: (value) => value.toUtc().toIso8601String());


  RecordFormBloc(User _user) {
    this.user = _user;
    addFieldBlocs(
      fieldBlocs: [
        description,
        fileId,
        consultationDate,
      ],
    );

    @override
    Future<void> close() {
      description.close();
      fileId.close();
      consultationDate.close();
      return super.close();
    }
  }

  Map<String, dynamic> toInputJson() => <String, dynamic>{
    'description': description.value,
    'file_id': fileId.value,
    'record_date': consultationDate.state.toJson(),
  };

  @override
  Future<void> onSubmitting() async {
    try{
      if(fileId == null || fileId.value == ''){
        emitFailure(failureResponse: 'Please upload a valid file');
        return;
      }
      final response = await http.post(
          Uri.parse(Environment().config.apiHost +
              '/user/' + this.email.value + '/medical-record'),
          headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this.email.value, await Utils.getIdToken(user)),
          body: JsonEncoder.withIndent('    ').convert(this.toInputJson(),
          ));

      if (response.statusCode == 200) {
        emitSuccess(
            successResponse: 'New record added successfully');
      } else {
        emitFailure(failureResponse: 'Error occurred, please try again');
      }
    }catch(e){
      emitFailure(failureResponse: 'Error occurred, please try again');
    }

  }

}

class RecordData{

  late final int recordId;

  late String description;

  late final DateTime recordDate;

  late final String fileId;

  RecordData.fromJson(Map<String, dynamic> json) {
    recordId = json['id'];
    description = json['description'];
    fileId = json['file_id'];
    recordDate = DateTime.parse(json['record_date']);
  }

}