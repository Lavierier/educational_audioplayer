import 'package:educational_audioplayer/ui/common_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';

import '../player.dart';
import '../util/constants.dart';

_BottomPlayerState _playerState;

class BottomPlayer extends CommonPlayer {
  play(List<Audio> audios, int index, {Function setLastAudioMethodLocal}) {
    if (currentAudios.length > 0 &&
        audios[index].url != currentAudios[currentAudioIndex].url) {
      _playerState.stop();
    }
    _playerState.play(audios, index,
        setLastAudioMethodLocal: setLastAudioMethodLocal);
  }

  show() {
    _playerState.show();
  }

  @override
  _BottomPlayerState createState() {
    _playerState = _BottomPlayerState();
    return _playerState;
  }
}

class _BottomPlayerState extends CommonPlayerState {
  bool isHidden = true;

  hide() {
    setState(() {
      isHidden = true;
    });
  }

  show() {
    setState(() {
      isHidden = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !isHidden,
      maintainState: true,
      child: Container(
          color: Theme.of(context).highlightColor,
          padding: EdgeInsets.only(left: playerInset, right: playerInset),
          child: Wrap(children: [
            Column(
              children: <Widget>[
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      IconButton(
                          icon: Icon(
                            Icons.share,
                            size: closeIconSize,
                          ),
                          onPressed: () {
                            Share.share(
                                '${currentAudios[currentAudioIndex].chapterName}\n\n${currentAudios[currentAudioIndex].audioName}\n\n${currentAudios[currentAudioIndex].audioDescription}\n\n${currentAudios[currentAudioIndex].authorName}\n\n${currentAudios[currentAudioIndex].url}');
                          }),
                      Expanded(
                        child: Text(
                          currentAudios[currentAudioIndex].audioName,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: audioNameSize),
                        ),
                      ),
                      IconButton(
                          icon: Icon(
                            Icons.close,
                            size: closeIconSize,
                          ),
                          onPressed: () {
                            audioPlayer.stop();
                            hide();
                            cancelNotification();
                          })
                    ]),
                Text(
                  currentAudios[currentAudioIndex].chapterName,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: chapterNameSize),
                ),
                Text(
                  currentAudios[currentAudioIndex].authorName,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: lecturerNameSize),
                ),
                (duration == null)
                    ? Container()
                    : Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text("${position != null ? positionText : ''}",
                                  style: TextStyle(fontSize: timeSize)),
                              CupertinoSlider(
                                  value: position?.inMilliseconds?.toDouble() ??
                                      0.0,
                                  onChanged: (double value) =>
                                      setPosition(value),
                                  min: 0.0,
                                  max: duration.inMilliseconds.toDouble()),
                              Text(durationText,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontSize: timeSize))
                            ],
                          ),
                        ],
                      ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: Container(),
                    ),
                    IconButton(
                        onPressed: () {
                          playPrevious();
                        },
                        iconSize: iconSize,
                        padding: EdgeInsets.only(
                            left: 0,
                            right: 0,
                            bottom: defaultPadding,
                            top: defaultPadding),
                        icon: Icon(Icons.skip_previous),
                        color: Theme.of(context).accentColor),
                    Expanded(
                      child: Container(),
                    ),
                    IconButton(
                        onPressed: () {
                          addSecondsToPosition(-10);
                        },
                        iconSize: iconSize,
                        padding: EdgeInsets.only(
                            left: 0,
                            right: 0,
                            bottom: defaultPadding,
                            top: defaultPadding),
                        icon: Icon(Icons.replay_10),
                        color: Theme.of(context).accentColor),
                    Expanded(
                      child: Container(),
                    ),
                    IconButton(
                        onPressed: () {
                          isPlaying
                              ? pause()
                              : isPaused
                                  ? resume()
                                  : play(currentAudios, currentAudioIndex);
                        },
                        iconSize: iconSize,
                        padding: EdgeInsets.only(
                            left: 0,
                            right: 0,
                            bottom: defaultPadding,
                            top: defaultPadding),
                        icon: isPlaying
                            ? Icon(Icons.pause)
                            : Icon(Icons.play_arrow),
                        color: Theme.of(context).accentColor),
                    Expanded(
                      child: Container(),
                    ),
                    IconButton(
                        onPressed: () {
                          addSecondsToPosition(10);
                        },
                        iconSize: iconSize,
                        padding: EdgeInsets.only(
                            left: 0,
                            right: 0,
                            bottom: defaultPadding,
                            top: defaultPadding),
                        icon: Icon(Icons.forward_10),
                        color: Theme.of(context).accentColor),
                    Expanded(
                      child: Container(),
                    ),
                    IconButton(
                        onPressed: () {
                          playNext();
                        },
                        iconSize: iconSize,
                        padding: EdgeInsets.only(
                            left: 0,
                            right: 0,
                            bottom: defaultPadding,
                            top: defaultPadding),
                        icon: Icon(Icons.skip_next),
                        color: Theme.of(context).accentColor),
                    Expanded(
                      flex: 5,
                      child: Container(),
                    ),
                  ],
                ),
              ],
            ),
          ])),
    );
  }
}
