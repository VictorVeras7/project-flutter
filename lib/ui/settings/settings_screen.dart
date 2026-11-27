import 'package:material_ui/material_ui.dart';

import '../checkout/checkout_components.dart';
import '../theme/rango_theme.dart';

// Fundo cinza com cabeçalho de voltar, comum às três telas.
class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({
    super.key,
    required this.title,
    required this.onBack,
    required this.children,
    this.spacing = 18,
  });

  final String title;
  final VoidCallback onBack;
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RangoPalette.of(context).background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckoutHeader(title: title, onBack: onBack),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                18,
                16,
                18,
                22 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) SizedBox(height: spacing),
                  child,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
