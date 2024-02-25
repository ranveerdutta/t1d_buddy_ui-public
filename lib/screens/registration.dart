import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:t1d_buddy_ui/utils/common_utils.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';
import 'package:t1d_buddy_ui/screens/loading_dialog.dart';
import 'package:t1d_buddy_ui/main.dart';
import 'package:t1d_buddy_ui/forms/user_profile.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';

class Registration extends StatefulWidget {
  //Registration({Key? key}) : super(key: key);

  final String? _email;
  final bool _noInviteFlow;

  Registration({String? email, bool noInviteFlow = false, Key? key}) :
        _email = email,
        _noInviteFlow = noInviteFlow,
        super(key: key);

  @override
  _RegistrationState createState() {
    return _RegistrationState();
  }
}

class _RegistrationState extends State<Registration> {
  final TextEditingController _controller1 = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();
  Future<Invitation>? _futureInvitation;

  final _invitationFormKey = GlobalKey<FormState>();

  @override
  void initState(){
    super.initState();
    if(widget._noInviteFlow == true){
      _controller1.text = 't1d-buddy';
      _controller2.text = widget._email!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Registration"),
        ),
        body: Center(
            child: (_futureInvitation == null && widget._noInviteFlow == false)
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Form(
                          key: _invitationFormKey,
                          child: Column(children: <Widget>[
                            Text(
                              'Please enter your invitation key:',
                              style: Theme.of(context)
                                  .textTheme
                                  .headline6!
                                  .copyWith(color: Colors.blue),
                            ),
                            TextFormField(
                              controller: _controller1,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter invitation key';
                                }
                                return null;
                              },
                              style: TextStyle(color: Colors.blue),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        style: BorderStyle.solid,
                                        color: Colors.blue,
                                        width: 10.0),
                                    borderRadius: BorderRadius.circular(50)),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Your Email(gmail account only):',
                              style: Theme.of(context)
                                  .textTheme
                                  .headline6!
                                  .copyWith(color: Colors.blue),
                            ),
                            TextFormField(
                              controller: _controller2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter email id';
                                }
                                return null;
                              },
                              style: TextStyle(color: Colors.blue),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        style: BorderStyle.solid,
                                        color: Colors.blue,
                                        width: 10.0),
                                    borderRadius: BorderRadius.circular(50)),
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  if (_invitationFormKey.currentState!
                                      .validate()) {
                                    _futureInvitation = validateInvitation(
                                        _controller1.text, _controller2.text);
                                  }
                                });
                              },
                              child: Text('submit'),
                            ),
                          ])),
                    ],
                  )
                : (widget._noInviteFlow == true ? buildUserProfileForm() : buildFutureInvitationBuilder())));
  }

  FutureBuilder<Invitation> buildFutureInvitationBuilder() {
    return FutureBuilder<Invitation>(
      future: _futureInvitation,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return buildUserProfileForm();
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }

        return const CircularProgressIndicator();
      },
    );
  }

  Widget buildUserProfileForm() {
    return BlocProvider(
        create: (context) => UserProfileFormBloc(null),
        child: Builder(builder: (context) {
          final formBloc = BlocProvider.of<UserProfileFormBloc>(context);
          formBloc.email.updateInitialValue(_controller2.text);
          formBloc.invitationKey.updateInitialValue(_controller1.text);
          return Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              child: Scaffold(
                  body: FormBlocListener<UserProfileFormBloc, String, String>(
                      onSubmitting: (context, state) {
                        LoadingDialog.show(context);
                      },
                      onSuccess: (context, state) {
                        LoadingDialog.hide(context);
                        Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => SuccessScreen()));
                      },
                      onFailure: (context, state) {
                        LoadingDialog.hide(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.failureResponse!)));
                      },
                      child: SingleChildScrollView(
                          physics: ClampingScrollPhysics(),
                          child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(children: <Widget>[
                                SizedBox(height: 20,),
                                Text('*Please add your basic details to personalize this app according to your need', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                                SizedBox(height: 20,),
                                new Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      new Flexible(
                                        child: TextFieldBlocBuilder(
                                          textFieldBloc: formBloc.firstName,
                                          textCapitalization: TextCapitalization.words,
                                          decoration: InputDecoration(
                                            labelText: 'First name*',
                                            prefixIcon: Icon(Icons.people),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10.0),
                                      new Flexible(
                                        child: TextFieldBlocBuilder(
                                          textFieldBloc: formBloc.lastName,
                                          textCapitalization: TextCapitalization.words,
                                          decoration: InputDecoration(
                                            labelText: 'Last name',
                                            prefixIcon: Icon(Icons.people),
                                          ),
                                        ),
                                      )
                                    ]),
                                TextFieldBlocBuilder(
                                  textFieldBloc: formBloc.avatarName,
                                  suffixButton: SuffixButton.asyncValidating,
                                  decoration: InputDecoration(
                                    labelText: 'Avatar name*',
                                    helperText: '*Your secret name',
                                    prefixIcon: Icon(Icons.people),
                                    //prefixIcon: Icon(Icons.people),
                                  ),
                                ),
                                TextFieldBlocBuilder(
                                  textFieldBloc: formBloc.aboutMe,
                                  textCapitalization: TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    labelText: 'About me',
                                    //prefixIcon: Icon(Icons.text_fields),
                                  ),
                                ),
                                TextFieldBlocBuilder(
                                  textFieldBloc: formBloc.email,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Email*',
                                    prefixIcon: Icon(Icons.email),
                                  ),
                                ),
                                RadioButtonGroupFieldBlocBuilder<String>(
                                  selectFieldBloc: formBloc.gender,
                                  decoration: InputDecoration(
                                    labelText: 'Gender*',
                                    prefixIcon: SizedBox(),
                                  ),
                                  numberOfItemPerRow: 2,
                                  itemBuilder: (context, item) => FieldItem(child: Text(item),
                                  ),
                                ),
                                TextFieldBlocBuilder(
                                  textFieldBloc: formBloc.city,
                                  //suffixButton: SuffixButton.asyncValidating,
                                  textCapitalization: TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    labelText: 'City*',
                                    prefixIcon: Icon(Icons.add_location),
                                  ),
                                ),
                                new Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      new Flexible(
                                        child: TextFieldBlocBuilder(
                                          textFieldBloc: formBloc.cityState,
                                          textCapitalization: TextCapitalization.sentences,
                                          decoration: InputDecoration(
                                            labelText: 'State/Region*',
                                            prefixIcon: Icon(Icons.add_location),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10.0),
                                      new Flexible(
                                        child: TextFieldBlocBuilder(
                                          textFieldBloc: formBloc.country,
                                          textCapitalization: TextCapitalization.sentences,
                                          //suffixButton: SuffixButton.asyncValidating,
                                          decoration: InputDecoration(
                                            labelText: 'Country*',
                                            prefixIcon: Icon(Icons.add_location),
                                          ),
                                        ),
                                      ),
                                    ]),
                                DropdownFieldBlocBuilder<String>(
                                    selectFieldBloc: formBloc.relationship,
                                    decoration: InputDecoration(
                                      labelText: 'Managed by*',
                                      helperText: '*Please fill all the fields with the details of the T1D, if your are creating this profile for someone else',
                                      helperMaxLines: 2,
                                      //prefixIcon: Icon(Icons.sentiment_satisfied),
                                    ),
                                    itemBuilder: (context, item) => FieldItem(child: Text(item))),
                                DateTimeFieldBlocBuilder(
                                  dateTimeFieldBloc: formBloc.dob,
                                  format: DateFormat('dd-MM-yyyy'),
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                  decoration: InputDecoration(
                                    labelText: 'Date of birth*',
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                ),
                                DateTimeFieldBlocBuilder(
                                  dateTimeFieldBloc: formBloc.dateOfDetection,
                                  format: DateFormat('dd-MM-yyyy'),
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                  decoration: InputDecoration(
                                      labelText: 'Date of detection*',
                                      prefixIcon: Icon(Icons.calendar_today),
                                      helperText:
                                          '*Date of detection will be used to calculate your T1D age'),
                                ),
                                new Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      new Flexible(
                                        child: RadioButtonGroupFieldBlocBuilder<String>(
                                            selectFieldBloc: formBloc.injectionType,
                                            decoration: InputDecoration(
                                              labelText: 'Injection type*',
                                              prefixIcon: SizedBox(),
                                            ),
                                            itemBuilder: (context, item) => FieldItem(child: Text(item))),
                                      ),
                                      SizedBox(width: 10.0),
                                      new Flexible(
                                        child: RadioButtonGroupFieldBlocBuilder<String>(
                                            selectFieldBloc: formBloc.insulinType,
                                            decoration: InputDecoration(
                                              labelText: 'Insulin type*',
                                              prefixIcon: SizedBox(),
                                            ),
                                            itemBuilder: (context, item) => FieldItem(child: Text(item))),
                                      )
                                    ]),
                                TextFieldBlocBuilder(
                                  textFieldBloc: formBloc.pumpType,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: InputDecoration(
                                    labelText: 'Pump type',
                                    helperText: '*If you are on insulin pump'
                                    //prefixIcon: Icon(Icons.text_fields),
                                  ),
                                ),
                                TextFieldBlocBuilder(
                                  textFieldBloc: formBloc.glucometerType,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: InputDecoration(
                                    labelText: 'Glucometer type',
                                    //prefixIcon: Icon(Icons.text_fields),
                                  ),
                                ),
                                RadioButtonGroupFieldBlocBuilder<String>(
                                  selectFieldBloc: formBloc.bgUnit,
                                  decoration: InputDecoration(
                                    labelText: 'BG unit*',
                                    prefixIcon: SizedBox(),
                                  ),
                                  itemBuilder: (context, item) => FieldItem(child: Text(item),
                                  ),
                                ),
                                new Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      new Flexible(
                                        child: TextFieldBlocBuilder(
                                          textFieldBloc: formBloc.normalBgMin,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Min normal BG*',
                                            prefixIcon: Icon(Icons
                                                .sentiment_very_satisfied_rounded),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 20.0),
                                      new Flexible(
                                        child: TextFieldBlocBuilder(
                                          textFieldBloc: formBloc.normalBgMax,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Max normal BG*',
                                            prefixIcon: Icon(Icons
                                                .sentiment_very_satisfied_rounded),
                                          ),
                                        ),
                                      )
                                    ]),
                                SwitchFieldBlocBuilder(
                                  booleanFieldBloc: formBloc.onCgm,
                                  body: Container(
                                    alignment: Alignment.centerLeft,
                                    child: Text('On CGM'),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: formBloc.submit,
                                  child: Text('Register'),
                                ),
                              ]))))));
        }));
  }
}

Future<Invitation> validateInvitation(
    String invitationKey, String email) async {
  final response = await http.get(
    Uri.parse(Environment().config.apiHost +
        '/user/invitation/' +
        invitationKey +
        '/email/' +
        email),
    headers: Utils.getHttpHeaders('application/json; charset=UTF-8', email, null),
  );

  if (response.statusCode == 200) {
    return Invitation.fromJson(jsonDecode(response.body));
  } else {
    throw Exception(response.body);
  }
}

class Invitation {
  final String invitationKey;
  final String invitedBy;
  final String email;

  Invitation(
      {required this.invitationKey,
      required this.invitedBy,
      required this.email});

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
        invitationKey: json['invitation_key'],
        invitedBy: json['invited_by'],
        email: json['email']);
  }
}

class SuccessScreen extends StatelessWidget {
  SuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.tag_faces, size: 100, color: Colors.blue),
            SizedBox(height: 10),
            Text(
              'Registration successful',
              style: TextStyle(fontSize: 54, color: Colors.blue),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context)
                  .pushReplacement(MaterialPageRoute(builder: (_) => MyApp())),
              icon: Icon(Icons.replay),
              label: Text('Go back and login'),
            ),
          ],
        ),
      ),
    );
  }
}
