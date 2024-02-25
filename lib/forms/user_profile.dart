import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:t1d_buddy_ui/services/user_services.dart';
import 'package:t1d_buddy_ui/utils/common_utils.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';
import 'package:t1d_buddy_ui/utils/form_validator.dart';

class UserProfileFormBloc extends FormBloc<String, String> {

  late User? user;

  var isEditFlow = BooleanFieldBloc(initialValue: false, name: 'is_edit_flow');

  var photoId = TextFieldBloc(name: 'profile_photo_id');

  var invitationKey = TextFieldBloc(
    validators: [
      FieldBlocValidators.required,
    ],
    name: 'invitation_key',
  );

  var aboutMe = TextFieldBloc(name: 'about_me');

  var firstName = TextFieldBloc(validators: [
    FieldBlocValidators.required,
  ], name: 'first_name');

  var lastName = TextFieldBloc(name: 'last_name');

  var avatarName = TextFieldBloc(
    validators: [
      FieldBlocValidators.required,
      FormValidator.onlyAlphanumeric,
    ],
    name: 'avatar_name',
    asyncValidatorDebounceTime: Duration(milliseconds: 1000),
  );

  var email = TextFieldBloc(
    validators: [
      FieldBlocValidators.required,
      FieldBlocValidators.email,
    ],
    name: 'email',
  );

  var gender = SelectFieldBloc(items: [
    'MALE',
    'FEMALE'
  ],
      validators: [
        FieldBlocValidators.required,
      ],
      name: 'gender');

  /*var pinCode = TextFieldBloc(
    validators: [
      FieldBlocValidators.required,
      FormValidator.onlyNumbers,
      FormValidator.pincodeLengthValidator,
    ],
    name: 'pin_code',
    asyncValidatorDebounceTime: Duration(milliseconds: 1000),
  );*/

  var city = TextFieldBloc(validators: [
    FieldBlocValidators.required,
  ], name: 'city');

  var cityState = TextFieldBloc(validators: [
    FieldBlocValidators.required,
  ], name: 'state');

  var country = TextFieldBloc(validators: [
    FieldBlocValidators.required,
  ], name: 'country');

  var relationship = SelectFieldBloc(items: [
    'SELF',
    'SIBLING',
    'SPOUSE',
    'FATHER',
    'MOTHER',
    'SON',
    'DAUGHTER',
    'FRIEND'
  ], validators: [
    FieldBlocValidators.required,
  ], name: 'relationship');

  var dob = InputFieldBloc<DateTime, Object>(validators: [
    FieldBlocValidators.required,
  ], name: 'dob',
      initialValue: DateTime.now(),
      toJson: (value) => value.toUtc().toIso8601String());

  var dateOfDetection = InputFieldBloc<DateTime, Object>(
      validators: [
        FieldBlocValidators.required,
      ],
      name: 'date_of_detection',
      initialValue: DateTime.now(),
      toJson: (value) => value.toUtc().toIso8601String());

  var glucometerType = TextFieldBloc(name: 'glucometer_type');

  var injectionType = SelectFieldBloc(items: [
    'MDI',
    'INSULIN_PUMP'
  ], validators: [
    FieldBlocValidators.required,
  ], name: 'injection_type');

  var insulinType = SelectFieldBloc(items: [
    'U40',
    'U100'
  ], validators: [
    FieldBlocValidators.required,
  ], name: 'insulin_type');

  var pumpType = TextFieldBloc(name: 'pump_type');

  var normalBgMin = TextFieldBloc(
      initialValue: '70',
      validators: [
        FieldBlocValidators.required,
        FormValidator.onlyNumbers,
      ],
      name: 'normal_bg_min');

  var normalBgMax = TextFieldBloc(
      initialValue: '180',
      validators: [
        FieldBlocValidators.required,
        FormValidator.onlyNumbers,
      ],
      name: 'normal_bg_max');

  var bgUnit = SelectFieldBloc(
      initialValue: 'MGDL',
      items: ['MGDL', 'MMOL'],
      validators: [
        FieldBlocValidators.required,
      ],
      name: 'bg_unit');

  var onCgm = BooleanFieldBloc(initialValue: false, name: 'on_cgm');

