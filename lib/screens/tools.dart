
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:t1d_buddy_ui/screens/cgm_connection.dart';
import 'package:t1d_buddy_ui/screens/medical_record.dart';

class Tools extends StatefulWidget {

  const Tools({Key? key, required User user})
      : _user = user,
        super(key: key);

  final User _user;

  @override
  _ToolsState createState() => _ToolsState();
}

class _ToolsState extends State<Tools> {
  late User _user;

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 50,),
          Card(
            elevation: 10,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: SizedBox(
              width: double.infinity,
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text('Connect with Glimp', style: TextStyle(color: Colors.blue)),
                  SizedBox(width: 50,),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 40),
                      maximumSize: const Size(120, 40),
                    ),
                    onPressed: () =>
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => CgmConnection(user: _user))),
                    child: Text('Connect'),
                  ),
                  SizedBox(width: 50,),
                ],
              ),
            ),
          ),
          SizedBox(height: 30,),
          Card(
            elevation: 10,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: SizedBox(
              width: double.infinity,
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text('Medical records', style: TextStyle(color: Colors.blue)),
                  SizedBox(width: 50,),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 40),
                      maximumSize: const Size(120, 40),
                    ),
                    onPressed: () =>
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => MedicalRecord(user: _user))),
                    child: Text('Storage'),
                  ),
                  SizedBox(width: 50,),
                ],
              ),
            ),
          ),
          SizedBox(height: 30,),
          Card(
            elevation: 10,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: SizedBox(
              width: double.infinity,
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text('Report generator', style: TextStyle(color: Colors.blue)),
                  SizedBox(width: 50,),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 40),
                      maximumSize: const Size(120, 40),
                    ),
                    onPressed: null,
                    child: Text('coming soon'),
                  ),
                  SizedBox(width: 50,),
                ],
              ),
            ),
          ),
          SizedBox(height: 30,),
        ],
        );
  }

  @override
  void initState(){
    super.initState();
    _user = widget._user;
  }

}