import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:t1d_buddy_ui/forms/user_profile.dart';
import 'package:t1d_buddy_ui/utils/common_utils.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';
import 'package:t1d_buddy_ui/utils/shared_preference_util.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class FileUploader extends StatefulWidget {

  ValueChanged<String> fileId;

  FileUploader({Key? key, required User user, required this.fileId})
      : _user = user,
        super(key: key);

  final User _user;

  @override
  State<FileUploader> createState() => _FileUploaderState();

}

class _FileUploaderState extends State<FileUploader>{

  late final User _user;

  late UserProfile _userProfile;

  String? _fileName;
  String? _saveAsFileName;
  String? _fileId;
  List<PlatformFile>? _paths;
  bool _isLoading = false;
  bool _userAborted = false;
  FileType _pickingType = FileType.custom;
  final int max_size = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _user = widget._user;
    _userProfile = SharedPrefUtil.getUserProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _pickFiles() async {
    _resetState();
    try {
      _paths = (await FilePicker.platform.pickFiles(
        type: _pickingType,
        allowMultiple: false,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      ))
          ?.files;
      if (!mounted) return;

      setState(() {
        _fileName = _paths?.first.name;
        _userAborted = _paths == null;
      });
      if(_paths?.first.size != null && _paths?.first.size.compareTo(max_size) == 1){
        throw Exception("file size exceeded the max allowed size");
      }
      _fileId = await uploadFile();

      setState(() {
        widget.fileId(_fileId!);
      });

    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    }finally {
      setState(() {
        _isLoading = false;
      });
      _clearCachedFiles();
    }
  }

  void _clearCachedFiles() async {
    try {
      await FilePicker.platform.clearTemporaryFiles();
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFile() async {
    _resetState();
    try {
      String? fileName = await FilePicker.platform.saveFile(
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        type: _pickingType,
      );
      setState(() {
        _saveAsFileName = fileName;
        _userAborted = fileName == null;
      });
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    } finally {
      setState(() => _isLoading = false);
      _clearCachedFiles();
    }
  }

  Future<String> uploadFile() async {
    try{
      if(_paths?.first.path == null) throw Exception("No file found");
      var url = Uri.parse(Environment().config.apiHost +
          '/user/' + this._user.email.toString() + '/record-file');
      http.MultipartRequest request = new http.MultipartRequest("POST", url);


      http.MultipartFile multipartFile = await http.MultipartFile.fromPath(
          'file', _paths![0].path!);

      request.files.add(multipartFile);

      http.StreamedResponse streamedResponse = await request.send();

      final http.Response response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception('System error' + e.toString());
    }
  }

  void _logException(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _resetState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _fileName = null;
      _paths = null;
      _saveAsFileName = null;
      _userAborted = false;
      _fileId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('File(pdf, jpg, jpeg, or png formats): ', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                        IconButton(onPressed: () => _pickFiles(), icon: Icon(Icons.file_upload, color: Colors.blue))
                        ]
                  ),
                  Text('Max file size 5MB', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  Builder(
                    builder: (BuildContext context) => _isLoading
                        ? Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: const CircularProgressIndicator(),
                    )
                        : _userAborted
                        ? Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: const Text(
                        'User has aborted the upload',
                      ),
                    )
                        : _paths != null && _fileId != null
                        ? Text(_paths!.first.name + ' uploaded', style: TextStyle(color: Colors.blue))
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
    );
  }


}