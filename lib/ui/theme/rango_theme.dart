import 'package:material_ui/material_ui.dart';

abstract final class RangoColors {
  static const primary = Color(0xFFFF6B00);
  static const primarySoft = Color(0xFFFF8A34);
  static const success = Color(0xFF22A447);
  static const error = Color(0xFFE53935);
}

abstract final class RangoTheme {
  static final light = _theme(
    const ColorScheme.light(
      primary: RangoColors.primary,
      onPrimary: Colors.white,
      secondary: RangoColors.primarySoft,
      surface: Colors.white,
      onSurface: Color(0xFF1F1F1F),
      surfaceContainerHighest: Color(0xFFF7F7F7),
      onSurfaceVariant: Color(0xFF737373),
      outline: Color(0xFFE8E8E8),
      error: RangoColors.error,
    ),
  );

  static ThemeData _theme(ColorScheme colorScheme) => ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
  );
}
