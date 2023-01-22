import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'dart:async';
import 'dart:io';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isSender;
  final bool isLast;

  const ChatBubble({
    Key? key,
    required this.text,
    this.isSender = false,
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, bottom: 10, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isSender) const Spacer(),
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isSender ? Color(0xFF276BFD) : Color(0xFF3343145)),
                padding:
                    EdgeInsets.only(left: 14, right: 12, top: 8, bottom: 9),
                child: Text(
                  text,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

class WaveBubble extends StatefulWidget {
  final bool isSender;
  final int? index;
  final String? path;
  final double? width;
  final bool isLastWidget;
  final Directory appDirectory;
  const WaveBubble({
    Key? key,
    required this.appDirectory,
    this.width,
    this.path,
    this.index,
    this.isLastWidget = false,
    this.isSender = false,
  }) : super(key: key);

  @override
  State<WaveBubble> createState() => _WaveBubbleState();
}

class _WaveBubbleState extends State<WaveBubble> {
  File? file;
  late PlayerController controller;
  late StreamSubscription<PlayerState> playerStateSubscription;
  final playerWaveStyle = const PlayerWaveStyle(
      fixedWaveColor: Colors.white54, 
      liveWaveColor: Colors.white, spacing: 6);
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = PlayerController();
    _preparePlayer();
    playerStateSubscription = controller.onPlayerStateChanged.listen((_) {
      setState(() {});
    });
  }

  void _preparePlayer() async {
    if (widget.index != null) {
      file = File("${widget.appDirectory.path}/audio1${widget.index}.mp3");
      await file?.writeAsBytes(
          (await rootBundle.load('assets/audio/audio2${widget.index}.mp3'))
              .buffer
              .asUint8List());
    }
    if (widget.index == null && widget.path == null && file?.path == null) {
      return;
    }
    controller.preparePlayer(
        path: widget.path ?? file!.path,
        shouldExtractWaveform: widget.index?.isEven ?? true);
    if (widget.index?.isOdd ?? false) {
      controller
          .extractWaveformData(
            path: widget.path ?? file!.path,
            noOfSamples:
                playerWaveStyle.getSamplesForWidth(widget.width ?? 200),
          )
          .then((waveformDate) => debugPrint(waveformDate.toString()));
    }
  }

  @override
  void dispose() {
    playerStateSubscription.cancel();
    if (widget.isLastWidget) {
      controller.stopAllPlayers();
    }
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.path != null || file?.path != null
        ? Align(
            alignment:
                widget.isSender ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.only(
                  bottom: 6, right: widget.isSender ? 0 : 10, top: 6),
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: widget.isSender ? Color(0xFF76bfd) : Color(0xFF343145),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!controller.playerState.isStopped)
                    IconButton(
                      onPressed: () async {
                        controller.playerState.isPlaying
                            ? await controller.pausePlayer()
                            : await controller.startPlayer(
                                finishMode: FinishMode.loop,
                              );
                      },
                      icon: Icon(controller.playerState.isPlaying
                          ? Icons.stop
                          : Icons.play_arrow),
                      color: Colors.white,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                  AudioFileWaveforms(
                    size: Size(MediaQuery.of(context).size.width / 2, 70),
                    playerController: controller,
                    waveformType: widget.index?.isOdd ?? false
                        ? WaveformType.fitWidth
                        : WaveformType.long,
                    playerWaveStyle: playerWaveStyle,
                  ),
                  if (widget.isSender)
                    const SizedBox(
                      width: 10,
                    ),
                ],
              ),
            ),
          )
        : SizedBox.shrink();
  }
}
