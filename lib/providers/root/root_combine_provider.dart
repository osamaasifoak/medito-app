import 'package:Medito/constants/constants.dart';
import 'package:Medito/models/models.dart';
import 'package:Medito/providers/providers.dart';
import 'package:Medito/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

final rootCombineProvider = Provider.family<void, BuildContext>((ref, context) {
  var audioPlayerProvider = ref.read(audioPlayerNotifierProvider);
  audioPlayerProvider.initAudioHandler();
  ref.read(remoteStatsProvider);
  ref.read(authProvider.notifier).saveFcmTokenEvent();
  ref.read(postLocalStatsProvider);
  ref.read(deviceAppAndUserInfoProvider);
  ref.read(pageviewNotifierProvider).addListenerToPage();
  ref
      .read(playerProvider.notifier)
      .getCurrentlyPlayingTrack(isPlayAudio: false);

  var streamEvent = audioPlayerProvider.trackAudioPlayer.playerStateStream
      .map((event) => event.processingState)
      .distinct();
  streamEvent.forEach((element) {
    if (element == ProcessingState.completed) {
      _handleAudioCompletion(ref);
      _handleUserNotSignedIn(ref, context);
    }
  });
});

void _handleAudioCompletion(
  Ref ref,
) {
  final audioProvider = ref.read(audioPlayerNotifierProvider);
  var extras = ref.read(audioPlayerNotifierProvider).mediaItem.value?.extras;
  if (extras != null) {
    ref.read(playerProvider.notifier).handleAudioCompletionEvent(
          extras['fileId'],
          extras['trackId'],
        );

    audioProvider.seekValueFromSlider(0);
    audioProvider.pause();
    ref.invalidate(packProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioPlayPauseStateProvider.notifier).state =
          PLAY_PAUSE_AUDIO.PAUSE;
    });
  }
}

void _handleUserNotSignedIn(Ref ref, BuildContext context) {
  var _user = ref.read(authProvider.notifier).userRes.body as UserTokenModel;
  if (_user.email == null) {
    var params = JoinRouteParamsModel(screen: Screen.track);
    context.push(
      RouteConstants.joinIntroPath,
      extra: params,
    );
  }
}