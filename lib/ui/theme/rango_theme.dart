import 'package:material_ui/material_ui.dart';

abstract final class RangoColors {
  static const primary = Color(0xFFFF6B00);
  static const primarySoft = Color(0xFFFF8A34);
  static const success = Color(0xFF22A447);
  static const error = Color(0xFFE53935);
}

// Cores do protótipo que não têm papel no ColorScheme (fundo da Home, avatar, skeleton).
class RangoPalette {
  const RangoPalette._({
    required this.background,
    required this.soft,
    required this.skeleton,
    required this.shadow,
  });

  static const _light = RangoPalette._(
    background: Color(0xFFF7F7F7),
    soft: Color(0xFFFFF1E6),
    skeleton: Color(0xFFECECEC),
    shadow: Color(0x171F1F1F),
  );

  static const _dark = RangoPalette._(
    background: Color(0xFF101012),
    soft: Color(0xFF2C1A0C),
    skeleton: Color(0xFF23252A),
    shadow: Color(0x8C000000),
  );

  static RangoPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  final Color background;
  final Color soft;
  final Color skeleton;
  final Color shadow;
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

  static final dark = _theme(
    const ColorScheme.dark(
      primary: RangoColors.primary,
      onPrimary: Colors.white,
      secondary: RangoColors.primarySoft,
      surface: Color(0xFF121212),
      onSurface: Color(0xFFF2F2F2),
      surfaceContainerHighest: Color(0xFF1E1E1E),
      onSurfaceVariant: Color(0xFFA3A3A3),
      outline: Color(0xFF2E2E2E),
      error: RangoColors.error,
    ),
  );

  static ThemeData _theme(ColorScheme colorScheme) => ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
  );
}
