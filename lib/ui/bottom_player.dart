import 'package:flutter/material.dart';

import '../util/constants.dart';
import '../util/player.dart';

_BottomSheetPlayerState _playerState;

class BottomPlayer extends Player {
  play(
      {List<String> urls,
      int index,
      List<String> names,
      String lecturerName,
      String chapterName}) {
    if (currentAudioUrls.length > 0 &&
        urls[index] != currentAudioUrls[currentAudioIndex]) {
      _playerState.stop();
    }
    _playerState.play(
        urls: urls,
        index: index,
        names: names,
        chapterName: chapterName,
        lecturerName: lecturerName);
  }

  hide() {
    _playerState.hide();
  }

  show() {
    _playerState.show();
  }

  @override
  _BottomSheetPlayerState createState() {
    _playerState = _BottomSheetPlayerState();
    return _playerState;
  }
}

class _BottomSheetPlayerState extends PlayerState {
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
          padding: EdgeInsets.all(playerInset),
          child: Wrap(children: [
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: playerInset),
                  child: Text(
                    currentChapterName,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: chapterNameSize),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: playerInset),
                  child: Text(
                    currentLecturerName,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: lecturerNameSize),
                  ),
                ),
                Text(
                  audioName,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: audioNameSize),
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
                              Slider(
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
                    IconButton(
                        onPressed: () {
                          playPrevious();
                        },
                        iconSize: iconSize,
                        icon: Icon(Icons.skip_previous),
                        color: buttonColor),
                    IconButton(
                        onPressed: () {
                          changePosition(-10);
                        },
                        iconSize: iconSize,
                        icon: Icon(Icons.replay_10),
                        color: buttonColor),
                    IconButton(
                        onPressed: () {
                          isPlaying
                              ? pause()
                              : play(
                                  urls: currentAudioUrls,
                                  index: currentAudioIndex,
                                  names: currentAudioNames);
                        },
                        iconSize: iconSize,
                        icon: isPlaying
                            ? Icon(Icons.pause)
                            : Icon(Icons.play_arrow),
                        color: buttonColor),
                    IconButton(
                        onPressed: () {
                          changePosition(10);
                        },
                        iconSize: iconSize,
                        icon: Icon(Icons.forward_10),
                        color: buttonColor),
                    IconButton(
                        onPressed: () {
                          playNext();
                        },
                        iconSize: iconSize,
                        icon: Icon(Icons.skip_next),
                        color: buttonColor),
                  ],
                )
              ],
            ),
          ])),
    );
  }
}
