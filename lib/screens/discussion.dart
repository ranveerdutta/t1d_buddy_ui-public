
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:t1d_buddy_ui/forms/post.dart';
import 'package:t1d_buddy_ui/screens/YoutubeWidget.dart';
import 'package:t1d_buddy_ui/screens/add_post.dart';
import 'package:t1d_buddy_ui/screens/common_widgets.dart';
import 'package:t1d_buddy_ui/screens/loading_dialog.dart';
import 'package:t1d_buddy_ui/screens/post_details.dart';
import 'package:t1d_buddy_ui/screens/user_info_screen.dart';
import 'package:t1d_buddy_ui/utils/common_utils.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:youtube_player_iframe/youtube_player_iframe.dart';

enum PostFilter { all, bookmarked }

class Discussion extends StatefulWidget {

  const Discussion({Key? key, required User user})
      : _user = user,
        super(key: key);

  final User _user;

  final PostFilter filter = PostFilter.all;

  @override
  _DiscussionState createState() => _DiscussionState();
}

class _DiscussionState extends State<Discussion> {
  late User _user;

  late List<PostHeader> _postHeaderList  = [];

  late DateTime createdAt;

  late int batchSize;

  late List<Widget> cards = [];

  late bool _hasNextPage;

  late bool _isFirstLoadRunning;

  late bool _isLoadMoreRunning;

  late ScrollController _scrollController;

  late PostFilter filter;

  @override
  void initState(){
    super.initState();
    _user = widget._user;
    setState(() {
      filter = PostFilter.all;
      reset();
    });
    _scrollController = new ScrollController()..addListener(_loadMore);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_loadMore);
    super.dispose();
  }


  void reset(){
    _isFirstLoadRunning = true;
    createdAt = DateTime.now();
    _isLoadMoreRunning = false;
    _postHeaderList.clear();
    cards.clear();
    _hasNextPage = true;
    batchSize = 10;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (_isFirstLoadRunning)?
        FutureBuilder<void>(
          future: fetchPostHeaders(),
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: Text('loading...'));
            } else {
              if (snapshot.hasError)
                return Center(child: Text('Error: ${snapshot.error}'));
              else
                return Column();
            }}):
        Column(
          children: [
            //SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                new Radio<PostFilter>(
                  fillColor: MaterialStateColor.resolveWith((states) => Colors.blue),
                  focusColor: MaterialStateColor.resolveWith((states) => Colors.blue),
                  value: PostFilter.all,
                  groupValue: filter,
                  autofocus: true,
                  onChanged: (PostFilter? value) {
                    setState(() {
                      filter = value!;
                      reset();
                    });
                  },
                ),
                new Text(
                  'All',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                SizedBox(width: 100,),
                new Radio<PostFilter>(
                  fillColor: MaterialStateColor.resolveWith((states) => Colors.blue),
                  focusColor: MaterialStateColor.resolveWith((states) => Colors.blue),
                  value: PostFilter.bookmarked,
                  groupValue: filter,
                  onChanged: (PostFilter? value) {
                    setState(() {
                      filter = value!;
                      reset();
                    });
                  },
                ),
                new Text(
                  'Bookmarked',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
            //SizedBox(height: 20,),
            Text("**Please don't follow medical suggestions given by any member in this forum without consulting your Doctor.", style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _postHeaderList.length,
                itemBuilder: (_, index) => new PostHeaderCard(postHeaderList: _postHeaderList, index: index, user: _user),
              ),
            ),

            // when the _loadMore function is running
            if (_isLoadMoreRunning == true)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 40),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // When nothing else to load
            if (_hasNextPage == false)
              Container(
                //padding: const EdgeInsets.only(top: 30, bottom: 40),
                color: Colors.white,
                child: Center(
                  child: Text('All posts displayed'),
                ),
              ),
          ],
        ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => AddPost(user: _user))).then((value){
          setState(() {
          });
        }),
        tooltip: 'Add',
        icon: Icon(Icons.question_answer),
        label: Text('New post'),
      ),
    );
  }

  Future<void> fetchPostHeaders() async {
    final response = await http.get(
      Uri.parse(Environment().config.apiHost +
          '/user/' + this._user.email! +
          '/post-headers/' + filter.name
          +'?created_at=' +
          createdAt.toUtc().toIso8601String() +
          '&batch_size=' +
          batchSize.toString()),
      headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this._user.email!, await Utils.getIdToken(_user)),
    );


    if (response.statusCode == 200) {
      List t = json.decode(response.body);
      List<PostHeader> fetchedPosts = t.map((item) => PostHeader.fromJson(item)).toList();
      _isFirstLoadRunning = false;
      if (fetchedPosts.length > 0) {
        setState(() {
          _postHeaderList.addAll(fetchedPosts);
          createdAt = _postHeaderList[_postHeaderList.length-1].createdAt;
          //List<Widget> generatedCards = new List.generate(_postHeaderList.length, (i)=>new PostHeaderCard(postHeaderList: fetchedPosts, index: i)).toList();
          //cards.addAll(generatedCards);
          if (fetchedPosts.length < batchSize) {
            _hasNextPage = false;
          }
        });
      } else {
        // This means there is no more data
        // and therefore, we will not send another GET request
        setState(() {
          _hasNextPage = false;
        });
      }
    } else {
      throw Exception(response.body);
    }
  }

  void _loadMore() async {
    if (_hasNextPage == true &&
        _isFirstLoadRunning == false &&
        _isLoadMoreRunning == false &&
        _scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent) {
      setState(() {
        _isLoadMoreRunning = true; // Display a progress indicator at the bottom
      });
      fetchPostHeaders();
      setState(() {
        _isLoadMoreRunning = false;
      });
    }
  }

}

