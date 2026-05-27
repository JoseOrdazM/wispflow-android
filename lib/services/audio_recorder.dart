import "dart:io";
import "package:record/record.dart";

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _outputPath;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    final dir = Directory.systemTemp;
    _outputPath = "${dir.path}/wf_${DateTime.now().millisecondsSinceEpoch}.wav";
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _outputPath!,
    );
  }

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  void dispose() {
    _recorder.dispose();
  }
}
