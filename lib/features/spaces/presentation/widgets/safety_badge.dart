import 'package:flutter/material.dart';

import '../../domain/entities/safety_label.dart';
import 'safety_visuals.dart';

/// A small pill showing the safety label (and optionally the numeric score).
class SafetyBadge extends StatelessWidget {
  const SafetyBadge({
    super.key,
    required this.label,
    this.score,
    this.compact = false,
  });

  final SafetyLabel label;
  final int? score;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = safetyColor(label);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(safetyIcon(label), color: color, size: compact ? 13 : 16),
          const SizedBox(width: 4),
          Text(
            score != null ? '${safetyText(label)} · $score' : safetyText(label),
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
