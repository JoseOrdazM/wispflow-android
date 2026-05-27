import "package:http/http.dart" as http;
import "../models/settings.dart";

class TranscriptionService {
  final AppSettings settings;
  TranscriptionService(this.settings);

  Future<String> transcribe(String audioPath) async {
    if (settings.backend == TranscriptionBackend.openai) {
      return _openAI(audioPath);
    }
    return _custom(audioPath);
  }

  Future<String> _openAI(String path) async {
    final req = http.MultipartRequest(
      "POST",
      Uri.parse("https://api.openai.com/v1/audio/transcriptions"),
    );
    req.headers["Authorization"] = "Bearer ${settings.openaiApiKey}";
    req.fields["model"] = "whisper-1";
    req.fields["response_format"] = "text";
    if (settings.language != "auto") {
      req.fields["language"] = settings.language;
    }
    req.files.add(await http.MultipartFile.fromPath("file", path));
    final res = await req.send();
    if (res.statusCode != 200) {
      throw Exception("OpenAI error ${res.statusCode}");
    }
    return (await res.stream.bytesToString()).trim();
  }

  Future<String> _custom(String path) async {
    final req = http.MultipartRequest(
      "POST",
      Uri.parse(settings.customServerUrl),
    );
    req.fields["language"] = settings.language;
    req.files.add(await http.MultipartFile.fromPath("file", path));
    final res = await req.send();
    if (res.statusCode != 200) {
      throw Exception("Server error ${res.statusCode}");
    }
    return (await res.stream.bytesToString()).trim();
  }
}
