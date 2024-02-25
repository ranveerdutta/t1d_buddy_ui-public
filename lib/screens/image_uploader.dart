import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:t1d_buddy_ui/screens/loading_dialog.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';

class ImageUploader extends StatefulWidget {
  ValueChanged<String> imageId;

  bool isProfilePhoto;

  ImageUploader({Key? key, required User user, required this.imageId, this.isProfilePhoto = false})
      : _user = user,
        super(key: key);

  final User _user;

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}


class _ImageUploaderState extends State<ImageUploader> {
  List<XFile>? _imageFileList;
  late final User _user;

  late final bool isProfilePhoto;

  Future<void> _setImageFileListFromFile(XFile? value) async {
    _imageFileList = value == null ? null : <XFile>[value];
    if(value != null){
      try{
        LoadingDialog.show(context);
        String imageId = await uploadImage();
        widget.imageId(imageId);
        LoadingDialog.hide(context);
      }catch (e) {
        _imageFileList = null;
        LoadingDialog.hide(context);
        throw Exception("Error while uploading image");
      }

    }

  }

  dynamic _pickImageError;

  String? _retrieveDataError;

  final ImagePicker _picker = ImagePicker();

  final double? _width = null;
  final double? _height = null;
  final int? _quality = 25;

  @override
  void initState() {
    super.initState();
    _user = widget._user;
    isProfilePhoto = widget.isProfilePhoto;
  }


  Future<void> _onImageButtonPressed(ImageSource source,
      {BuildContext? context, bool isMultiImage = false}) async {

    if (isMultiImage) {
      _displayPickImageDialog(context!,
              (double? maxWidth, double? maxHeight, int? quality) async {
            try {
              final List<XFile>? pickedFileList = await _picker.pickMultiImage(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
                imageQuality: quality,
              );
              setState(() {
                _imageFileList = pickedFileList;
              });
            } catch (e) {
              setState(() {
                _pickImageError = e;
              });
            }
          });
    } else {

      _displayPickImageDialog(context!,
              (double? maxWidth, double? maxHeight, int? quality) async {
            try {
              final XFile? pickedFile = await _picker.pickImage(
                source: source,
                maxWidth: maxWidth,
                maxHeight: maxHeight,
                imageQuality: quality,
              );
              /*setState(() async {
                await _setImageFileListFromFile(pickedFile);
              });*/
              await _setImageFileListFromFile(pickedFile);
            } catch (e) {
              setState(() {
                _pickImageError = e;
              });
            }
          });
    }
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();
  }


  Widget _previewImages() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_imageFileList != null) {
      return Semantics(
        child: getImage(0),
      );
      /*return Semantics(
        label: 'image_picker_example_picked_images',
        child: ListView.builder(
          key: UniqueKey(),
          itemBuilder: (BuildContext context, int index) {
            // Why network for web?
            // See https://pub.dev/packages/image_picker#getting-ready-for-the-web-platform
            return Semantics(
              label: 'image_picker_example_picked_image',
              child: new Flexible(child: getImage(index)),
            );
          },
          itemCount: _imageFileList!.length,
        ),
      );*/
    } else if (_pickImageError != null) {
      return Text(
        'Pick image error: $_pickImageError',
        textAlign: TextAlign.center,
      );
    } else {
      return const Text('');
    }
  }

  Widget getImage(int index){
    return this.isProfilePhoto?
      kIsWeb?
      ClipOval(
        child: Material(
          child: Image.network(_imageFileList![index].path, fit: BoxFit.fitHeight)
        ),
      )
          : ClipOval(
        child: Material(
            child: Image.file(File(_imageFileList![index].path), fit: BoxFit.fitHeight)
        ),
      )
        :
    kIsWeb?
    ClipRect(
      child: Material(
          child: Image.network(_imageFileList![index].path, fit: BoxFit.fitHeight)
      ),
    )
        : ClipRect(
      child: Material(
          child: Image.file(File(_imageFileList![index].path), fit: BoxFit.fitHeight)
      ),
    );
  }


  Future<void> retrieveLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      /*setState(() {
        if (response.files == null) {
          _setImageFileListFromFile(response.file);
        } else {
          _imageFileList = response.files;
        }
      });*/
      if (response.files == null) {
        _setImageFileListFromFile(response.file);
      } else {
        _imageFileList = response.files;
      }
    } else {
      _retrieveDataError = response.exception!.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(children: <Widget>[
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? FutureBuilder<void>(
          future: retrieveLostData(),
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
                return const Text('');
              case ConnectionState.done:
                return _previewImages();
              default:
                if (snapshot.hasError) {
                  return Text(
                    'Pick image error: ${snapshot.error}}',
                    textAlign: TextAlign.center,
                  );
                } else {
                  return const Text('');
                }
            }
          },
        )
            : _previewImages(),

          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                this.isProfilePhoto? Text('Upload new profile photo: ') : Text('Image: '),
                SizedBox(width: 30),
                Semantics(
                  child: InkWell(
                    onTap: () {
                      _onImageButtonPressed(ImageSource.gallery, context: context);
                    },
                    child: const Icon(Icons.photo, color: Colors.blue),
                  ),
                ),
                /*Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: InkWell(
                  onTap: () {
                    _onImageButtonPressed(
                      ImageSource.gallery,
                      context: context,
                      isMultiImage: true,
                    );
                  },
                  child: const Icon(Icons.photo_library),
                ),

                ),*/
                SizedBox(width: 30),
                Semantics(
                  child: InkWell(
                    onTap: () {
                      _onImageButtonPressed(ImageSource.camera, context: context);
                    },
                    child: const Icon(Icons.camera_alt, color: Colors.blue),
                  ),
                ),
                ]
          ),

          ],

      ),
    );
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Future<void> _displayPickImageDialog(
      BuildContext context, OnPickImageCallback onPick) async {

    onPick(this._width, this._height, this._quality);
  }

  Future<String> uploadImage() async {
    try{
      var url = Uri.parse(Environment().config.apiHost +
          '/user/' + this._user.email.toString() + '/image');
      http.MultipartRequest request = new http.MultipartRequest("POST", url);


      http.MultipartFile multipartFile = await http.MultipartFile.fromPath(
          'file', _imageFileList![0].path);

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
}



typedef OnPickImageCallback = void Function(
    double? maxWidth, double? maxHeight, int? quality);


