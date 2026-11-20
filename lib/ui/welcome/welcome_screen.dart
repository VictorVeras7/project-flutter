import 'package:material_ui/material_ui.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onLogin,
    required this.onSignup,
  });

  final VoidCallback onLogin;
  final VoidCallback onSignup;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        // A margem inferior de 30 do protótipo já inclui a área segura.
        minimum: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            Expanded(
              // Rola em telas pequenas, mantendo os botões sempre visíveis.
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comida boa,\nentrega rápida.',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 31,
                        height: 1.14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Os melhores restaurantes da sua região em poucos '
                      'toques. Pediu, chegou.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 14.5,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: 11,
                children: [
                  Text(
                    'Ao continuar você aceita os Termos de uso e a Política '
                    'de privacidade.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
