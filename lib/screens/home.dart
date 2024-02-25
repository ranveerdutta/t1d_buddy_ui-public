import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:t1d_buddy_ui/forms/user_profile.dart';
import 'package:t1d_buddy_ui/screens/common_widgets.dart';
import 'package:t1d_buddy_ui/screens/discussion.dart';
import 'package:t1d_buddy_ui/screens/network.dart';
import 'package:t1d_buddy_ui/screens/timeline.dart';
import 'package:t1d_buddy_ui/screens/tools.dart';
import 'package:t1d_buddy_ui/utils/shared_preference_util.dart';

class Home extends StatefulWidget {
  const Home({Key? key, required User user, int pageIndex=0})
      : _user = user,
        _pageIndex = pageIndex,
        super(key: key);

  final User _user;

  final int _pageIndex;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late User _user;

  late int _pageIndex;
  late PageController _pageController;
  late UserPublicProfile _publicProfile;

  late List<Widget> tabPages;

  @override
  void initState(){
    super.initState();
    _user = widget._user;
    _pageIndex = widget._pageIndex;
    _pageController = PageController(initialPage: _pageIndex);
    _publicProfile = SharedPrefUtil.getPublicProfile();
    tabPages = [
      Timeline(user: _user),
      Discussion(user: _user),
      Network(user: _user),
      Tools(user: _user),

    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonWidget.getCommonHeader(context, _user, _publicProfile),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _pageIndex,
        onTap: onTabTapped,
        unselectedItemColor: Colors.white,
        selectedItemColor: Colors.black,
        backgroundColor: Colors.blue,
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem( icon: Icon(Icons.timeline), label: "Timeline"),
          BottomNavigationBarItem(icon: Icon(Icons.question_answer), label: "Social"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Members"),
          BottomNavigationBarItem(icon: Icon(Icons.engineering), label: "Tools"),
        ],

      ),
      body: PageView(
        children: tabPages,
        onPageChanged: onPageChanged,
        controller: _pageController,
      ),
    );
  }

  void onPageChanged(int page) {
    setState(() {
      this._pageIndex = page;
    });
  }

  void onTabTapped(int index) {
    this._pageController.animateToPage(index,duration: const Duration(milliseconds: 500),curve: Curves.easeInOut);
  }
}


