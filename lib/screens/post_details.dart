
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:t1d_buddy_ui/forms/post.dart';
import 'package:t1d_buddy_ui/screens/YoutubeWidget.dart';
import 'package:t1d_buddy_ui/screens/add_post_response.dart';
import 'package:t1d_buddy_ui/screens/common_widgets.dart';
import 'package:t1d_buddy_ui/screens/loading_dialog.dart';
import 'package:t1d_buddy_ui/screens/user_info_screen.dart';
import 'package:t1d_buddy_ui/utils/common_utils.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';


class PostDetails extends StatefulWidget {
  const PostDetails({Key? key, required User user, required int postId})
      : _user = user,
        _postId = postId,
        super(key: key);

  final User _user;
  final int _postId;

  @override
  _PostDetailsState createState() => _PostDetailsState();
}

class _PostDetailsState extends State<PostDetails> {
  late User _user;
  late int _postId;

  late PostHeader _postHeader;

  late List<PostResponse> _postResponseList;

  final List<Widget> cards = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Post Details"),
      ),
      body: FutureBuilder<void>(
          future: fetchPostDetails(_postId),
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: Text('loading...'));
            } else {
              if (snapshot.hasError)
                return Center(child: Text('Error: ${snapshot.error}'));
              else
                return SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Card(
                            elevation: 10,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  SizedBox(height: 20),
                                  ListTile(
                                    leading: InkWell(
                                      splashColor: Colors.blue.withAlpha(30),
                                      onTap: () {
                                        this._postHeader.useAvatar?
                                        null :
                                        Navigator.push(context,
                                            MaterialPageRoute(builder: (context) => UserInfoScreen(user: _user, email: this._postHeader.authorEmail)));
                                      },
                                      child: Icon(Icons.person_rounded, color: Colors.blue)
                                    ),
                                    isThreeLine: true,
                                    title: InkWell(
                                      splashColor: Colors.blue.withAlpha(30),
                                      onTap: () {
                                        this._postHeader.useAvatar?
                                        null :
                                        Navigator.push(context,
                                            MaterialPageRoute(builder: (context) => UserInfoScreen(user: _user, email: this._postHeader.authorEmail)));
                                      },
                                      child: RichText(
                                        text: TextSpan(children: [
                                          TextSpan(text: _postHeader.useAvatar? _postHeader.authorAvatar : _postHeader.authorFirstName + ' ' + _postHeader.authorLastName
                                              , style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                          TextSpan(text: '\n' + DateFormat("dd-MMM-yy hh:mm aaa").format(_postHeader.createdAt.toLocal()), style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic)),
                                        ]))
                                    ),
                                    subtitle: SelectableText('\n' + _postHeader.content, enableInteractiveSelection: true, style: TextStyle(color: Colors.black)),
                                  ),
                                  const SizedBox(height: 10),
                                  _postHeader.imageId.isNotEmpty?
                                    ClipRect(
                                      child: Material(
                                          child: CommonWidget.getImage(_postHeader.imageId),
                                      ),
                                    )
                                  : const SizedBox(height: 10),
                                _postHeader.videoUrl.isNotEmpty && _postHeader.videoUrl != "null"  && YoutubePlayerController.convertUrlToId(_postHeader.videoUrl) != null ?
                                      YoutubeWidget(videoUrl: _postHeader.videoUrl) : const SizedBox(height: 10),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      /*Icon(Icons.message, color: Colors.blue),
                                      Text(this._postHeader.responseCount.toString()),
                                      const SizedBox(width: 20),*/
                                      _postHeader.isLiked ?
                                        InkWell(
                                          child: Icon(Icons.thumb_up, color: Colors.blue, size: 30),
                                          splashColor: Colors.blue.withAlpha(30),
                                          onTap: () {
                                            deletePostReaction(_postHeader.postId);
                                          },
                                        ) :
                                        InkWell(
                                          child: Icon(Icons.thumb_up, color: Colors.grey, size: 30),
                                          splashColor: Colors.blue.withAlpha(30),
                                          onTap: () {
                                            reactOnPost(_postHeader.postId);
                                          },
                                        ),
                                      Text(this._postHeader.reactionCount.toString()),
                                      const SizedBox(width: 20),
                                      _postHeader.isBookmarked ?
                                        InkWell(
                                          child: Icon(Icons.bookmark, color: Colors.blue, size: 30),
                                          splashColor: Colors.blue.withAlpha(30),
                                          onTap: () {
                                            removePostBookmark(_postId);
                                          },
                                        ) :
                                        InkWell(
                                          child: Icon(Icons.bookmark, color: Colors.grey, size: 30),
                                          splashColor: Colors.blue.withAlpha(30),
                                          onTap: () {
                                            bookmarkPost(_postId);
                                          },
                                        ),
                                      const SizedBox(width: 20),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('COMMENTS: ', style: TextStyle(color: Colors.blue)),
                          Text('---------------------- ', style: TextStyle(color: Colors.blue)),
                          const SizedBox(height: 10),
                          Column(
                              children: cards,
                          ),
                          SizedBox(height: 70),

                        ]
                    ));
            }}
      ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () =>
            showDialog(
                context: context,
                builder: (BuildContext context) =>
                        Center( //child: Container(height: 600,
                            child: AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5.0))),
                              contentPadding: EdgeInsets.all(0.0),
                              elevation: 5,
                              title: _getCloseButton(context),
                              content: AddPostResponse(user: _user, postId: this._postId),
                    )),

    ),
          tooltip: 'Add',
          icon: Icon(Icons.message),
          label: Text('Respond'),
        )
    );
  }

  _getCloseButton(context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: GestureDetector(
        onTap: () {

        },
        child: Container(
          alignment: FractionalOffset.topRight,
          child: GestureDetector(child: Icon(Icons.clear,color: Colors.black),

            onTap: (){
              Navigator.pop(context);
            },),
        ),
      ),
    );
  }

  Future<void> reactOnPost(int postId) async{
    try{
        Map<String, dynamic> json = <String, dynamic>{
          'reaction_type': 'LIKE'
        };
        final response = await http.post(
            Uri.parse(Environment().config.apiHost +
                '/user/' + _user.email.toString() + '/post/' +
                postId.toString() + '/post-reaction'),
            headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this._user.email!, await Utils.getIdToken(_user)),
            body: JsonEncoder.withIndent('    ').convert(json,
            )
        );


        if (response.statusCode == 200) {
          setState(() {
          });
        } else {
          throw Exception(response.body);
        }
    }catch(e){
    }

  }

  Future<void> deletePostReaction(int postId) async{
    try{
      Map<String, dynamic> json = <String, dynamic>{
        'reaction_type': 'LIKE'
      };
      final response = await http.delete(
          Uri.parse(Environment().config.apiHost +
              '/user/' + _user.email.toString() + '/post/' +
              postId.toString() + '/post-reaction'),
          headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this._user.email!, await Utils.getIdToken(_user)),
          body: JsonEncoder.withIndent('    ').convert(json,
          )
      );


      if (response.statusCode == 200) {
        setState(() {
        });
      } else {
        throw Exception(response.body);
      }
    }catch(e){
    }

  }

  Future<void> bookmarkPost(int postId) async{
    try{
      final response = await http.post(
          Uri.parse(Environment().config.apiHost +
              '/user/' + _user.email.toString() + '/post/' +
              postId.toString() + '/post-bookmark'),
          headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this._user.email!, await Utils.getIdToken(_user)),
      );


      if (response.statusCode == 200) {
        setState(() {
        });
      } else {
        throw Exception(response.body);
      }
    }catch(e){
    }

  }

  Future<void> removePostBookmark(int postId) async{
    try{
      final response = await http.delete(
        Uri.parse(Environment().config.apiHost +
            '/user/' + _user.email.toString() + '/post/' +
            postId.toString() + '/post-bookmark'),
        headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this._user.email!, await Utils.getIdToken(_user)),
      );


      if (response.statusCode == 200) {
        setState(() {
        });
      } else {
        throw Exception(response.body);
      }
    }catch(e){
    }

  }

  @override
  void initState(){
    super.initState();
    _user = widget._user;
    _postId = widget._postId;
  }

  Future<void> fetchPostDetails(int postId) async {
    final response = await http.get(
      Uri.parse(Environment().config.apiHost +
          '/user/' + _user.email.toString() +
          '/post-details/' + postId.toString()),
      headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this._user.email!, await Utils.getIdToken(_user)),
    );

    if (response.statusCode == 200) {
      _postHeader = PostHeader.fromJson(json.decode(response.body)['post_header']);
      List t = json.decode(response.body)['post_response_list'];
      _postResponseList = t.map((item) => PostResponse.fromJson(item)).toList();
      cards.clear();
      List<Widget> generatedCards = new List.generate(_postResponseList.length, (i)=>new PostResponseCard(postResponseList: _postResponseList, index: i, user: _user,)).toList();
      cards.addAll(generatedCards);
    } else {
      throw Exception(response.body);
    }

  }

}

