import 'dart:async';
import 'package:flutter/material.dart';

class TypewriterSlogan extends StatefulWidget {
  const TypewriterSlogan({super.key});

  @override
  State<TypewriterSlogan> createState() => _TypewriterSloganState();
}

class _TypewriterSloganState extends State<TypewriterSlogan>
    with SingleTickerProviderStateMixin {
  final List<String> _phrases = [
    "Your Archive.",
    "Films. Memories. Time.",
  ];
  int _phraseIndex = 0;
  String _currentText = "";
  int _charIndex = 0;
  Timer? _timer;
  bool _isDeleting = false;

  AnimationController? _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);

    // Start typing after a short delay
    _timer = Timer(const Duration(milliseconds: 500), _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cursorController?.dispose();
    super.dispose();
  }

  void _tick() {
    final currentPhrase = _phrases[_phraseIndex];

    if (_isDeleting) {
      // Deleting logic
      if (_charIndex > 0) {
        _charIndex--;
        setState(() {
          _currentText = currentPhrase.substring(0, _charIndex);
        });
        _timer = Timer(const Duration(milliseconds: 50), _tick);
      } else {
        // Finished deleting, move to next phrase
        _isDeleting = false;
        _phraseIndex = (_phraseIndex + 1) % _phrases.length;
        _timer = Timer(const Duration(milliseconds: 500), _tick);
      }
    } else {
      // Typing logic
      if (_charIndex < currentPhrase.length) {
        _charIndex++;
        setState(() {
          _currentText = currentPhrase.substring(0, _charIndex);
        });
        _timer = Timer(const Duration(milliseconds: 100), _tick);
      } else {
        // Finished typing, pause then delete
        _isDeleting = true;
        _timer = Timer(const Duration(milliseconds: 2000), _tick);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _currentText,
          style: TextStyle(
            fontFamily: 'BitcountGridDoubleInk',
            fontSize: 16, // Adjusted to fit nicely
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        // Cursor
        AnimatedBuilder(
          animation: _cursorController!,
          builder: (context, child) {
            return Opacity(
              opacity:
                  ((_cursorController!.value * 2).toInt() % 2 == 0) ? 1 : 0,
              child: Text(
                "_",
                style: TextStyle(
                  fontFamily: 'BitcountGridDoubleInk',
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
