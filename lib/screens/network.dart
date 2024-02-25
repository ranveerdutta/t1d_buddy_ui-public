
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:t1d_buddy_ui/forms/user_profile.dart';
import 'package:t1d_buddy_ui/screens/loading_dialog.dart';
import 'package:t1d_buddy_ui/screens/user_info_screen.dart';
import 'package:t1d_buddy_ui/services/user_services.dart';
import 'package:t1d_buddy_ui/utils/common_utils.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';

enum MemberFilter { all, follower, following }

class Network extends StatefulWidget {

  const Network({Key? key, required User user})
      : _user = user,
        super(key: key);

  final User _user;

  final MemberFilter filter = MemberFilter.all;

  @override
  _NetworkState createState() => _NetworkState();
}

class _NetworkState extends State<Network> {
  late User _user;

  late List<MemberDetails> _memberList  = [];

  late DateTime createdAt;

  late int batchSize;

  late List<Widget> cards = [];

  late bool _hasNextPage;

  late bool _isFirstLoadRunning;

  late bool _isLoadMoreRunning;

  late ScrollController _scrollController;

  late MemberFilter filter;

  @override
  void initState(){
    super.initState();
    _user = widget._user;
    setState(() {
      filter = MemberFilter.all;
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
    _memberList.clear();
    cards.clear();
    _hasNextPage = true;
    batchSize = 10;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (_isFirstLoadRunning)?
      FutureBuilder<void>(
          future: fetchMemberList(),
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
          SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              new Radio<MemberFilter>(
                fillColor: MaterialStateColor.resolveWith((states) => Colors.blue),
                focusColor: MaterialStateColor.resolveWith((states) => Colors.blue),
                value: MemberFilter.all,
                groupValue: filter,
                autofocus: true,
                onChanged: (MemberFilter? value) {
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
              SizedBox(width: 10,),
              new Radio<MemberFilter>(
                fillColor: MaterialStateColor.resolveWith((states) => Colors.blue),
                focusColor: MaterialStateColor.resolveWith((states) => Colors.blue),
                value: MemberFilter.follower,
                groupValue: filter,
                onChanged: (MemberFilter? value) {
                  setState(() {
                    filter = value!;
                    reset();
                  });
                },
              ),
              new Text(
                'Followers',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              SizedBox(width: 10,),
              new Radio<MemberFilter>(
                fillColor: MaterialStateColor.resolveWith((states) => Colors.blue),
                focusColor: MaterialStateColor.resolveWith((states) => Colors.blue),
                value: MemberFilter.following,
                groupValue: filter,
                onChanged: (MemberFilter? value) {
                  setState(() {
                    filter = value!;
                    reset();
                  });
                },
              ),
              new Text(
                'Following',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          SizedBox(height: 10,),
          if(_memberList.length == 0)
            Center(child: Text("No members found", style: TextStyle(color: Colors.grey))),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _memberList.length,
              itemBuilder: (_, index) => new MemberDetailsCard(memberDetailsList: _memberList, index: index, user: _user),
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
                child: Text('All members displayed'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> fetchMemberList() async {
    final response = await http.get(
      Uri.parse(Environment().config.apiHost +
          '/user/' + this._user.email! +
          '/member-list/' + filter.name
          +'?created_at=' +
          createdAt.toUtc().toIso8601String() +
          '&batch_size=' +
          batchSize.toString()),
      headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this._user.email!, await Utils.getIdToken(_user)),
    );


    if (response.statusCode == 200) {
      List t = json.decode(response.body);
      List<MemberDetails> fetchedPosts = t.map((item) => MemberDetails.fromJson(item)).toList();
      _isFirstLoadRunning = false;
      if (fetchedPosts.length > 0) {
        setState(() {
          _memberList.addAll(fetchedPosts);
          createdAt = _memberList[_memberList.length-1].createdAt;
          //List<Widget> generatedCards = new List.generate(_postHeaderList.length, (i)=>new PostHeaderCard(postHeaderList: fetchedPosts, index: i)).toList();
          //cards.addAll(generatedCards);
          if(fetchedPosts.length < batchSize){
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
      fetchMemberList();
      setState(() {
        _isLoadMoreRunning = false;
      });
    }
  }

}

class MemberDetailsCard extends StatefulWidget {

  const MemberDetailsCard({Key? key, required List<MemberDetails> memberDetailsList, required int index, required User user})
      : _memberDetailsList = memberDetailsList,
        _index = index,
        _user = user,
        super(key: key);

  final List<MemberDetails> _memberDetailsList;
  final int _index;
  final User _user;

  @override
  State<StatefulWidget> createState() => _MemberDetailsCardState(_memberDetailsList, _user, _index);


}

class _MemberDetailsCardState extends State<MemberDetailsCard> {

  _MemberDetailsCardState(List<MemberDetails> memberDetailsList, User user, int index)
      : _index = index,
        _user = user,
        _memberDetailsList = memberDetailsList;

  final List<MemberDetails> _memberDetailsList;
  final int _index;
  final User _user;

  @override
  Widget build(BuildContext context) {
    return new Card(
      elevation: 10,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: SizedBox(
        width: double.infinity,
        child: Column(
            children: <Widget>[
              ListTile(
                leading: InkWell(
                    onTap: () {
                      Navigator.push(context,
                      MaterialPageRoute(builder: (context) => UserInfoScreen(user: _user, email: this._memberDetailsList[_index].email)));
                    },
                    child: getProfileImage(this._memberDetailsList[_index].profilePhotoId),
                ),
                title: InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => UserInfoScreen(user: _user, email: this._memberDetailsList[_index].email)));
                  },
                  child: Center(
                    child: Text(this._memberDetailsList[_index].firstName + ' ' + this._memberDetailsList[_index].lastName, style: TextStyle(color: Colors.blue))
                )),
                subtitle: InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => UserInfoScreen(user: _user, email: this._memberDetailsList[_index].email)));
                  },
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(this._memberDetailsList[_index].gender + '/' + this._memberDetailsList[_index].age.toString() + ' yrs'),
                    Text(this._memberDetailsList[_index].city + ', ' + this._memberDetailsList[_index].country),
                  ],
                )),
                trailing: ElevatedButton(
                  child: _memberDetailsList[_index].follow == true ? Text("Unfollow") : Text("Follow"),
                  onPressed: () {
                    if(_memberDetailsList[_index].follow == true)
                      unfollow(_memberDetailsList[_index].email);
                    else
                      follow(_memberDetailsList[_index].email);
                  },
                  style: ElevatedButton.styleFrom(
                    primary: _memberDetailsList[_index].follow == true ? Colors.grey : Colors.blue,
                  ),
                ),
                //Text(this._memberDetailsList[_index].city + ', ' + this._memberDetailsList[_index].country),
              ),
              const SizedBox(height: 10),
            ]),
      ),
      //),
    );
  }

  Widget getProfileImage(String? photoId){
    return
      photoId == null || photoId == ''?
      ClipOval(
          child: SizedBox.fromSize(
            size: Size.fromRadius(30),
              child: Icon(Icons.person, size: 50,),
        ),
      )
          : ClipOval(
        child: SizedBox.fromSize(
            size: Size.fromRadius(30),
            child: CachedNetworkImage(
              imageUrl: UserService.getProfilePhotoUrl(photoId),
              fit: BoxFit.cover,
              placeholder: (context,url) => CircularProgressIndicator(),
              errorWidget: (context,url,error) => new Icon(Icons.person),
            )
        ),
      );
  }

  Future<void> follow(String email) async {
    try{
      LoadingDialog.show(context);
      final response = await http.post(
          Uri.parse(Environment().config.apiHost +
              '/user/' +
              _user.email! +
              '/follow/' + email),
          headers: Utils.getHttpHeaders('application/json; charset=UTF-8', _user.email!, await Utils.getIdToken(_user)),
          body: JsonEncoder.withIndent('    ').convert(
              <String, dynamic>{}
          )
      );
      LoadingDialog.hide(context);
      if (response.statusCode == 200) {
        setState(() {
          _memberDetailsList[_index].follow = true;
        });
      } else {
        throw Exception(response.body);
      }
    }catch(e){
      e.toString();
      LoadingDialog.hide(context);
    }

  }

  Future<void> unfollow(String email) async {
    try{
      LoadingDialog.show(context);
      final response = await http.post(
          Uri.parse(Environment().config.apiHost +
              '/user/' +
              _user.email! +
              '/unfollow/' + email),
          headers: Utils.getHttpHeaders('application/json; charset=UTF-8', _user.email!, await Utils.getIdToken(_user)),
          body: JsonEncoder.withIndent('    ').convert(
              <String, dynamic>{}
          )
      );
      LoadingDialog.hide(context);
      if (response.statusCode == 200) {
        setState(() {
            _memberDetailsList[_index].follow = false;
        });
      } else {
        throw Exception(response.body);
      }
    }catch(e){
      e.toString();
      LoadingDialog.hide(context);
    }

  }
}



