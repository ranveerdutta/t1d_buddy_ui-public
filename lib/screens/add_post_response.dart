import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:t1d_buddy_ui/forms/post.dart';
import 'package:t1d_buddy_ui/screens/loading_dialog.dart';
import 'package:t1d_buddy_ui/screens/post_details.dart';

class AddPostResponse extends StatefulWidget {
  const AddPostResponse({Key? key, required User user, required int postId})
      : _user = user,
        _postId = postId,
        super(key: key);

  final User _user;
  final int _postId;

  @override
  _AddPostResponseState createState() => _AddPostResponseState();
}


class _AddPostResponseState extends State<AddPostResponse> {
  late User _user;

  late int _postId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
            create: (context) => PostResponseFormBloc(_user),
            child: Builder(builder: (context) {
              final formBloc = BlocProvider.of<PostResponseFormBloc>(context);
              formBloc.email.updateInitialValue(_user.email!);
              formBloc.postId.updateInitialValue(_postId.toString());
              return Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: InputDecorationTheme(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  child: Scaffold(
                      body: FormBlocListener<PostResponseFormBloc, String, String>(
                          onSubmitting: (context, state) {
                            LoadingDialog.show(context);
                          },
                          onSuccess: (context, state) {
                            LoadingDialog.hide(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(state.successResponse!)));
                            Navigator.pop(context);
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (_) => PostDetails(user: _user, postId: _postId)));
                          },
                          onFailure: (context, state) {
                            LoadingDialog.hide(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(state.failureResponse!)));
                          },

                              child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(children: <Widget>[
                                    Expanded(
                                      child: TextFieldBlocBuilder(
                                        textFieldBloc: formBloc.content,
                                        textCapitalization: TextCapitalization.sentences,
                                        decoration: InputDecoration(
                                          labelText: 'Comment*',
                                        ),
                                        maxLength: 250,
                                        expands: true,
                                        maxLines: null,
                                        textAlign: TextAlign.justify,
                                      ),
                                    ),
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
                                  ])))));
            }));
  }

  @override
  void initState() {
    super.initState();
    _user = widget._user;
    _postId = widget._postId;
  }
}