class PostResponseCard extends StatefulWidget {

  const PostResponseCard({Key? key, required List<PostResponse> postResponseList, required int index, required User user})
      : _postResponseList = postResponseList,
        _index = index,
        _user = user,
        super(key: key);

  final List<PostResponse> _postResponseList;
  final int _index;
  final User _user;

  @override
  _PostResponseCardState createState() => _PostResponseCardState(_postResponseList, _user, _index);

}

class _PostResponseCardState extends State<PostResponseCard> {
  _PostResponseCardState(List<PostResponse> postResponseList, User user, int index)
   : _index = index,
    _user = user,
    _postResponseList = postResponseList;



  final List<PostResponse> _postResponseList;
  final int _index;
  final User _user;


  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Card(
      elevation: 10,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 10),
            InkWell(
              splashColor: Colors.blue.withAlpha(30),
              onTap: () {
                this._postResponseList[_index].useAvatar?
                null :
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => UserInfoScreen(user: _user, email: this._postResponseList[_index].authorEmail)));
              },
              child: Text('~' + (this._postResponseList[_index].useAvatar ? this._postResponseList[_index].authorAvatar : this._postResponseList[_index].authorFirstName + ' ' + this._postResponseList[_index].authorLastName), style: TextStyle(fontSize: 10, color: Colors.blue)),
            ),
            const SizedBox(height: 10),
            SelectableText(this._postResponseList[_index].content, enableInteractiveSelection: true),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(DateFormat("dd-MMM-yy HH:mm aaa").format(this._postResponseList[_index].createdAt.toLocal()), style: TextStyle(fontSize: 10, color: Colors.grey)),
                SizedBox(width: 20),
                _postResponseList[_index].isLiked ?
                InkWell(
                  child: Icon(Icons.thumb_up, color: Colors.blue, size: 30),
                  splashColor: Colors.blue.withAlpha(30),
                  onTap: () {
                    removeResponseReaction(_postResponseList[_index].responseId);
                  },
                ) :
                InkWell(
                  child: Icon(Icons.thumb_up, color: Colors.grey, size: 30),
                  splashColor: Colors.blue.withAlpha(30),
                  onTap: () {
                    reactOnResponse(_postResponseList[_index].responseId);
                  },
                ),
                SizedBox(width: 5),
                Text(this._postResponseList[_index].reactionCount.toString(), style: TextStyle(color: Colors.grey)),
                SizedBox(width: 20),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> reactOnResponse(int responseId) async{
    try{
        LoadingDialog.show(context);
        Map<String, dynamic> json = <String, dynamic>{
          'reaction_type': 'LIKE'
        };
        final response = await http.post(
            Uri.parse(Environment().config.apiHost +
                '/user/' + _user.email.toString() + '/response/' +
                responseId.toString() + '/response-reaction'),
            headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this._user.email!, await Utils.getIdToken(_user)),
            body: JsonEncoder.withIndent('    ').convert(json,
            )
        );


        if (response.statusCode == 200) {
          setState(() {
            _postResponseList[_index].isLiked = true;
            _postResponseList[_index].reactionCount = _postResponseList[_index].reactionCount+1;
          });

        } else {
          throw Exception(response.body);
        }
        LoadingDialog.hide(context);
    }catch(e){
      LoadingDialog.hide(context);
    }

  }

  Future<void> removeResponseReaction(int responseId) async{
    try{
      LoadingDialog.show(context);
      Map<String, dynamic> json = <String, dynamic>{
        'reaction_type': 'LIKE'
      };
      final response = await http.delete(
          Uri.parse(Environment().config.apiHost +
              '/user/' + _user.email.toString() + '/response/' +
              responseId.toString() + '/response-reaction'),
          headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this._user.email!, await Utils.getIdToken(_user)),
          body: JsonEncoder.withIndent('    ').convert(json,
          )
      );


      if (response.statusCode == 200) {
        setState(() {
          _postResponseList[_index].isLiked = false;
          _postResponseList[_index].reactionCount = _postResponseList[_index].reactionCount-1;
        });

      } else {
        throw Exception(response.body);
      }
      LoadingDialog.hide(context);
    }catch(e){
      LoadingDialog.hide(context);
    }

  }

}