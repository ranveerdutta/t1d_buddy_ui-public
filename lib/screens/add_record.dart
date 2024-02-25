import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as speechToText;
import 'package:t1d_buddy_ui/forms/record.dart';
import 'package:t1d_buddy_ui/screens/file_uploader.dart';
import 'package:t1d_buddy_ui/screens/loading_dialog.dart';
import 'package:t1d_buddy_ui/screens/medical_record.dart';

class AddRecord extends StatefulWidget {
  const AddRecord({Key? key, required User user})
      : _user = user,
        super(key: key);

  final User _user;

  @override
  _AddRecordState createState() => _AddRecordState();
}

class _AddRecordState extends State<AddRecord> {

  late User _user;

  late speechToText.SpeechToText speech;
  bool isListen = false;
  late RecordFormBloc _formBloc;
  String currText = "";

  late FocusNode titleFocusNode;
  late FocusNode contentFocusNode;
  late TextFieldBloc editField;
  TextFieldBloc emptyField = new TextFieldBloc();

  @override
  void initState() {
    super.initState();
    _user = widget._user;

  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New record"),
      ),
      body: BlocProvider(
          create: (context) => RecordFormBloc(_user),
          child: Builder(builder: (context) {
            final formBloc = BlocProvider.of<RecordFormBloc>(context);
            _formBloc = formBloc;
            formBloc.email.updateInitialValue(_user.email!);
            return Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                child: Scaffold(
                    body: FormBlocListener<RecordFormBloc, String, String>(
                        onSubmitting: (context, state) {
                          LoadingDialog.show(context);
                        },
                        onSuccess: (context, state) {
                          LoadingDialog.hide(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(state.successResponse!)));
                          Navigator.of(context).pop(
                              MaterialPageRoute(
                                  builder: (_) => MedicalRecord(user: _user)));
                        },
                        onFailure: (context, state) {
                          LoadingDialog.hide(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(state.failureResponse!), backgroundColor: Colors.red));
                        },
                        child: SingleChildScrollView(
                            physics: ClampingScrollPhysics(),
                            child: Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Column(children: <Widget>[
                                  FileUploader(user: this._user, fileId: (fileId) {
                                    formBloc.fileId.updateInitialValue(fileId);
                                  }),
                                  SizedBox(height: 10),
                                  TextFieldBlocBuilder(
                                    textFieldBloc: formBloc.description,
                                    textCapitalization: TextCapitalization.sentences,
                                    decoration: InputDecoration(
                                      labelText: 'Description*',
                                    ),
                                    maxLength: 50,
                                  ),
                                  DateTimeFieldBlocBuilder(
                                    dateTimeFieldBloc: formBloc.consultationDate,
                                    format: DateFormat('dd-MM-yyyy'),
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                    decoration: InputDecoration(
                                      labelText: 'Consultation date*',
                                      prefixIcon: Icon(Icons.calendar_today),
                                    ),
                                  ),
                                  SizedBox(width: 40),
                                  ElevatedButton(
                                    onPressed: formBloc.submit,
                                    child: Text('Add record'),
                                  ),
                                ]))))));
          })),
      resizeToAvoidBottomInset: false,
      );
  }


}
