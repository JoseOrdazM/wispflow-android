import "dart:async";
import "dart:io";
import "package:flutter/services.dart";
import "package:flutter_overlay_window/flutter_overlay_window.dart";
import "audio_recorder.dart";
import "transcription_service.dart";
import "../models/settings.dart";

enum BubbleState { idle, recording, processing }

class OverlayService {
  static final OverlayService _instance = OverlayService._();
  factory OverlayService() => _instance;
  OverlayService._();

  final AudioRecorderService _audio = AudioRecorderService();
  TranscriptionService? _transcriber;
  BubbleState _state = BubbleState.idle;
  final _stateController = StreamController<BubbleState>.broadcast();

  Stream<BubbleState> get stateStream => _stateController.stream;
  BubbleState get currentState => _state;

  void setSettings(AppSettings s) {
    _transcriber = TranscriptionService(s);
  }

  /// Returns true if overlay was shown, false if permission is missing
  Future<bool> startOverlay() async {
    final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
    if (!hasPermission) {
      await FlutterOverlayWindow.requestPermission();
      // requestPermission opens Android settings — user must grant and come back
      return false;
    }
    await FlutterOverlayWindow.showOverlay(
      height: 80,
      width: 80,
      alignment: OverlayAlignment.topRight,
      enableDrag: true,
      flag: OverlayFlag.defaultFlag,
    );
    return true;
  }

  Future<void> stopOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }

  Future<void> onBubbleTap() async {
    if (_state == BubbleState.idle) {
      await _audio.startRecording();
      _setState(BubbleState.recording);
    } else if (_state == BubbleState.recording) {
      _setState(BubbleState.processing);
      final path = await _audio.stopRecording();
      if (path == null || _transcriber == null) {
        _setState(BubbleState.idle);
        return;
      }
      try {
        final text = await _transcriber!.transcribe(path);
        await Clipboard.setData(ClipboardData(text: text));
        try { File(path).delete(); } catch (_) {}
        _setState(BubbleState.idle);
        await FlutterOverlayWindow.shareData("transcribed:$text");
      } catch (e) {
        _setState(BubbleState.idle);
      }
    }
  }

  void _setState(BubbleState s) {
    _state = s;
    _stateController.add(s);
  }

  void dispose() {
    _stateController.close();
    _audio.dispose();
  }
}
