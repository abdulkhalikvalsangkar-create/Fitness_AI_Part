import 'dart:async';
import 'package:flutter/material.dart';

class RestTimerWidget extends StatefulWidget {
  final Duration duration;
  final VoidCallback onDismiss;

  const RestTimerWidget({
    super.key,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration.inSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _timer?.cancel();
        if (mounted) widget.onDismiss();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formatted {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remaining / widget.duration.inSeconds;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    color: colorScheme.primary,
                    backgroundColor:
                        colorScheme.primary.withValues(alpha: 0.2),
                  ),
                  Center(
                    child: Icon(Icons.timer,
                        size: 18, color: colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rest',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                  ),
                  Text(
                    _formatted,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: widget.onDismiss,
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }
}
