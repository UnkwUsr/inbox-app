// ignore_for_file: constant_identifier_names

import 'dart:io';
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

const String INBOX_PATH = "/sdcard/txts/phone_inbox";
const String INBOX_MD_PATH = "$INBOX_PATH/inbox.md";
const String INBOX_VOICES_PATH = "$INBOX_PATH/voices";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inbox app',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Inbox app'),
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

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late final AudioRecorder audioRecorder;
  bool isRecording = false;
  final StopWatchTimer stopWatchTimer = StopWatchTimer();
  final textController = TextEditingController();

  late bool saveOnSubmit;
  late bool showFloating = false;

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

    _prefs.then((res) => {
          setState(() {
            saveOnSubmit = res.getBool("save_on_submit") ?? true;
            showFloating = res.getBool("show_floating") ?? false;
          })
        });
  }

  @override
  void dispose() {
    audioRecorder.stop();

    textController.dispose();
    focusNode.dispose();
    audioRecorder.dispose;
    stopWatchTimer.dispose();
    super.dispose();
  }

  void _addToInbox(String text) async {
    if (!await requestStoragePermission()) {
      return;
    }

    File file = File(INBOX_MD_PATH);
    try {
      await file.parent.create(recursive: true);
      file.writeAsStringSync('* $text\n', mode: FileMode.append);
    } catch (e, _) {
      Fluttertoast.showToast(msg: e.toString());
      return;
    }

    // close app
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => [
                    PopupMenuItem(
                        child: StatefulBuilder(
                      builder: (_, popupSetState) => CheckboxListTile(
                          title: const Text("Save on press submit button"),
                          value: saveOnSubmit,
                          onChanged: (value) => {
                                popupSetState(() {
                                  saveOnSubmit = !saveOnSubmit;
                                  _prefs.then((prefs) => prefs.setBool(
                                      "save_on_submit", saveOnSubmit));
                                })
                              }),
                    )),
                    PopupMenuItem(
                        child: StatefulBuilder(
                      builder: (_, popupSetState) => CheckboxListTile(
                          title: const Text("Show floating save button"),
                          value: showFloating,
                          onChanged: (value) {
                            popupSetState(() {
                              showFloating = !showFloating;
                              _prefs.then((prefs) =>
                                  prefs.setBool("show_floating", showFloating));
                            });
                            // this need to rebuild whole widget with updated
                            // showFloating
                            setState(() {});
                          }),
                    )),
                  ]),
        ],
      ),
      floatingActionButton: Visibility(
        visible: showFloating,
        child: FloatingActionButton(
          onPressed: () => {_addToInbox(textController.text)},
          tooltip: 'Save note',
          child: const Icon(Icons.note_add),
        ),
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(5.0),
          child: TextField(
            onSubmitted: (text) => {if (saveOnSubmit) _addToInbox(text)},
            controller: textController,
            // do not hide keyboard on submitting (hack)
            onEditingComplete: () {},
            // make autofocus (hack)
            focusNode: focusNode,
            autofocus: false,
            // make wrap long lines (kind of hack)
            minLines: 1,
            maxLines: 20,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
          ),
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
      Fluttertoast.showToast(msg: "Please grant Microphone permission");
      return;
    }
    if (!await requestStoragePermission()) {
      return;
    }

    if (isRecording) {
      audioRecorder.stop();
      setState(() {
        isRecording = false;
        stopWatchTimer.onStopTimer();
        stopWatchTimer.onResetTimer();
        WakelockPlus.disable();

        // close app
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      });

      return;
    }

    try {
      await Directory(INBOX_VOICES_PATH).create(recursive: true);
    } catch (e, _) {
      Fluttertoast.showToast(msg: e.toString());
      return;
    }

    (() async {
      var datetime = formatDateTime(DateTime.now());
      var path = "$INBOX_VOICES_PATH/voice_$datetime.m4a";
      File file = File(path);
      var config = const RecordConfig();

      final stream = await audioRecorder.startStream(config);
      stream.listen(
        (data) {
          try {
            file.writeAsBytesSync(data, mode: FileMode.append);
          } catch (e, _) {
            Fluttertoast.showToast(msg: e.toString());
            return;
          }
        },
        // onDone: () => print('End of stream'),
        onError: (e) => Fluttertoast.showToast(msg: e.toString()),
      );
    })();

    stopWatchTimer.onStartTimer();
    // hide keyboard
    focusNode.unfocus();
    // keep screen on while recording
    WakelockPlus.enable();

    setState(() {
      isRecording = true;
    });
  }
}

// YYYY-MM-DD_hh-mm-ss
String formatDateTime(DateTime datetime) {
  // ignore: prefer_interpolation_to_compose_strings
  return datetime
          .toString()
          .split(":")
          .take(2)
          .join("-")
          .replaceFirst(" ", "_") +
      "-" +
      datetime.second.toString().padLeft(2, '0');
}

Future<bool> requestStoragePermission() async {
  var sdkVersion = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
  if (sdkVersion < 30) {
    if (await Permission.storage.request().isGranted) {
      return true;
    }
  } else {
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }
  }

  Fluttertoast.showToast(msg: "Please grant Storage permission");
  return false;
}
