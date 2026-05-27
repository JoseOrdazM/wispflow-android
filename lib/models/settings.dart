import "package:shared_preferences/shared_preferences.dart";

enum TranscriptionBackend { openai, custom }

class AppSettings {
  TranscriptionBackend backend;
  String openaiApiKey;
  String customServerUrl;
  String language;
  bool bubbleEnabled;

  AppSettings({
    this.backend = TranscriptionBackend.openai,
    this.openaiApiKey = "",
    this.customServerUrl = "",
    this.language = "auto",
    this.bubbleEnabled = true,
  });

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString("backend", backend.name);
    await p.setString("openai_api_key", openaiApiKey);
    await p.setString("custom_server_url", customServerUrl);
    await p.setString("language", language);
    await p.setBool("bubble_enabled", bubbleEnabled);
  }

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AppSettings(
      backend: p.getString("backend") == "custom"
          ? TranscriptionBackend.custom
          : TranscriptionBackend.openai,
      openaiApiKey: p.getString("openai_api_key") ?? "",
      customServerUrl: p.getString("custom_server_url") ?? "",
      language: p.getString("language") ?? "auto",
      bubbleEnabled: p.getBool("bubble_enabled") ?? true,
    );
  }
}
