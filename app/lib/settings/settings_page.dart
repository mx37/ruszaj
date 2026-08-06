import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.locale,
    required this.themeMode,
    required this.onLocaleChanged,
    required this.onThemeChanged,
  });
  final Locale? locale;
  final ThemeMode themeMode;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode =
        locale?.languageCode ?? Localizations.localeOf(context).languageCode;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const AppIcon(
                    HugeIcons.strokeRoundedArrowLeft01,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  l10n.settings,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 34),
            _SectionTitle(text: l10n.language),
            const SizedBox(height: 10),
            _SettingOption(
              label: l10n.english,
              selected: languageCode == 'en',
              onTap: () => onLocaleChanged(const Locale('en')),
            ),
            _SettingOption(
              label: l10n.polish,
              selected: languageCode == 'pl',
              onTap: () => onLocaleChanged(const Locale('pl')),
            ),
            const SizedBox(height: 28),
            _SectionTitle(text: l10n.settings),
            const SizedBox(height: 10),
            _SettingOption(
              label: l10n.lightTheme,
              selected: themeMode == ThemeMode.light,
              onTap: () => onThemeChanged(ThemeMode.light),
            ),
            _SettingOption(
              label: l10n.darkTheme,
              selected: themeMode == ThemeMode.dark,
              onTap: () => onThemeChanged(ThemeMode.dark),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: AppColors.textMuted(context),
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _SettingOption extends StatelessWidget {
  const _SettingOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.softOf(context)
              : Theme.of(context).colorScheme.surface,
          borderRadius: AppRadii.field,
          border: Border.all(
            color: selected
                ? AppColors.lineSoftOf(context)
                : AppColors.lineOf(context),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.selectedTextOf(context)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (selected)
              const AppIcon(
                HugeIcons.strokeRoundedTick01,
                size: 20,
                color: AppColors.blue,
              ),
          ],
        ),
      ),
    );
  }
}
