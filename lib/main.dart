import 'package:material_ui/material_ui.dart';

import 'ui/theme/rango_theme.dart';
import 'ui/welcome/welcome_screen.dart';

void main() {
  runApp(const RangoApp());
}

class RangoApp extends StatelessWidget {
  const RangoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rango',
      debugShowCheckedModeBanner: false,
      theme: RangoTheme.light,
      darkTheme: RangoTheme.dark,
      home: const _AppHome(),
    );
  }
}

class _AppHome extends StatelessWidget {
  const _AppHome();

  // Login e cadastro são as próximas features.
  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature estará disponível em breve.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return WelcomeScreen(
      onLogin: () => _comingSoon(context, 'Login'),
      onSignup: () => _comingSoon(context, 'Cadastro'),
    );
  }
}
