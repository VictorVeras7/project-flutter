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
                    const _Logo(),
                    const SizedBox(height: 22),
                    const _Hero(),
                    const SizedBox(height: 26),
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

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      spacing: 10,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Text(
            'r',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          'rango',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/hero_delivery.png',
      width: double.infinity,
      height: 318,
      fit: BoxFit.contain,
      semanticLabel: 'Entregador de moto',
    );
  }
}
