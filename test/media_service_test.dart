import 'package:audio_service/audio_service.dart';
import 'package:feniksflutter/services/media_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;

void main() {
  late MediaService service;
  late List<String> calls;

  setUp(() {
    calls = [];
    service = MediaService(
      onPlay: () async => calls.add('play'),
      onStop: () async {
        calls.add('stop');
        service.update(playing: false, processing: ProcessingState.idle);
      },
    );
  });

  PlaybackState state() => service.playbackState.value;

  void playing([ProcessingState processing = ProcessingState.ready]) =>
      service.update(playing: true, processing: processing);

  group('MediaService', () {
    test('shows nothing before the radio is first played', () {
      service.update(playing: false, processing: ProcessingState.ready);
      expect(state().playing, isFalse);
      expect(state().processingState, AudioProcessingState.idle);
    });

    test('playing shows a pause button', () {
      playing();
      expect(state().playing, isTrue);
      expect(state().processingState, AudioProcessingState.ready);
      expect(state().controls, [MediaControl.pause]);
    });

    test('a reconnecting stream keeps the service up', () {
      for (final processing in [
        ProcessingState.idle,
        ProcessingState.loading,
        ProcessingState.buffering,
        ProcessingState.completed,
      ]) {
        playing(processing);
        expect(state().playing, isTrue, reason: '$processing');
        expect(
          state().processingState,
          AudioProcessingState.buffering,
          reason: '$processing',
        );
      }
    });

    testWidgets('a paused radio can be started again for 10 minutes', (
      tester,
    ) async {
      playing();
      await service.pause();
      expect(calls, ['stop']);

      await tester.pump(const Duration(minutes: 9, seconds: 59));
      expect(state().processingState, AudioProcessingState.ready);
      expect(state().controls, [MediaControl.play]);

      await service.play();
      expect(calls, ['stop', 'play']);
      playing();
      await tester.pump(const Duration(minutes: 20));
      expect(state().playing, isTrue);
      expect(state().processingState, AudioProcessingState.ready);

      await service.stop();
    });

    testWidgets('the service ends 10 minutes after a pause', (tester) async {
      playing();
      await service.pause();
      await tester.pump(const Duration(minutes: 10));
      expect(state().playing, isFalse);
      expect(state().processingState, AudioProcessingState.idle);
    });

    testWidgets('later player events do not extend the 10 minutes', (
      tester,
    ) async {
      playing();
      await service.pause();
      await tester.pump(const Duration(minutes: 6));
      service.update(playing: false, processing: ProcessingState.idle);
      await tester.pump(const Duration(minutes: 4));
      expect(state().processingState, AudioProcessingState.idle);
    });

    test('stop ends the service right away', () async {
      playing();
      await service.stop();
      expect(calls, ['stop']);
      expect(state().processingState, AudioProcessingState.idle);
    });

    test('swiping the app away keeps a playing radio on', () async {
      playing();
      await service.onTaskRemoved();
      expect(calls, isEmpty);
      expect(state().playing, isTrue);
      await service.stop();
    });

    testWidgets('swiping the app away ends a paused radio', (tester) async {
      playing();
      await service.pause();
      await service.onTaskRemoved();
      expect(state().processingState, AudioProcessingState.idle);
    });

    test('shows the song, with the station name when there is no artist', () {
      service.showSong(title: 'Grijeh', artist: 'Neko');
      expect(service.mediaItem.value?.title, 'Grijeh');
      expect(service.mediaItem.value?.artist, 'Neko');
      service.showSong(title: 'Vijesti', artist: '');
      expect(service.mediaItem.value?.artist, 'Feniks Radio');
    });
  });
}
