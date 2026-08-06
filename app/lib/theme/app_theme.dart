import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF101828);
  static const muted = Color(0xFF667085);
  static const subtle = Color(0xFF98A2B3);
  static const line = Color(0xFFE4E7EC);
  static const canvas = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const blue = Color(0xFF2563EB);
  static const blueSoft = Color(0xFFEFF6FF);
  static const blueLine = Color(0xFFBFDBFE);
  static const green = Color(0xFF10B981);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? const Color(0xFF9CA3AF) : muted;

  static Color lineOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF2C3644) : line;

  static Color softOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF182339) : blueSoft;

  static Color lineSoftOf(BuildContext context) =>
      isDark(context) ? const Color(0xFF3E4C63) : blueLine;

  static Color selectedTextOf(BuildContext context) =>
      isDark(context) ? Colors.white : ink;
}

abstract final class AppRadii {
  static const field = BorderRadius.all(Radius.circular(18));
  static const card = BorderRadius.all(Radius.circular(24));
  static const pill = BorderRadius.all(Radius.circular(999));
}

ThemeData appTheme({Brightness brightness = Brightness.light}) {
  final base = brightness == Brightness.dark
      ? ThemeData.dark(useMaterial3: false)
      : ThemeData.light(useMaterial3: false);
  return base.copyWith(
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? const Color(0xFF0B1017)
        : AppColors.canvas,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.blue,
      onPrimary: Colors.white,
      surface: brightness == Brightness.dark
          ? const Color(0xFF151C25)
          : AppColors.surface,
      onSurface: brightness == Brightness.dark ? Colors.white : AppColors.ink,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: brightness == Brightness.dark ? Colors.white : AppColors.ink,
      displayColor: brightness == Brightness.dark
          ? Colors.white
          : AppColors.ink,
      fontFamily: 'Arial',
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
