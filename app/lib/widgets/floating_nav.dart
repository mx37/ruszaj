import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';

class FloatingNav extends StatelessWidget {
  const FloatingNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (HugeIcons.strokeRoundedRoute01, l10n.route),
      (HugeIcons.strokeRoundedBus01, l10n.stops),
      (HugeIcons.strokeRoundedSettings01, l10n.settings),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: AppRadii.pill,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A101828),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++)
            GestureDetector(
              onTap: () => onSelected(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selectedIndex == i ? Colors.white : Colors.transparent,
                  borderRadius: AppRadii.pill,
                ),
                child: Row(
                  children: [
                    AppIcon(
                      items[i].$1,
                      size: 19,
                      color: selectedIndex == i
                          ? AppColors.ink
                          : Colors.white70,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      items[i].$2,
                      style: TextStyle(
                        color: selectedIndex == i
                            ? AppColors.ink
                            : Colors.white70,
                        fontSize: 13,
                        fontWeight: selectedIndex == i
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
