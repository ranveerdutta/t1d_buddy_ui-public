import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:t1d_buddy_ui/forms/post.dart';
import 'package:t1d_buddy_ui/screens/home.dart';
import 'package:t1d_buddy_ui/screens/image_uploader.dart';
import 'package:t1d_buddy_ui/screens/loading_dialog.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:speech_to_text/speech_to_text.dart' as speechToText;

class AddPost extends StatefulWidget {
  const AddPost({Key? key, required User user})
      : _user = user,
        super(key: key);

  final User _user;

  @override
  _AddPostState createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {

  late User _user;

  late speechToText.SpeechToText speech;
  bool isListen = false;
  late PostFormBloc _formBloc;
  String currText = "";

  //late FocusNode titleFocusNode;
  late FocusNode contentFocusNode;
  late TextFieldBloc editField;
  TextFieldBloc emptyField = new TextFieldBloc();

  @override
  void initState() {
    super.initState();
    _user = widget._user;
    speech = speechToText.SpeechToText();
    editField = emptyField;
    //titleFocusNode = new FocusNode();
    contentFocusNode = new FocusNode();
    
    /*titleFocusNode.addListener(() {
      if(titleFocusNode.hasFocus){
        editField = _formBloc.title;
      }else{
        editField = emptyField;
      }
    });*/

    contentFocusNode.addListener(() {
      if(contentFocusNode.hasFocus){
        editField = _formBloc.content;
      }else{
        editField = emptyField;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    //titleFocusNode.dispose();
    contentFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Add post"),
        ),
        body: BlocProvider(
            create: (context) => PostFormBloc(_user),
            child: Builder(builder: (context) {
              final formBloc = BlocProvider.of<PostFormBloc>(context);
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
                      body: FormBlocListener<PostFormBloc, String, String>(
                          onSubmitting: (context, state) {
                            LoadingDialog.show(context);
                          },
                          onSuccess: (context, state) {
                            LoadingDialog.hide(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(state.successResponse!)));
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (_) => Home(user: _user, pageIndex: 1)));
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
                                    Text("*Please use this forum to share diabetes related posts, ask questions and reply to other member's queries.", style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                                    Text("**Using Avatar will hide your actual name in the post.", style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                                    /*TextFieldBlocBuilder(
                                      textFieldBloc: formBloc.title,
                                      textCapitalization: TextCapitalization.sentences,
                                      decoration: InputDecoration(
                                        labelText: 'Title*',
                                      ),
                                      maxLength: 50,
                                      focusNode: titleFocusNode,
                                    ),*/
                                    SizedBox(
                                      height: 250,
                                      child: TextFieldBlocBuilder(
                                        textFieldBloc: formBloc.content,
                                        textCapitalization: TextCapitalization.sentences,
                                        decoration: InputDecoration(
                                          labelText: 'Description*',
                                        ),
                                        maxLength: 500,
                                        expands: true,
                                        maxLines: null,
                                        textAlign: TextAlign.justify,
                                        focusNode: contentFocusNode,
                                      ),
                                    ),
                                    /*TextFieldBlocBuilder(
                                      textFieldBloc: formBloc.imageUrl,
                                      decoration: InputDecoration(
                                        labelText: 'Image url',
                                      ),
                                    ),*/
                                    ImageUploader(user: this._user, imageId: (imageId) {
                                      formBloc.imageId.updateInitialValue(imageId);
                                    }),
                                    SizedBox(height: 20,),
                                    TextFieldBlocBuilder(
                                      textFieldBloc: formBloc.videoUrl,
                                      decoration: InputDecoration(
                                        labelText: 'Youtube url: ',
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    SwitchFieldBlocBuilder(
                                      booleanFieldBloc: formBloc.useAvatar,
                                      body: Container(
                                        alignment: Alignment.centerLeft,
                                        child: Text('Use Avatar'),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: formBloc.submit,
                                      child: Text('Submit'),
                                    ),
                                  ]))))));
            })),
      resizeToAvoidBottomInset: false,
      floatingActionButton: AvatarGlow(
        animate: isListen && editField != emptyField,
        glowColor: Colors.red,
        endRadius: 65.0,
        duration: Duration(milliseconds: 2000),
        repeatPauseDuration: Duration(milliseconds: 100),
        repeat: true,
        child: FloatingActionButton(
          child: Icon(isListen ? Icons.mic : Icons.mic_none, color: Colors.white),
          backgroundColor: Colors.red,
          onPressed: () {
            listen();
          },
        ),
      ),);
  }


  void listen() async {
    currText = editField.value;
    if (!isListen && editField != emptyField) {
      bool avail = await speech.initialize();
      if (avail) {
        setState(() {
          isListen = true;
        });
        speech.listen(onResult: resultListener);
      }else{
        //print('speech not available');
      }
    } else {
      setState(() {
        isListen = false;
      });
      speech.stop();
    }
  }

  void resultListener(value){
    setState(() {
      String textString = value.recognizedWords;
      //print(textString);
      editField.updateValue(currText + textString);
      /*if (value.hasConfidenceRating && value.confidence > 0) {
              print(value.confidence);
            }*/
      if(!speech.isListening){
        isListen = false;
        speech.stop();
      }
    });
  }

}
