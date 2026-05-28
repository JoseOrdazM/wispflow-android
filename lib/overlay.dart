import "dart:async";
import "package:flutter/material.dart";
import "package:flutter_overlay_window/flutter_overlay_window.dart";

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayBubble(),
  ));
}

class OverlayBubble extends StatefulWidget {
  const OverlayBubble({super.key});
  @override
  State<OverlayBubble> createState() => _OverlayBubbleState();
}

enum _BubbleState { idle, recording, processing }

class _OverlayBubbleState extends State<OverlayBubble> {
  _BubbleState _state = _BubbleState.idle;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is String) {
        if (mounted) {
          setState(() {
            if (data == "state:recording") {
              _state = _BubbleState.recording;
            } else if (data == "state:processing") {
              _state = _BubbleState.processing;
            } else if (data == "state:idle") {
              _state = _BubbleState.idle;
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Color get _color {
    switch (_state) {
      case _BubbleState.idle:
        return Colors.deepPurple;
      case _BubbleState.recording:
        return Colors.red;
      case _BubbleState.processing:
        return Colors.orange;
    }
  }

  Widget get _icon {
    switch (_state) {
      case _BubbleState.idle:
        return const Icon(Icons.mic, color: Colors.white, size: 30);
      case _BubbleState.recording:
        return const Icon(Icons.stop, color: Colors.white, size: 28);
      case _BubbleState.processing:
        return const SizedBox(
          width: 26, height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FlutterOverlayWindow.shareData("bubble:tap");
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color,
            boxShadow: [
              BoxShadow(
                color: _color.withOpacity(0.5),
                blurRadius: 14,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Center(child: _icon),
        ),
      ),
    );
  }
}