  var role = TextFieldBloc(initialValue: 'MEMBER', name: 'role');

  UserProfileFormBloc(User? _user) {
    this.user = _user;
    addFieldBlocs(
      fieldBlocs: [
        isEditFlow,
        photoId,
        invitationKey,
        aboutMe,
        firstName,
        lastName,
        avatarName,
        email,
        gender,
        //pinCode,
        city,
        cityState,
        country,
        dob,
        relationship,
        dateOfDetection,
        glucometerType,
        injectionType,
        insulinType,
        pumpType,
        normalBgMin,
        normalBgMax,
        bgUnit,
        onCgm,
        role,
      ],
    );
    /*pinCode.addAsyncValidators(
      [_checkPincodeValidity],
    );*/

    avatarName.addAsyncValidators(
      [_checkAvatarNameAvailability],
    );
  }


  /*Future<String?> _checkPincodeValidity(String? pincode) async {
    final response = await http.get(
      Uri.parse('http://www.postalpincode.in/api/pincode/' + pincode!),
      headers: <String, String>{'Content-Type':'application/json; charset=UTF-8'},
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> json = jsonDecode(response.body);
      String status = json['Status'];
      if (status == 'Error') {
        return 'Wrong pincode';
      } else if (status == 'Success') {
        this.city.updateValue(json['PostOffice'][0]['District']);
        this.cityState.updateValue(json['PostOffice'][0]['State']);
        this.country.updateValue(json['PostOffice'][0]['Country']);
        return null;
      } else {
        return 'Error occurred';
      }
    } else {
      return 'Error occurred';
    }
  }*/

  Future<String?> _checkAvatarNameAvailability(String? avatarName) async {
    final response = await http.get(
      Uri.parse(Environment().config.apiHost + '/user/' + this.email.value + '/avatar/' + avatarName!),
      headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this.email.value, null),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> json = jsonDecode(response.body);
      bool isAvailable = json['is_available'];
      if (isAvailable) {
        return null;
      } else {
        return avatarName + ' is not available, try some other name';
      }
    } else {
      return 'Error occurred';
    }
  }

  @override
  Future<void> onSubmitting() async {
    try{
      String url;
      if(this.isEditFlow.value){
        url = Environment().config.apiHost + '/user/' + email.value.toString() + '/profile-update';
      }else{
        url = Environment().config.apiHost + '/user/register/' + invitationKey.value.toString();
      }

      final response = await http.post(
          Uri.parse(url),
          headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this.email.value, this.isEditFlow.value ? await Utils.getIdToken(user): null),
          body: JsonEncoder.withIndent('    ').convert(state.toJson(),
          ));

          if (response.statusCode == 200) {
            if(this.isEditFlow.value){
              await UserService.addUserProfileToSharedPref(this.email.value, user!);

              await UserService.addPublicProfileToSharedPref(this.email.value, user!);
              emitSuccess(
                  successResponse: 'User profile updated successfully');
            }else{
              emitSuccess(
                  successResponse: 'User registered successfully');
            }
          } else {
            emitFailure(failureResponse: 'Error occurred, please try again');
          }
    }catch(e){
      emitFailure(failureResponse: 'Error occurred, please try again');
    }

  }

}

class UserProfile{
  late final String? aboutMe;

  late final String?  firstName;

  late final String?  lastName;

  late final String?  avatarName;

  late final String?  email;

  late final String? gender;

  //late final String? pinCode;

  late final String? city;

  late final String? cityState;

  late final String? country;

  late final String? relationship;

  late final String? dob;

  late final String? dateOfDetection;

  late final String? glucometerType;

  late final String? injectionType;

  late final String? insulinType;

  late final String? pumpType;

  late final int normalBgMin;

  late final int normalBgMax;

  final String? bgUnit;

  late final bool? onCgm;

  late final String? role;

  late final String? apiSecret;

  late String? fcmToken;


