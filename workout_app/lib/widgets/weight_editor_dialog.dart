import 'package:flutter/material.dart';
import '../models/weight.dart';

class WeightEditorDialog extends StatefulWidget {
  final Weight initial;
  final ValueChanged<Weight> onChanged;

  const WeightEditorDialog({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<WeightEditorDialog> createState() => _WeightEditorDialogState();
}

class _WeightEditorDialogState extends State<WeightEditorDialog> {
  late TextEditingController _controller;
  late WeightUnit _unit;

  @override
  void initState() {
    super.initState();
    _unit = widget.initial.unit;
    final v = widget.initial.value;
    _controller = TextEditingController(
      text: v == v.roundToDouble() ? v.toInt().toString() : v.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_controller.text);
    if (value == null) return;
    widget.onChanged(Weight(value: value, unit: _unit));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Weight'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Weight',
              suffixText: _unit == WeightUnit.kilograms ? 'kg' : 'lbs',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          SegmentedButton<WeightUnit>(
            segments: const [
              ButtonSegment(value: WeightUnit.kilograms, label: Text('kg')),
              ButtonSegment(value: WeightUnit.pounds, label: Text('lbs')),
            ],
            selected: {_unit},
            onSelectionChanged: (s) {
              final newUnit = s.first;
              final current = double.tryParse(_controller.text);
              if (current != null) {
                final converted = Weight(value: current, unit: _unit)
                    .convertTo(newUnit);
                final cv = converted.value;
                _controller.text = cv == cv.roundToDouble()
                    ? cv.toInt().toString()
                    : cv.toStringAsFixed(2);
              }
              setState(() => _unit = newUnit);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Convenience helper
Future<void> showWeightEditor(
  BuildContext context, {
  required Weight initial,
  required ValueChanged<Weight> onChanged,
}) {
  return showDialog(
    context: context,
    builder: (_) =>
        WeightEditorDialog(initial: initial, onChanged: onChanged),
  );
}
