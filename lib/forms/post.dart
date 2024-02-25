
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:t1d_buddy_ui/utils/common_utils.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';
import 'package:t1d_buddy_ui/utils/form_validator.dart';

class PostFormBloc extends FormBloc<String, String> {

  late User user;

  final email = TextFieldBloc();

  /*final title = TextFieldBloc(
    name: 'title',
    validators: [
    FieldBlocValidators.required,
    ]);*/

  final content = TextFieldBloc(
    name: 'description',validators: [
    FieldBlocValidators.required,
  ]);

  final imageId = TextFieldBloc();

  final videoUrl = TextFieldBloc(
    validators: [
      FormValidator.validYoutubeUrl,
    ],
  );

  final useAvatar = BooleanFieldBloc(initialValue: false, name: 'use_avatar');

  PostFormBloc(User _user) {
    this.user = _user;
    addFieldBlocs(
      fieldBlocs: [
        //title,
        content,
        imageId,
        videoUrl,
        useAvatar,
      ],
    );

    @override
    Future<void> close() {
      //title.close();
      content.close();
      imageId.close();
      videoUrl.close();
      useAvatar.close();
      return super.close();
    }
  }

  Map<String, dynamic> toInputJson() => <String, dynamic>{
    //'title': title.value,
    'content': content.value,
    'image_id': imageId.value,
    'video_url': videoUrl.value,
    'use_avatar': useAvatar.value,
  };

  @override
  Future<void> onSubmitting() async {
    try{
      final response = await http.post(
          Uri.parse(Environment().config.apiHost +
              '/user/' + this.email.value + '/post'),
          headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this.email.value, await Utils.getIdToken(user)),
          body: JsonEncoder.withIndent('    ').convert(this.toInputJson(),
          ));

      if (response.statusCode == 200) {
        emitSuccess(
            successResponse: 'Post added successfully');
      } else {
        emitFailure(failureResponse: 'Error occurred, please try again');
      }
    }catch(e){
      emitFailure(failureResponse: 'Error occurred, please try again');
    }

  }

}

class PostHeader{

  late final int postId;

  //late final String title;

  late final String content;

  late final String imageId;

  late final String videoUrl;

  late final DateTime createdAt;

  late final bool useAvatar;

  late final String authorFirstName;

  late final String authorLastName;

  late final String authorAvatar;

  late final String authorEmail;

  late final int responseCount;

  late int reactionCount;

  late bool isLiked;

  late bool isBookmarked;

  PostHeader.fromJson(Map<String, dynamic> json) {
    postId = json['post_id'];
    //title = json['title'];
    content = json['content'];
    imageId = json['image_id'];
    videoUrl = json['video_url'];
    createdAt = DateTime.parse(json['created_at']);
    useAvatar = json['use_avatar'];
    authorFirstName = json['author_first_name'];
    authorLastName = json['author_last_name'];
    authorAvatar = json['author_avatar'];
    authorEmail = json['author_email'];
    responseCount = json['response_count'];
    reactionCount = json['reaction_count'];
    isLiked = json['is_liked'] == null ? false : json['is_liked'];
    isBookmarked = json['is_bookmarked'] == null ? false : json['is_bookmarked'];
  }
}

class PostResponseFormBloc extends FormBloc<String, String> {

  late User user;

  final email = TextFieldBloc();

  final postId = TextFieldBloc();

  final content = TextFieldBloc(
      name: 'Comment',validators: [
    FieldBlocValidators.required,
  ]);

  final useAvatar = BooleanFieldBloc(initialValue: false, name: 'use_avatar');

  PostResponseFormBloc(User _user) {
    this.user = _user;
    addFieldBlocs(
      fieldBlocs: [
        content,
        useAvatar,
      ],
    );

    @override
    Future<void> close() {
      content.close();
      useAvatar.close();
      return super.close();
    }
  }

  Map<String, dynamic> toInputJson() => <String, dynamic>{
    'content': content.value,
    'use_avatar': useAvatar.value
  };

  @override
  Future<void> onSubmitting() async {
    try{
      final response = await http.post(
          Uri.parse(Environment().config.apiHost +
              '/user/' + this.email.value + '/post/' +
          this.postId.value + '/post-response'),
          headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this.email.value, await Utils.getIdToken(user)),
          body: JsonEncoder.withIndent('    ').convert(this.toInputJson(),
          ));

      if (response.statusCode == 200) {
        emitSuccess(
            successResponse: 'Post response added successfully');
      } else {
        emitFailure(failureResponse: 'Error occurred, please try again');
      }
    }catch(e){
      emitFailure(failureResponse: 'Error occurred, please try again');
    }

  }

}

class PostResponse{

  late final int responseId;

  late final String content;

  late final DateTime createdAt;

  late final bool useAvatar;

  late final String authorFirstName;

  late final String authorLastName;

  late final String authorEmail;

  late final String authorAvatar;

  late int reactionCount;

  late bool isLiked;

  PostResponse.fromJson(Map<String, dynamic> json) {
    responseId = json['response_id'];
    content = json['content'];
    createdAt = DateTime.parse(json['created_at']);
    useAvatar = json['use_avatar'];
    authorFirstName = json['author_first_name'];
    authorLastName = json['author_last_name'];
    authorEmail = json['author_email'];
    authorAvatar = json['author_avatar'];
    reactionCount = json['reaction_count'];
    isLiked = json['is_liked'] == null ? false : json['is_liked'];
  }

}