  UserProfile.fromJson(Map<String, dynamic> json)
      : aboutMe = json['about_me'],
        firstName = json['first_name'],
        lastName = json['last_name'],
        avatarName = json['avatar_name'],
        email = json['email'],
        gender = json['gender'],
        //pinCode = json['pin_code'],
        city = json['city'],
        cityState = json['state'],
        country = json['country'],
        dob = json['dob'],
        relationship = json['relationship'],
        dateOfDetection = json['date_of_detection'],
        glucometerType = json['glucometer_type'],
        injectionType = json['injection_type'],
        insulinType = json['insulin_type'],
        pumpType = json['pump_type'],
        normalBgMin = json['normal_bg_min'],
        normalBgMax = json['normal_bg_max'],
        bgUnit = json['bg_unit'],
        onCgm = json['on_cgm'],
        role = json['role'],
        apiSecret = json['api_secret'],
        fcmToken = json['fcm_token'];

  Map<String, dynamic> toJson() => {
    'about_me' : aboutMe,
    'first_name': firstName,
    'last_name': lastName,
    'avatar_name': avatarName,
    'email': email,
    'gender': gender,
    //'pin_code': pinCode,
    'city': city,
    'state': cityState,
    'country': country,
    'dob': dob,
    'relationship': relationship,
    'date_of_detection': dateOfDetection,
    'glucometer_type': glucometerType,
    'injection_type': injectionType,
    'insulin_type': insulinType,
    'pump_type': pumpType,
    'normal_bg_min': normalBgMin,
    'normal_bg_max': normalBgMax,
    'bg_unit': bgUnit,
    'on_cgm': onCgm,
    'role': role,
    'api_secret': apiSecret,
    'fcm_token': fcmToken
  };
}

class UserPublicProfile{

  late final String? photoId;

  late final String? connectionStatus;

  late final String? about;

  late final String?  firstName;

  late final String?  lastName;

  late final String? gender;

  late final String? city;

  late final String? cityState;

  late final String? country;

  late final String? relationship;

  late final int? age;

  late final String? glucometerType;

  late final String? injectionType;

  late final String? insulinType;

  late final bool? onCgm;

  late final String? pumpType;

  late final int? normalBgMin;

  late final int? normalBgMax;

  late final String? bgUnit;

  late final String diaversary;

  bool sameInjectionType(String otherInjType){
    return this.injectionType == otherInjType ||
        (this.injectionType == 'Insulin Pump' && otherInjType == 'INSULIN_PUMP');
  }

  UserPublicProfile.fromJson(Map<String, dynamic> json)
      : photoId = json['profile_photo_id'],
        connectionStatus = json['connection_status'],
        about = json['about'],
        firstName = json['first_name'],
        lastName = json['last_name'],
        gender = json['gender'],
        city = json['city'],
        cityState = json['state'],
        country = json['country'],
        age = json['age'],
        relationship = json['relationship'],
        glucometerType = json['glucometer_type'],
        injectionType = json['injection_type'],
        insulinType = json['insulin_type'],
        pumpType = json['pump_type'],
        normalBgMin = json['normal_bg_min'],
        normalBgMax = json['normal_bg_max'],
        bgUnit = json['bg_unit'],
        onCgm = json['on_cgm'],
        diaversary = json['date-of-detection'] == null ? '' : DateFormat('dd-MMMM-yyyy').format(DateTime.parse(json['date-of-detection']).toLocal());

}

class MemberDetails{

  late final int id;

  late final String email;

  late final String firstName;

  late final String lastName;

  late final String city;

  late final String cityState;

  late final String country;

  late final int age;

  late final String gender;

  late bool follow;

  late final String profilePhotoId;

  late final DateTime createdAt;

  MemberDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    email = json['email'];
    firstName = json['first_name'];
    lastName = json['last_name'] == null ? '' : json['last_name'];
    createdAt = DateTime.parse(json['created_at']);
    city = json['city'];
    cityState = json['state'];
    country = json['country'];
    age = json['age'];
    gender = json['gender'];
    follow = json['follow'];
    profilePhotoId = json['profile_photo_id'] == null ? '' : json['profile_photo_id'];
  }
}

class Token{
  late String idToken;

  late DateTime createdAt;

  Token(this.idToken, this.createdAt);

  Map<String, dynamic> toJson() => {
    'id_token' : idToken,
    'created_at': createdAt.toUtc().toIso8601String()
  };

  Token.fromJson(Map<String, dynamic> json) {
    idToken = json['id_token'];
    createdAt = DateTime.parse(json['created_at']);
  }
}
