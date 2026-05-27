import "package:flutter/material.dart";
import "../models/settings.dart";

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;
  final Function(AppSettings) onSaved;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSaved,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;
  late TextEditingController _apiCtrl;
  late TextEditingController _urlCtrl;

  final _languages = {
    "auto": "Auto-detect", "es": "Español", "en": "English",
    "fr": "Français", "de": "Deutsch", "pt": "Português",
    "it": "Italiano", "ja": "日本語", "zh": "中文",
  };

  @override
  void initState() {
    super.initState();
    _settings = AppSettings(
      backend: widget.settings.backend,
      openaiApiKey: widget.settings.openaiApiKey,
      customServerUrl: widget.settings.customServerUrl,
      language: widget.settings.language,
      bubbleEnabled: widget.settings.bubbleEnabled,
    );
    _apiCtrl = TextEditingController(text: _settings.openaiApiKey);
    _urlCtrl = TextEditingController(text: _settings.customServerUrl);
  }

  @override
  void dispose() {
    _apiCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _save() {
    _settings.openaiApiKey = _apiCtrl.text;
    _settings.customServerUrl = _urlCtrl.text;
    _settings.save();
    widget.onSaved(_settings);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Settings saved")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("WispFlow Settings"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text("Save",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text("Enable Floating Bubble"),
            subtitle: const Text("Show overlay"),
            value: _settings.bubbleEnabled,
            onChanged: (v) => setState(() => _settings.bubbleEnabled = v),
          ),
          const Divider(),
          const Text("Backend",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          RadioListTile<TranscriptionBackend>(
            title: const Text("OpenAI Whisper"),
            subtitle: const Text("Requires API key"),
            value: TranscriptionBackend.openai,
            groupValue: _settings.backend,
            onChanged: (v) => setState(() => _settings.backend = v!),
          ),
          RadioListTile<TranscriptionBackend>(
            title: const Text("Custom Server"),
            subtitle: const Text("Your own server"),
            value: TranscriptionBackend.custom,
            groupValue: _settings.backend,
            onChanged: (v) => setState(() => _settings.backend = v!),
          ),
          if (_settings.backend == TranscriptionBackend.openai)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextField(
                controller: _apiCtrl,
                decoration: const InputDecoration(
                  labelText: "OpenAI API Key",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
                obscureText: true,
              ),
            ),
          if (_settings.backend == TranscriptionBackend.custom)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: "Server URL",
                  hintText: "https://...",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.dns),
                ),
              ),
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _settings.language,
            decoration: const InputDecoration(
              labelText: "Language",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.language),
            ),
            items: _languages.keys.map((k) {
              return DropdownMenuItem(value: k, child: Text(_languages[k]!));
            }).toList(),
            onChanged: (v) => setState(() => _settings.language = v ?? "auto"),
          ),
        ],
      ),
    );
  }
}
