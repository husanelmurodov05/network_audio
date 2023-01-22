import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'chat_bubble.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Audio Waveforms",
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  late final RecorderController recorderController;
  String? path;
  String? musicFile;
  bool isRecording = false;
  bool isRecordingCompleted = false;
  bool isLoading = true;
  late Directory appDirectory;
  
  
  @override
  void initState() {
    _getDir();
    super.initState();
  }

  void _getDir() async {
    appDirectory = await getApplicationDocumentsDirectory();
    path = "${appDirectory.path}/recording.m4a";
    isLoading = false;
    setState(() {});

    void _initialiseControllers() {
      recorderController = RecorderController()
        ..androidEncoder = AndroidEncoder.aac
        ..androidOutputFormat = AndroidOutputFormat.mpeg_2_ts
        ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
        ..sampleRate = 44100;
    }
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
     musicFile = result.files.single.path;
      setState(() {});
    } else {
      debugPrint("File not picked");
    }
  }

  @override
  void dispose() {
    recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFF252331),
        appBar: AppBar(
          backgroundColor: Color(0xFF252331),
          elevation: 1,
          centerTitle: true,
          shadowColor: Colors.grey,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/flutter.webp",
               scale: 4.5,
              ),
              SizedBox(
                width: 10.0,
              ),
              Text("Simform "),
            ],
          ),
        ),
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : SafeArea(
                child: Column(
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  Expanded(
                      child: ListView.builder(
                          itemCount: 4,
                          itemBuilder: (_, index) {
                            return WaveBubble(
                              index: index + 1,
                              isSender: index.isOdd,
                              width: MediaQuery.of(context).size.width / 2,
                              isLastWidget:
                                  !isRecordingCompleted || musicFile == null,
                                  appDirectory: appDirectory, 
                            );
                          })),
                  if (isRecordingCompleted)
                    WaveBubble(
                      path: path,
                      isSender: true,
                      isLastWidget: isRecordingCompleted && musicFile == null,
                      appDirectory: appDirectory,
                    ),
                  if (musicFile != null)
                    WaveBubble(
                      path:musicFile,
                      isSender: true,
                      isLastWidget: true,
                      appDirectory: appDirectory,
                    ),
                  SafeArea(
                      child: Row(
                    children: [
                      AnimatedSwitcher(
                          duration: Duration(milliseconds: 200),
                          child: isRecording
                              ? AudioWaveforms(
                                  enableGesture: true,
                                  size: Size(MediaQuery.of(context).size.width/2,50),
                                  recorderController: recorderController,
                                  waveStyle: WaveStyle(
                                    waveColor: Colors.white,
                                    extendWaveform: true,
                                    showMiddleLine: false,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
                                    color: Color(0xFF1E1B26),
                                  ),
                                  padding: EdgeInsets.only(left: 18),
                                  margin: EdgeInsets.symmetric(horizontal: 15),
                                )
                              : Container(
                                  width:
                                      MediaQuery.of(context).size.width / 1.7,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE1B26),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  padding: EdgeInsets.only(left: 18),
                                  margin: EdgeInsets.symmetric(horizontal: 15),
                                  child: TextField(
                                    readOnly: true,
                                    decoration: InputDecoration(
                                        hintText: "Type Something...",
                                        hintStyle:
                                            TextStyle(color: Colors.white54),
                                        contentPadding:
                                            EdgeInsets.only(top: 16),
                                        border: InputBorder.none,
                                        suffixIcon: IconButton(
                                            onPressed: _pickFile,
                                            icon: Icon(Icons.adaptive.share))),
                                  ),
                                )),
                      IconButton(
                          onPressed: _refreshWave,
                          icon: Icon(
                            isRecording ? Icons.refresh : Icons.send,
                            color: Colors.white,
                          )),
                      SizedBox(
                        width: 16,
                      ),
                      IconButton(
                        onPressed: _startOrStopRecording,
                        icon: Icon(isRecording ? Icons.stop : Icons.mic),
                        color: Colors.white,
                        iconSize: 28,
                      )
                    ],
                  ))
                ],
              )));
  }

  void _startOrStopRecording() async {
    try {
      if (isRecording) {
        recorderController.reset();
        final path = await recorderController.stop(false);
        if (path != null) {
          isRecordingCompleted = true;
          debugPrint(path);
          debugPrint("Recorded file size${File(path).lengthSync()}");
        }
      } else {
        await recorderController.record(path: path!);
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isRecording = !isLoading;
      });
    }
  }

  void _refreshWave() {
    if (isRecording) recorderController.refresh();
  }
}
