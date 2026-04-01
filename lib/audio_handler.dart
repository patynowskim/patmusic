import 'package:audio_service/audio_service.dart';

class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  void Function()? onPlay;
  void Function()? onPause;
  void Function()? onSkipToNext;
  void Function()? onSkipToPrevious;
  void Function(Duration)? onSeek;

  @override
  Future<void> play() async => onPlay?.call();

  @override
  Future<void> pause() async => onPause?.call();

  @override
  Future<void> skipToNext() async => onSkipToNext?.call();

  @override
  Future<void> skipToPrevious() async => onSkipToPrevious?.call();

  @override
  Future<void> seek(Duration position) async {
    onSeek?.call(position);
  }
}
