import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_overlay_window/flutter_overlay_window.dart";
import "models/settings.dart";
import "screens/settings_screen.dart";
import "services/overlay_service.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WispFlowApp());
}

class WispFlowApp extends StatefulWidget {
  const WispFlowApp({super.key});

  @override
  State<WispFlowApp> createState() => _WispFlowAppState();
}

class _WispFlowAppState extends State<WispFlowApp> {
  final OverlayService _overlay = OverlayService();
  AppSettings _settings = AppSettings();
  bool _bubbleActive = false;

  @override
  void initState() {
    super.initState();
    AppSettings.load().then((s) {
      _settings = s;
      _overlay.setSettings(s);
      if (mounted) setState(() {});
    });
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is String && event.startsWith("transcribed:")) {
        final text = event.substring(12);
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Transcription"),
              content: SelectableText(text),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Copied")),
                    );
                  },
                  child: const Text("Copy"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Close"),
                ),
              ],
            ),
          );
        }
      }
    });
  }

  Future<void> _toggleBubble() async {
    if (_bubbleActive) {
      await _overlay.stopOverlay();
    } else {
      await _overlay.startOverlay();
    }
    setState(() => _bubbleActive = !_bubbleActive);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "WispFlow",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("WispFlow"),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mic,
                  size: 80,
                  color: _bubbleActive ? Colors.deepPurple : Colors.grey,
                ),
                const SizedBox(height: 24),
                Text(
                  "WispFlow",
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Floating voice transcription",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _toggleBubble,
                    icon: Icon(
                        _bubbleActive ? Icons.stop_circle : Icons.play_circle),
                    label: Text(
                      _bubbleActive ? "Stop" : "Start Bubble",
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _bubbleActive ? Colors.red : Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                            settings: _settings,
                            onSaved: (s) {
                              _settings = s;
                              _overlay.setSettings(s);
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text("Settings",
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Tap bubble to record\nTap again to transcribe",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
