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

  void setSettings(AppSettings s) {
    _transcriber = TranscriptionService(s);
  }

  Future<bool> startOverlay() async {
    final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
    if (!hasPermission) {
      await FlutterOverlayWindow.requestPermission();
      return false;
    }
    await FlutterOverlayWindow.showOverlay(
      height: 80,
      width: 80,
      alignment: OverlayAlignment.bottomRight,
      enableDrag: true,
      flag: OverlayFlag.defaultFlag,
      positionGravity: PositionGravity.auto,
    );
    // Listen for bubble taps from the overlay
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data == "bubble:tap") {
        onBubbleTap();
      }
    });
    return true;
  }

  Future<void> stopOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
    _setState(BubbleState.idle);
  }

  Future<void> onBubbleTap() async {
    if (_state == BubbleState.idle) {
      _setState(BubbleState.recording);
      FlutterOverlayWindow.shareData("state:recording");
      await _audio.startRecording();
    } else if (_state == BubbleState.recording) {
      _setState(BubbleState.processing);
      FlutterOverlayWindow.shareData("state:processing");
      final path = await _audio.stopRecording();
      if (path == null || _transcriber == null) {
        _setState(BubbleState.idle);
        FlutterOverlayWindow.shareData("state:idle");
        return;
      }
      try {
        final text = await _transcriber!.transcribe(path);
        await Clipboard.setData(ClipboardData(text: text));
        try { File(path).delete(); } catch (_) {}
        FlutterOverlayWindow.shareData("transcribed:$text");
      } catch (_) {}
      _setState(BubbleState.idle);
      FlutterOverlayWindow.shareData("state:idle");
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
