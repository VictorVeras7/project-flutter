import 'package:material_ui/material_ui.dart';

import '../theme/rango_theme.dart';

// Seletor − quantidade + do protótipo, em dois tamanhos:
// grande na barra do detalhe e pequeno nas linhas do carrinho.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
    this.compact = false,
  });

  final int quantity;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(compact ? 3 : 5),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(compact ? 12 : 15),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: compact ? 2 : 3,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            tooltip: 'Diminuir quantidade',
            compact: compact,
            onTap: onMinus,
          ),
          SizedBox(
            width: compact ? 22 : 26,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              semanticsLabel: 'Quantidade $quantity',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: compact ? 13.5 : 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            tooltip: 'Aumentar quantidade',
            compact: compact,
            onTap: onPlus,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final size = compact ? 28.0 : 36.0;
    final radius = BorderRadius.circular(compact ? 9 : 11);

    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: radius,
          boxShadow: compact
              ? null
              : [
                  BoxShadow(
                    color: RangoPalette.of(context).shadow,
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Icon(
              icon,
              size: compact ? 17 : 19,
              color: onTap == null
                  ? colors.onSurfaceVariant
                  : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
