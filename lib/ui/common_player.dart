import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../player.dart';
import '../util/constants.dart';
import '../util/loader.dart';

List<Audio> currentAudios = [Audio(url: '')];
int currentAudioIndex = 0;
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

class CommonPlayer extends StatefulWidget {
  @override
  CommonPlayerState createState() {
    return CommonPlayerState();
  }
}

class CommonPlayerState extends State<CommonPlayer> {
  AudioPlayer audioPlayer;
  Duration duration;
  Duration position;
  Function setLastAudioMethod;

  AudioPlayerState playerState = AudioPlayerState.STOPPED;

  get isPlaying => playerState == AudioPlayerState.PLAYING;
  get isPaused => playerState == AudioPlayerState.PAUSED;

  get durationText => duration != null
      ? '${duration.inMinutes.toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}'
      : '';
  get positionText => position != null
      ? '${position.inMinutes.toString().padLeft(2, '0')}:${position.inSeconds.remainder(60).toString().padLeft(2, '0')}'
      : '';

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    try {
      initNotifications();
    } catch (Exception) {}
  }

  @override
  void dispose() {
    audioPlayer.stop();

    try {
      cancelNotification();
    } catch (Exception) {}

    super.dispose();
  }

  Future play(List<Audio> audios, int index,
      {Function setLastAudioMethodLocal}) async {
    _updateName(audios, index,
        setLastAudioMethodLocal: setLastAudioMethodLocal);

    try {
      cancelNotification();
      showNotification(pauseNotification);
    } catch (Exception) {}

    String path = await getLocalPath(audios[index].url);
    if ((await File(path).exists())) {
      _playLocal(path);
    } else {
      _playNetwork(audios[index].url);
    }
  }

  Future pause() async {
    try {
      cancelNotification();
      showNotification(playNotification);
    } catch (Exception) {}
    await audioPlayer.pause();
  }

  Future stop() async {
    await audioPlayer.stop();
    setState(() {
      position = Duration();
    });
  }

  Future resume() async {
    try {
      cancelNotification();
      showNotification(pauseNotification);
    } catch (Exception) {}
    await audioPlayer.resume();
  }

  Future playNext() async {
    if (currentAudioIndex + 1 < currentAudios.length) {
      if (isPlaying) {
        await audioPlayer.stop();
        setState(() {
          position = Duration(seconds: 0);
        });
        _updateName(currentAudios, currentAudioIndex + 1);
        play(currentAudios, currentAudioIndex);
      } else {
        await audioPlayer.stop();
        setState(() {
          position = Duration(seconds: 0);
        });
        _updateName(currentAudios, currentAudioIndex + 1);
      }
    }
  }

  Future playPrevious() async {
    if (currentAudioIndex - 1 > -1) {
      if (isPlaying) {
        await audioPlayer.stop();
        setState(() {
          position = Duration(seconds: 0);
        });
        _updateName(currentAudios, currentAudioIndex - 1);
        play(currentAudios, currentAudioIndex);
      } else {
        await audioPlayer.stop();
        setState(() {
          position = Duration(seconds: 0);
        });
        _updateName(currentAudios, currentAudioIndex - 1);
      }
    }
  }

  addSecondsToPosition(double seconds) {
    setState(() {
      Duration newPosition =
          Duration(seconds: (position.inSeconds + seconds).toInt());
      if (newPosition.inSeconds < 0) {
        newPosition = Duration(seconds: 0);
      }
      if (newPosition <= duration) {
        audioPlayer.seek(newPosition);
        position = newPosition;
      }
    });
  }

  setPosition(double value) {
    setState(() {
      Duration newPosition = Duration(milliseconds: value.toInt());
      if (newPosition <= duration) {
        audioPlayer.seek(newPosition);
        position = Duration(milliseconds: value.toInt());
      }
    });
  }

  _updateName(List<Audio> audios, int index,
      {Function setLastAudioMethodLocal}) {
    setState(() {
      currentAudios = audios;
      currentAudioIndex = index;
    });
    if (setLastAudioMethodLocal is Function) {
//      print('setLastAudioMethodLocal is function');
      setLastAudioMethod = setLastAudioMethodLocal;
      setLastAudioMethod(audios[index].url);
    } else if (setLastAudioMethod is Function) {
//      print('setLastAudioMethodLocal is not function');
//      print('setLastAudioMethod is function');
      setLastAudioMethod(audios[index].url);
    } else {
//      print('setLastAudioMethod is not function');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  _initAudioPlayer() {
    audioPlayer = AudioPlayer();

    audioPlayer.onDurationChanged.listen((Duration d) {
      if (mounted) {
        setState(() {
          duration = d;
        });
      }
    });
    audioPlayer.onAudioPositionChanged.listen((Duration d) {
      if (mounted) {
        setState(() {
          position = d;
        });
      }
    });

    audioPlayer.onPlayerCompletion.listen((event) {
      onComplete();
    });

    audioPlayer.onPlayerStateChanged.listen((AudioPlayerState s) {
      setState(() => playerState = s);
    });

    audioPlayer.onPlayerError.listen((msg) {
      stop();
      setState(() {
        duration = Duration(seconds: 0);
        position = Duration(seconds: 0);
      });
      _showPlayFailDialog(context);
    });
  }

  Future _playNetwork(String url) async {
    await audioPlayer.play(url);
  }

  Future _playLocal(String path) async {
    await audioPlayer.play(path, isLocal: true);
  }

  Future onComplete() async {
    if (currentAudioIndex + 1 < currentAudios.length) {
      setState(() {
        position = Duration(seconds: 0);
      });
      _updateName(currentAudios, currentAudioIndex + 1);
      play(currentAudios, currentAudioIndex);
    }
  }

  void _showPlayFailDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text(
              playFailedDialogTitle,
              textAlign: TextAlign.center,
            ),
            content: Text(
              playFailedDialogInfo,
              textAlign: TextAlign.center,
            ));
      },
    );
  }

  initNotifications() {
    // initialise notification plugin
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future<void> onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {}

  Future<void> onSelectNotification(String payload) async {
    if (payload == pauseNotification) {
      pause();
    }
    if (payload == playNotification) {
      resume();
    }
  }

  Future<void> showNotification(payload) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelName,
        notificationChannelDescription,
        playSound: false,
        enableVibration: false,
        styleInformation: DefaultStyleInformation(true, true));
    var iOSPlatformChannelSpecifics =
        IOSNotificationDetails(presentSound: false);
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    String title = '';
    if (payload == pauseNotification) {
      title = pauseNotificationTitle;
    }
    if (payload == playNotification) {
      title = playNotificationTitle;
    }

    await flutterLocalNotificationsPlugin.show(
        0, title, notificationBody, platformChannelSpecifics,
        payload: payload);
  }

  Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }
}
