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

class _WispFlowAppState extends State<WispFlowApp> with WidgetsBindingObserver {
  final OverlayService _overlay = OverlayService();
  AppSettings _settings = AppSettings();
  bool _bubbleActive = false;
  bool _needsPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns from Android settings after granting permission
    if (state == AppLifecycleState.resumed && _needsPermission) {
      _needsPermission = false;
      _tryStartOverlay();
    }
  }

  Future<void> _tryStartOverlay() async {
    final started = await _overlay.startOverlay();
    if (started) {
      setState(() {
        _bubbleActive = true;
        _needsPermission = false;
      });
    } else {
      // Permission requested — user sent to settings
      setState(() {
        _bubbleActive = false;
        _needsPermission = true;
      });
    }
  }

  Future<void> _toggleBubble() async {
    if (_bubbleActive) {
      await _overlay.stopOverlay();
      setState(() => _bubbleActive = false);
    } else {
      await _tryStartOverlay();
    }
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
                if (_needsPermission) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Permiso requerido: activa \"Mostrar sobre otras apps\" para WispFlow en Ajustes, luego pulsa Start Bubble.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.deepOrange),
                    ),
                  ),
                ],
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
