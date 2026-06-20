import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/usecases/discover_spaces.dart';

/// The Safe / Not-safe / All segmented control plus the refresh action that
/// sits on top of the home grid.
class SafetyFilterBar extends StatelessWidget {
  const SafetyFilterBar({
    super.key,
    required this.active,
    required this.onChanged,
    required this.onRefresh,
    required this.refreshing,
  });

  final SafetyFilter active;
  final ValueChanged<SafetyFilter> onChanged;
  final VoidCallback onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              _segment(SafetyFilter.all, 'Todos', AppColors.primary),
              const SizedBox(width: 8),
              _segment(SafetyFilter.safe, 'Safe spaces', AppColors.safe),
              const SizedBox(width: 8),
              _segment(SafetyFilter.notSafe, 'Não seguros', AppColors.notSafe),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _refreshButton(),
      ],
    );
  }

  Widget _segment(SafetyFilter value, String label, Color color) {
    final selected = active == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.2) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? color : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _refreshButton() {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: refreshing ? null : onRefresh,
        child: Container(
          width: 42,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: refreshing
              ? const Padding(
                  padding: EdgeInsets.all(11),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded,
                  color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}
