import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'theme/app_theme.dart';
import 'widgets/app_icon.dart';
import 'widgets/floating_nav.dart';
import 'package:hugeicons/hugeicons.dart';

void main() => runApp(const RuszajApp());

class RuszajApp extends StatelessWidget {
  const RuszajApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruszaj',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supported) {
        if (locale == null) return supported.first;
        return supported.firstWhere(
          (item) => item.languageCode == locale.languageCode,
          orElse: () => supported.first,
        );
      },
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  String _city = 'Warszawa';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _Header(city: _city, onCityTap: _chooseCity),
                      const SizedBox(height: 34),
                      Text(
                        l10n.appTagline,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _JourneyCard(),
                      const SizedBox(height: 32),
                      Text(
                        l10n.recentRoutes,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _RecentEmpty(text: l10n.noRecentRoutes),
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: Center(
                child: FloatingNav(
                  selectedIndex: _selectedTab,
                  onSelected: (index) => setState(() => _selectedTab = index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseCity() async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _CitySheet(title: l10n.selectCity),
    );
    if (selected != null && mounted) setState(() => _city = selected);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.city, required this.onCityTap});
  final String city;
  final VoidCallback onCityTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        const Text(
          'Ruszaj',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onCityTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(
                HugeIcons.strokeRoundedBuilding03,
                size: 18,
                color: AppColors.blue,
              ),
              const SizedBox(width: 7),
              Text(
                city,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 5),
              const AppIcon(
                HugeIcons.strokeRoundedArrowDown01,
                size: 17,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.chooseCity,
          style: const TextStyle(fontSize: 12, color: AppColors.subtle),
        ),
      ],
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
      ),
      child: Column(
        children: [
          _PlaceField(
            label: l10n.from,
            hint: l10n.whereAreYouStarting,
            color: AppColors.blue,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Row(
              children: [
                Expanded(child: Container(height: 1, color: AppColors.line)),
                const SizedBox(width: 10),
                const AppIcon(
                  HugeIcons.strokeRoundedArrowUpDown,
                  size: 19,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
          _PlaceField(
            label: l10n.to,
            hint: l10n.whereAreYouGoing,
            color: AppColors.green,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.pill,
                ),
              ),
              child: Text(
                l10n.findRoute,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceField extends StatelessWidget {
  const _PlaceField({
    required this.label,
    required this.hint,
    required this.color,
  });
  final String label;
  final String hint;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.subtle,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              hint,
              style: const TextStyle(fontSize: 17, color: AppColors.muted),
            ),
          ],
        ),
      ),
      const AppIcon(
        HugeIcons.strokeRoundedSearch01,
        size: 19,
        color: AppColors.subtle,
      ),
    ],
  );
}

class _RecentEmpty extends StatelessWidget {
  const _RecentEmpty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.line),
      borderRadius: AppRadii.card,
    ),
    child: Row(
      children: [
        const AppIcon(HugeIcons.strokeRoundedClock01, color: AppColors.subtle),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _CitySheet extends StatelessWidget {
  const _CitySheet({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
    decoration: const BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.line,
            borderRadius: AppRadii.pill,
          ),
        ),
        const SizedBox(height: 22),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 14),
        for (final city in [
          'Warszawa',
          'Kraków',
          'Gdańsk',
          'Wrocław',
          'Poznań',
        ])
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(city),
            trailing: const AppIcon(
              HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              color: AppColors.subtle,
            ),
            onTap: () => Navigator.pop(context, city),
          ),
      ],
    ),
  );
}
