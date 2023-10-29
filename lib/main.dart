// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'package:record/record.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

const String INBOX_FILE_PATH = "/sdcard/phone_inbox.md";
const String VOICE_RECORD_PATH = "/sdcard/inbox_voices";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FocusNode focusNode;
  static const int FOCUS_KEYBOARD_DELAY_HACK = 100;

  late final AudioRecorder audioRecorder;
  bool isRecording = false;
  final StopWatchTimer stopWatchTimer = StopWatchTimer();

  @override
  void initState() {
    super.initState();

    focusNode = FocusNode();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(milliseconds: FOCUS_KEYBOARD_DELAY_HACK), () {
        focusNode.requestFocus();
      });
    });

    audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    audioRecorder.stop();

    focusNode.dispose();
    audioRecorder.dispose;
    stopWatchTimer.dispose();
    super.dispose();
  }

  void _addToInbox(String text) {
    File file = File(INBOX_FILE_PATH);
    file.writeAsStringSync('* $text\n', mode: FileMode.append);

    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(children: [
        TextField(
          onSubmitted: _addToInbox,
          focusNode: focusNode,
          autofocus: false,
        ),
        const Text("or", style: TextStyle(fontSize: 18)),
        // const SizedBox(height: 10),
        Transform.scale(
            scale: 1.25,
            child: ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll<Color>(
                        isRecording ? Colors.red : Colors.white)),
                onPressed: () => toggleRecording(),
                child: isRecording
                    ? const Text("Stop recording")
                    : const Text("Start recording"))),
        if (isRecording)
          StreamBuilder<int>(
            stream: stopWatchTimer.rawTime,
            initialData: stopWatchTimer.rawTime.value,
            builder: (context, snap) {
              final value = snap.data!;
              final displayTime =
                  StopWatchTimer.getDisplayTime(value, hours: false);
              return Text(displayTime);
            },
          ),
      ]),
    );
  }

  toggleRecording() async {
    if (!await audioRecorder.hasPermission()) {
      return;
    }

    if (isRecording) {
      audioRecorder.stop();
      setState(() {
        isRecording = false;
        stopWatchTimer.onStopTimer();
        stopWatchTimer.onResetTimer();
      });

      return;
    }

    Directory(VOICE_RECORD_PATH).create(recursive: true).then((_) {
      var timestamp = DateTime.now().millisecondsSinceEpoch;
      var path = "$VOICE_RECORD_PATH/voice_$timestamp.m4a";
      audioRecorder.start(const RecordConfig(), path: path);
    });

    stopWatchTimer.onStartTimer();

    setState(() {
      isRecording = true;
    });
  }
}
