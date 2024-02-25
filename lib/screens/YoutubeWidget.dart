
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YoutubeWidget extends StatefulWidget {
  YoutubeWidget({Key? key, required String videoUrl}) :
        _videoUrl = videoUrl,
        super(key: key);

  final String _videoUrl;

  @override
  _YoutubeWidgetState createState() => _YoutubeWidgetState();
}

class _YoutubeWidgetState extends State<YoutubeWidget> {

  late YoutubePlayerController _controller;

  @override
  void initState() {
    _controller = YoutubePlayerController.fromVideoId(
      videoId: YoutubePlayerController.convertUrlToId(widget._videoUrl)!,
      autoPlay: false,
      params: YoutubePlayerParams(
        mute: false,
        showControls: true,
        showFullscreenButton: false,
      ),
    );

    /*_controller.setFullScreenListener(
          (isFullScreen) {
        print('${isFullScreen ? 'Entered' : 'Exited'} Fullscreen.');
      },
    );*/
    super.initState();
  }

  @override
  void dispose(){
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerScaffold(
      controller: _controller,
      builder: (context, player) {
        return Container(child: player);
      },
    );
  }

}

