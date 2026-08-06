import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/ruszaj_api.dart';
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
            _SectionTitle(text: l10n.appearance),
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
            const SizedBox(height: 28),
            _SectionTitle(text: l10n.connection),
            const SizedBox(height: 10),
            _ApiDomainOption(l10n: l10n),
            const SizedBox(height: 28),
            _SectionTitle(text: l10n.dataSources),
            const SizedBox(height: 10),
            _TransitousOption(l10n: l10n),
            const SizedBox(height: 28),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final info = snapshot.data;
                final value = info == null
                    ? '...'
                    : '${info.version}+${info.buildNumber}';
                return Text(
                  '${l10n.version} $value',
                  style: TextStyle(
                    color: AppColors.textMuted(context),
                    fontSize: 13,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TransitousOption extends StatelessWidget {
  const _TransitousOption({required this.l10n});
  final AppLocalizations l10n;

  Future<void> _openSources() async {
    await launchUrl(
      Uri.parse('https://transitous.org/sources/'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openSources,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppRadii.field,
          border: Border.all(color: AppColors.lineOf(context)),
        ),
        child: Row(
          children: [
            const AppIcon(
              HugeIcons.strokeRoundedBus01,
              size: 20,
              color: AppColors.blue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transitous',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.transitousSources,
                    style: TextStyle(
                      color: AppColors.textMuted(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const AppIcon(
              HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              color: AppColors.subtle,
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiDomainOption extends StatefulWidget {
  const _ApiDomainOption({required this.l10n});
  final AppLocalizations l10n;

  @override
  State<_ApiDomainOption> createState() => _ApiDomainOptionState();
}

class _ApiDomainOptionState extends State<_ApiDomainOption> {
  String get _value => RuszajApi.configuredBaseUrl;

  Future<void> _edit() async {
    final controller = TextEditingController(text: _value);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
        title: Text(widget.l10n.apiDomain),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: widget.l10n.apiDomainHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.field),
            ),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(widget.l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    RuszajApi.setBaseUrlOverride(result);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('api_base_url', RuszajApi.configuredBaseUrl);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final value = _value.isEmpty ? widget.l10n.defaultApiDomain : _value;
    return GestureDetector(
      onTap: _edit,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppRadii.field,
          border: Border.all(color: AppColors.lineOf(context)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.l10n.apiDomain,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const AppIcon(
              HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              color: AppColors.subtle,
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
