import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:t1d_buddy_ui/forms/user_profile.dart';
import 'package:t1d_buddy_ui/main.dart';
import 'package:t1d_buddy_ui/screens/common_widgets.dart';
import 'package:t1d_buddy_ui/screens/image_uploader.dart';
import 'package:t1d_buddy_ui/screens/loading_dialog.dart';
import 'package:t1d_buddy_ui/utils/shared_preference_util.dart';

class EditProfile extends StatefulWidget {
  EditProfile({Key? key, required this.user}) : super(key: key);

  final User user;

  @override
  _EditProfileState createState() {
    return _EditProfileState();
  }
}

class _EditProfileState extends State<EditProfile> {

  late User user;

  late final UserProfile userProfile;

  late final UserPublicProfile publicProfile;

  bool updatedInitialValues = false;

  @override
  void initState(){
    super.initState();
    this.user = widget.user;
    this.userProfile = SharedPrefUtil.getUserProfile();
    this.publicProfile = SharedPrefUtil.getPublicProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text("Edit profile"),
      ),
      body: Center(
        child: buildUserProfileForm()
      )
    );
  }

  Widget buildUserProfileForm() {
    return BlocProvider(
        create: (context) => UserProfileFormBloc(user),
        child: Builder(builder: (context) {
          final formBloc = BlocProvider.of<UserProfileFormBloc>(context);
          if(!updatedInitialValues) updateFormBloc(formBloc);
          updatedInitialValues = true;
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
                                new Center(
                                    child: new ImageUploader(user: this.user, isProfilePhoto: true, imageId: (imageId) {
                                      formBloc.photoId.updateInitialValue(imageId);
                                    })
                                ),
                                SizedBox(height: 20,),
                                new Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      new Flexible(
                                        child: TextFieldBlocBuilder(
                                          textFieldBloc: formBloc.firstName,
                                          isEnabled: false,
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
                                          isEnabled: false,
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
                                  isEnabled: false,
                                  decoration: InputDecoration(
                                    labelText: 'Email*',
                                    prefixIcon: Icon(Icons.email),
                                  ),
                                ),
                                RadioButtonGroupFieldBlocBuilder<String>(
                                  selectFieldBloc: formBloc.gender,
                                  isEnabled: false,
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
                                          decoration: InputDecoration(
                                            labelText: 'Country*',
                                            prefixIcon: Icon(Icons.add_location),
                                          ),
                                        ),
                                      ),
                                    ]),
                                DropdownFieldBlocBuilder<String>(
                                    selectFieldBloc: formBloc.relationship,
                                    isEnabled: false,
                                    decoration: InputDecoration(
                                      labelText: 'Managed by*',
                                      helperText: '*Please fill all the fields with the details of the T1D, if your are creating this profile for someone else',
                                      //prefixIcon: Icon(Icons.sentiment_satisfied),
                                    ),
                                    itemBuilder: (context, item) => FieldItem(child: Text(item))),
                                DateTimeFieldBlocBuilder(
                                  dateTimeFieldBloc: formBloc.dob,
                                  isEnabled: false,
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
                                  isEnabled: false,
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
                                Text("*Moving to MDI will lead to deletion of any existing basal rate.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),),
                                SizedBox(height: 10),
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
                                  child: Text('Submit'),
                                ),
                              ]))))));
        }));
  }

  void updateFormBloc(UserProfileFormBloc formBloc) {
    formBloc.isEditFlow.updateInitialValue(true);
    if(this.publicProfile.photoId != null){
      formBloc.photoId.updateInitialValue(this.publicProfile.photoId!);
    }
    formBloc.email.updateInitialValue(this.userProfile.email!);
    formBloc.insulinType.updateInitialValue(this.userProfile.insulinType);
    formBloc.injectionType.updateInitialValue(this.userProfile.injectionType);
    formBloc.bgUnit.updateInitialValue(this.userProfile.bgUnit);
    formBloc.normalBgMin.updateInitialValue(this.userProfile.normalBgMin.toString());
    formBloc.normalBgMax.updateInitialValue(this.userProfile.normalBgMax.toString());
    formBloc.aboutMe.updateInitialValue(this.userProfile.aboutMe!);
    formBloc.firstName.updateInitialValue(this.userProfile.firstName!);
    formBloc.lastName.updateInitialValue(this.userProfile.lastName!);
    //formBloc.pinCode.updateInitialValue(this.userProfile.pinCode!);
    formBloc.city.updateInitialValue(this.userProfile.city!);
    formBloc.cityState.updateInitialValue(this.userProfile.cityState!);
    formBloc.country.updateInitialValue(this.userProfile.country!);
    formBloc.avatarName.updateInitialValue(this.userProfile.avatarName!);
    formBloc.gender.updateInitialValue(this.userProfile.gender!);
    formBloc.relationship.updateInitialValue(this.userProfile.relationship!);
    formBloc.dob.updateInitialValue(DateTime.parse(this.userProfile.dob!).toLocal());
    formBloc.dateOfDetection.updateInitialValue(DateTime.parse(this.userProfile.dateOfDetection!).toLocal());
    formBloc.pumpType.updateInitialValue(this.userProfile.pumpType!);
    formBloc.glucometerType.updateInitialValue(this.userProfile.glucometerType!);
    formBloc.onCgm.updateInitialValue(this.userProfile.onCgm!);
    formBloc.role.updateInitialValue(this.userProfile.role!);
    formBloc.invitationKey.updateInitialValue(' ');
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
              'Profile updated successfully',
              style: TextStyle(fontSize: 54, color: Colors.blue),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context)
                  .pushReplacement(MaterialPageRoute(builder: (_) => MyApp())),
              icon: Icon(Icons.replay),
              label: Text('Home'),
            ),
          ],
        ),
      ),
    );
  }
}
