import 'package:material_ui/material_ui.dart';

import 'ui/components/auth_components.dart';
import 'ui/login/login_screen.dart';
import 'ui/signup/signup_screen.dart';
import 'ui/theme/rango_theme.dart';
import 'ui/welcome/welcome_screen.dart';

enum Screen { welcome, login, signup }

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

class _AppHome extends StatefulWidget {
  const _AppHome();

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> {
  // Pilha do protótipo: voltar retorna para a tela anterior.
  final _stack = [Screen.welcome];

  void _open(Screen screen) => setState(() => _stack.add(screen));

  void _back() => setState(_stack.removeLast);

  // A Home é a próxima feature; até lá o fluxo volta para a Welcome.
  void _finishAuth(String message, RangoToastKind kind) {
    setState(() {
      _stack
        ..clear()
        ..add(Screen.welcome);
    });
    showRangoToast(context, message, kind: kind);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stack.length == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: switch (_stack.last) {
        Screen.welcome => WelcomeScreen(
          onLogin: () => _open(Screen.login),
          onSignup: () => _open(Screen.signup),
        ),
        Screen.login => LoginScreen(
          onBack: _back,
          onLoginSuccess: (_) => _finishAuth(
            'Home estará disponível em breve.',
            RangoToastKind.info,
          ),
          onForgotPassword: () => showRangoToast(
            context,
            'Recuperar senha estará disponível em breve.',
            kind: RangoToastKind.info,
          ),
          onSignup: () => _open(Screen.signup),
        ),
        Screen.signup => SignupScreen(
          onBack: _back,
          onSignupSuccess: () =>
              _finishAuth('Conta criada com sucesso!', RangoToastKind.success),
          onLogin: () => _open(Screen.login),
        ),
      },
    );
  }
}
