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

  get durationText =>
      duration != null ? duration.toString().split('.').first : '';
  get positionText =>
      position != null ? position.toString().split('.').first : '';

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

  void setStoppedState() {
    setState(() => playerState = AudioPlayerState.STOPPED);
  }

  void setPausedState() {
    setState(() => playerState = AudioPlayerState.PAUSED);
  }

  void playingState() {
    setState(() => playerState = AudioPlayerState.PLAYING);
  }

  void completedState() {
    setState(() => playerState = AudioPlayerState.COMPLETED);
  }

  Future play(List<Audio> audios, int index,
      {Function setLastAudioMethodLocal}) async {
    currentAudios = audios;
    currentAudioIndex = index;

    if (setLastAudioMethodLocal is Function) {
      setLastAudioMethod = setLastAudioMethodLocal;
      setLastAudioMethod(audios[index].url);
    }
    _updateName(audios[index].authorName);

    try {
      showNotification();
    } catch (Exception) {}

    String path = await getLocalPath(audios[index].url);
    if ((await File(path).exists())) {
      _playLocal(path);
    } else {
      _playNetwork(audios[index].url);
    }
  }

  Future pause() async {
    await audioPlayer.pause();
    setPausedState();
  }

  Future stop() async {
    await audioPlayer.stop();
    setStoppedState();
    setState(() {
      position = Duration();
    });
  }

  Future playNext() async {
    if (currentAudioIndex + 1 < currentAudios.length) {
      if (isPlaying) {
        await audioPlayer.stop();
        setState(() {
          duration = Duration(seconds: 0);
          position = Duration(seconds: 0);
        });
        currentAudioIndex++;
        play(currentAudios, currentAudioIndex);
      } else {
        await audioPlayer.stop();
        setState(() {
          duration = Duration(seconds: 0);
          position = Duration(seconds: 0);
        });
        currentAudioIndex++;
        await play(currentAudios, currentAudioIndex);
        await stop();
      }
    }
  }

  Future playPrevious() async {
    if (currentAudioIndex - 1 > -1) {
      if (isPlaying) {
        await audioPlayer.stop();
        setState(() {
          duration = Duration(seconds: 0);
          position = Duration(seconds: 0);
        });
        currentAudioIndex--;
        play(currentAudios, currentAudioIndex);
      } else {
        await audioPlayer.stop();
        setState(() {
          duration = Duration(seconds: 0);
          position = Duration(seconds: 0);
        });
        currentAudioIndex--;
        await play(currentAudios, currentAudioIndex);
        await stop();
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

  _updateName(String name) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  _initAudioPlayer() {
    audioPlayer = AudioPlayer();

    audioPlayer.onDurationChanged.listen((Duration d) {
      if (mounted) {
        duration = Duration(seconds: 0);
        setState(() {
          duration = d;
        });
      }
    });
    audioPlayer.onAudioPositionChanged.listen((Duration d) {
      if (mounted) {
        position = Duration(seconds: 0);
        setState(() {
          position = d;
        });
      }
    });

    audioPlayer.onPlayerCompletion.listen((event) {
      onComplete();
      setState(() {
        position = duration;
      });
    });

    audioPlayer.onPlayerStateChanged.listen((AudioPlayerState s) {
      setState(() => playerState = s);
    });

    audioPlayer.onPlayerError.listen((msg) {
      setStoppedState();
      setState(() {
        duration = Duration(seconds: 0);
        position = Duration(seconds: 0);
      });
      _showPlayFailDialog(context);
    });
  }

  Future _playNetwork(String url) async {
    await audioPlayer.play(url);
    playingState();
  }

  Future _playLocal(String path) async {
    await audioPlayer.play(path, isLocal: true);
    playingState();
  }

  onComplete() {
    if (currentAudioIndex + 1 < currentAudios.length) {
      currentAudioIndex++;
      play(currentAudios, currentAudioIndex);
    } else {
      setStoppedState();
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
    pause();
  }

  Future<void> showNotification() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelName,
        notificationChannelDescription,
        playSound: false,
        enableVibration: false,
        ongoing: true,
        styleInformation: DefaultStyleInformation(true, true));
    var iOSPlatformChannelSpecifics =
        IOSNotificationDetails(presentSound: false);
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, notificationTitle, notificationBody, platformChannelSpecifics);
  }

  Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }
}
