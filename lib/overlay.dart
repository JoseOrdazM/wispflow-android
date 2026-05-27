import "package:flutter/material.dart";
import "services/overlay_service.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FloatingBubble(),
  ));
}

class FloatingBubble extends StatefulWidget {
  const FloatingBubble({super.key});

  @override
  State<FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<FloatingBubble> {
  final OverlayService _service = OverlayService();
  BubbleState _state = BubbleState.idle;

  @override
  void initState() {
    super.initState();
    _service.stateStream.listen((s) {
      if (mounted) setState(() => _state = s);
    });
  }

  Color _bubbleColor() {
    switch (_state) {
      case BubbleState.idle:
        return Colors.deepPurple;
      case BubbleState.recording:
        return Colors.redAccent;
      case BubbleState.processing:
        return Colors.orange;
    }
  }

  Widget _bubbleContent() {
    switch (_state) {
      case BubbleState.idle:
        return const Icon(Icons.mic, color: Colors.white, size: 28);
      case BubbleState.recording:
        return const Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.stop, color: Colors.white, size: 22),
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ],
        );
      case BubbleState.processing:
        return const SizedBox(
          width: 28,
          height: 28,
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
      onTap: () => _service.onBubbleTap(),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _bubbleColor(),
          boxShadow: [
            BoxShadow(
              color: _bubbleColor().withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: _bubbleContent(),
      ),
    );
  }
}
