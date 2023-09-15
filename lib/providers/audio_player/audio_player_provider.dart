import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:Medito/main.dart';
import 'package:Medito/models/models.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final audioPlayerNotifierProvider =
    ChangeNotifierProvider<AudioPlayerNotifier>((ref) {
  return audioHandler;
});

//ignore:prefer-match-file-name
class AudioPlayerNotifier extends BaseAudioHandler
    with QueueHandler, SeekHandler, ChangeNotifier {
  var backgroundSoundAudioPlayer = AudioPlayer();
  TrackFilesModel? currentlyPlayingTrack;
  final hasBgSound = 'hasBgSound';
  final trackAudioPlayer = AudioPlayer();

  late String _contentToken;

  @override
  Future<void> pause() async {
    pauseBackgroundSound();
    unawaited(trackAudioPlayer.pause());
  }

  @override
  Future<void> play() async {
    var checkBgAudio = mediaItemHasBGSound();
    if (checkBgAudio) {
      playBackgroundSound();
    } else {
      pauseBackgroundSound();
    }
    unawaited(trackAudioPlayer.play());
  }

  @override
  Future<void> stop() async {
    unawaited(trackAudioPlayer.stop());
    if (mediaItemHasBGSound()) {
      stopBackgroundSound();
    }
  }

  void setContentToken(String token) {
    _contentToken = token;
  }

  void initAudioHandler() {
    trackAudioPlayer.playbackEventStream
        .map(_transformEvent)
        .pipe(playbackState);
  }

  void setBackgroundAudio(BackgroundSoundsModel sound) {
    unawaited(
      backgroundSoundAudioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(sound.path),
          headers: {
            HttpHeaders.authorizationHeader: _contentToken,
          },
        ),
      ),
    );
  }

  void setTrackAudio(
    TrackModel trackModel,
    TrackFilesModel file, {
    String? filePath,
  }) {
    if (filePath != null) {
      unawaited(trackAudioPlayer.setFilePath(filePath));
      setMediaItem(trackModel, file, filePath: filePath);
    } else {
      setMediaItem(trackModel, file);
      unawaited(
        trackAudioPlayer.setAudioSource(AudioSource.uri(
          Uri.parse(file.path),
          headers: {
            HttpHeaders.authorizationHeader: _contentToken,
          },
        )),
      );
    }
  }

  void playBackgroundSound() {
    backgroundSoundAudioPlayer.play();
    backgroundSoundAudioPlayer.setLoopMode(LoopMode.all);
  }

  void pauseBackgroundSound() {
    backgroundSoundAudioPlayer.pause();
  }

  void stopBackgroundSound() {
    backgroundSoundAudioPlayer.stop();
  }

  void setTrackAudioSpeed(double speed) {
    trackAudioPlayer.setSpeed(speed);
  }

  void seekValueFromSlider(int duration) {
    trackAudioPlayer.seek(Duration(milliseconds: duration));
  }

  void stopTrack() {
    trackAudioPlayer.stop();
  }

  void skipForward30Secs() async {
    var seekDuration = trackAudioPlayer.position.inMilliseconds +
        Duration(seconds: 30).inMilliseconds;
    await trackAudioPlayer.seek(Duration(milliseconds: seekDuration));
  }

  void skipBackward10Secs() async {
    var seekDuration = max(
      0,
      trackAudioPlayer.position.inMilliseconds -
          Duration(seconds: 10).inMilliseconds,
    );
    await trackAudioPlayer.seek(Duration(milliseconds: seekDuration));
  }

  void setBackgroundSoundVolume(double volume) async {
    await backgroundSoundAudioPlayer.setVolume(volume / 100);
  }

  void disposeTrackAudio() async {
    await trackAudioPlayer.dispose();
  }

  void setMediaItem(
    TrackModel trackModel,
    TrackFilesModel file, {
    String? filePath,
  }) {
    var item = MediaItem(
      id: filePath ?? file.path,
      title: trackModel.title,
      artist: trackModel.artist?.name,
      duration: Duration(milliseconds: file.duration),
      artUri: Uri.parse(
        trackModel.coverUrl,
      ),
      extras: {
        hasBgSound: trackModel.hasBackgroundSound,
        'trackId': trackModel.id,
        'fileId': file.id,
      },
    );
    mediaItem.add(item);
  }

  bool mediaItemHasBGSound() {
    return mediaItem.value?.extras?[hasBgSound] ?? false;
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (trackAudioPlayer.playing)
          MediaControl.pause
        else
          MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[trackAudioPlayer.processingState]!,
      playing: trackAudioPlayer.playing,
      updatePosition: trackAudioPlayer.position,
      bufferedPosition: trackAudioPlayer.bufferedPosition,
      speed: trackAudioPlayer.speed,
      queueIndex: event.currentIndex,
    );
  }
}