class PostHeaderCard extends StatefulWidget {

  const PostHeaderCard({Key? key, required List<PostHeader> postHeaderList, required int index, required User user})
      : _postHeaderList = postHeaderList,
        _index = index,
        _user = user,
        super(key: key);

  final List<PostHeader> _postHeaderList;
  final int _index;
  final User _user;

  @override
  _PostHeaderCardState createState() => _PostHeaderCardState(this._postHeaderList, _index, _user);

}

class _PostHeaderCardState extends State<PostHeaderCard> {

  _PostHeaderCardState(List<PostHeader> postHeaderList, int index, User user)
      : _postHeaderList = postHeaderList,
        _index = index,
        _user = user;

  final List<PostHeader> _postHeaderList;
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
        //height: 150,
          child: Column(
              children: <Widget>[
                SizedBox(height: 10,),
                ListTile(
                  leading: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      this._postHeaderList[_index].useAvatar?
                      null :
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => UserInfoScreen(user: _user, email: this._postHeaderList[_index].authorEmail)));
                    },
                    child: Icon(Icons.person_rounded, color: Colors.blue)
                  ),
                  isThreeLine: true,
                  title: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      this._postHeaderList[_index].useAvatar?
                      null :
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => UserInfoScreen(user: _user, email: this._postHeaderList[_index].authorEmail)));
                    },
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(text: this._postHeaderList[_index].useAvatar? this._postHeaderList[_index].authorAvatar : this._postHeaderList[_index].authorFirstName + ' ' + this._postHeaderList[_index].authorLastName
                                        , style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        TextSpan(text: '\n' + DateFormat("dd-MMM-yy hh:mm aaa").format(this._postHeaderList[_index].createdAt.toLocal()), style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic)),
                      ]))
                  ),

                  subtitle: SelectableText('\n' + _postHeaderList[_index].content, enableInteractiveSelection: true, style: TextStyle(color: Colors.black)),
                ),
                const SizedBox(height: 10),
                this._postHeaderList[_index].imageId.isNotEmpty?
                ClipRect(
                  child: Material(
                    child: CommonWidget.getImage(_postHeaderList[_index].imageId),
                  ),
                )
                    : const SizedBox(height: 10),
                _postHeaderList[_index].videoUrl.isNotEmpty && _postHeaderList[_index].videoUrl != "null"  && YoutubePlayerController.convertUrlToId(_postHeaderList[_index].videoUrl) != null ?
                    YoutubeWidget(videoUrl: _postHeaderList[_index].videoUrl) : const SizedBox(height: 10),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Row(children: <Widget>[
                      _postHeaderList[_index].isLiked ?
                      InkWell(
                        child: Icon(Icons.thumb_up, color: Colors.blue, size: 25),
                        splashColor: Colors.blue.withAlpha(30),
                        onTap: () {
                          deletePostReaction(_postHeaderList[_index].postId);
                        },
                      ) :
                      InkWell(
                        child: Icon(Icons.thumb_up, color: Colors.grey, size: 25),
                        splashColor: Colors.blue.withAlpha(30),
                        onTap: () {
                          reactOnPost(_postHeaderList[_index].postId);
                        },
                      ),
                      Text(this._postHeaderList[_index].reactionCount.toString())]),
                    Row(children: <Widget>[
                      InkWell(
                        child: Icon(Icons.comment, color: Colors.blue, size: 25),
                        splashColor: Colors.blue.withAlpha(30),
                        onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => PostDetails(user: _user, postId: this._postHeaderList[_index].postId,)));
                        },
                      ),
                    Text(this._postHeaderList[_index].responseCount.toString())]),
                  ],
                ),
                const SizedBox(height: 10),
              ]),
      ),
    );


  }

  Future<void> reactOnPost(int postId) async{
    try{
      LoadingDialog.show(context);
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
          _postHeaderList[_index].isLiked = true;
          _postHeaderList[_index].reactionCount = _postHeaderList[_index].reactionCount+1;
        });
      } else {
        throw Exception(response.body);
      }
    }catch(e){
    }finally{
      LoadingDialog.hide(context);
    }

  }

  Future<void> deletePostReaction(int postId) async{
    try{
      LoadingDialog.show(context);
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
          _postHeaderList[_index].isLiked = false;
          _postHeaderList[_index].reactionCount = _postHeaderList[_index].reactionCount-1;
        });
      } else {
        throw Exception(response.body);
      }
    }catch(e){
    }finally{
      LoadingDialog.hide(context);
    }

  }

}