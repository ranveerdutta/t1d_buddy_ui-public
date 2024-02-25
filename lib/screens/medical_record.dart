
import 'dart:convert';
import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:t1d_buddy_ui/forms/record.dart';
import 'package:t1d_buddy_ui/screens/add_record.dart';
import 'package:t1d_buddy_ui/screens/loading_dialog.dart';
import 'package:t1d_buddy_ui/utils/common_utils.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';


class MedicalRecord extends StatefulWidget {

  const MedicalRecord({Key? key, required User user})
      : _user = user,
        super(key: key);

  final User _user;

  @override
  _MedicalRecordState createState() => _MedicalRecordState();
}

class _MedicalRecordState extends State<MedicalRecord> {
  late User _user;

  late List<RecordData> _recordDataList;
  final List<Widget> _recordCards  = [];

  @override
  void initState(){
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
        title: Text("Medical records"),
      ),
      body: FutureBuilder<void>(
          future: fetchRecordData(),
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
                          SizedBox(height: 20,),
                          Column(
                            children: _recordCards,
                          ),
                          SizedBox(height: 70,),
                        ]
                    )
                );
            }
          }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => AddRecord(user: _user))).then((value){
              setState(() {
              });
        }),
        tooltip: 'Upload',
        icon: Icon(Icons.file_upload),
        label: Text('New medical record'),
      ),
    );
  }

  Future<void> fetchRecordData() async {
    final response = await http.get(
      Uri.parse(Environment().config.apiHost +
          '/user/' + this._user.email! +
          '/medical-record'),
      headers: Utils.getHttpHeaders('application/json; charset=UTF-8', this._user.email!, await Utils.getIdToken(_user)),
    );


    if (response.statusCode == 200) {
      List t = json.decode(response.body);
      _recordDataList = t.map((item) => RecordData.fromJson(item)).toList();
      _recordCards.clear();
      List<Widget> generatedCards = new List.generate(_recordDataList.length, (i)=>new RecordDataCard(recordDataList: _recordDataList, index: i, user: _user)).toList();
      _recordCards.addAll(generatedCards);
    } else {
      throw Exception(response.body);
    }
  }

}

class RecordDataCard extends StatelessWidget {

  const RecordDataCard({Key? key, required List<RecordData> recordDataList, required int index, required User user})
      : _recordDataList = recordDataList,
        _index = index,
        _user = user,
        super(key: key);

  final List<RecordData> _recordDataList;
  final int _index;
  final User _user;

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
                leading: Icon(Icons.medical_information, color: Colors.blue),
                isThreeLine: true,
                title: Text(this._recordDataList[_index].description),
                subtitle: Text('\n' + DateFormat('dd-MMM-yyyy').format(this._recordDataList[_index].recordDate.toLocal()), style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: IconButton(
                  icon: Icon(Icons.file_download, color: Colors.blue),
                  onPressed: () async {
                    await downloadReport(_recordDataList[_index].fileId, context);
                  },
                )
              ),
              const SizedBox(height: 10),
            ]),
      ),
    );
  }

  Future<void> downloadReport(String fileId, BuildContext context) async {
    try{
      LoadingDialog.show(context);
      final response = await http.get(
          Uri.parse(Environment().config.apiHost + '/file/'+ fileId.toString()),
          headers: Utils.getHttpHeaders('application/json; charset=UTF-8', _user.email, await Utils.getIdToken(_user)),
      );

      if (response.statusCode == 200) {
        String? contentDisp = response.headers['content-disposition'];
        String? fileName = contentDisp?.split('filename=')[1].replaceAll('\"', '');
        //String path = '/storage/emulated/0/Download/';
        String path = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS);
        var bytes = response.bodyBytes;
        File file = File(path + "/" + fileName!);
        await file.writeAsBytes(bytes).then((value) async {
          await Utils.showLocalNotification('Report downloaded', null, value);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Report downloaded')));

      } else {
        throw Exception(response.body);
      }
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error while downloading the medical report.', style: TextStyle(color: Colors.red))));
      throw Exception('System error' + e.toString());
    }finally{
      LoadingDialog.hide(context);
    }

  }
}
