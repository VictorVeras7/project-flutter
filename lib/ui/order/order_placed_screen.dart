import 'package:material_ui/material_ui.dart';

import '../../data/order.dart';
import '../../data/product.dart';
import '../theme/rango_theme.dart';

// "Pedido realizado com sucesso!", com o resumo devolvido pelo servidor.
class OrderPlacedScreen extends StatefulWidget {
  const OrderPlacedScreen({
    super.key,
    required this.order,
    required this.onTrack,
    required this.onHome,
  });

  final PlacedOrder order;
  final VoidCallback onTrack;
  final VoidCallback onHome;

  @override
  State<OrderPlacedScreen> createState() => _OrderPlacedScreenState();
}

class _OrderPlacedScreenState extends State<OrderPlacedScreen>
    with SingleTickerProviderStateMixin {
  // Entrada do ícone com o "pop" do protótipo (0,5 s).
  late final _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final order = widget.order;
    final count = order.itemCount;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 22),
                      ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _pop,
                          curve: const Cubic(0.2, 0.9, 0.3, 1),
                        ),
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x1F22A447),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            size: 56,
                            color: RangoColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Pedido realizado\ncom sucesso!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 24,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        'Você receberá notificações sobre cada etapa do '
                        'preparo e da entrega.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 13.5,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.outline),
                        ),
                        child: Column(
                          spacing: 12,
                          children: [
                            _InfoRow(
                              label: 'Número do pedido',
                              value: order.code,
                              valueStyle: TextStyle(
                                color: colors.onSurface,
                                fontFamily: 'monospace',
                                fontFamilyFallback: const ['Courier'],
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            _InfoRow(
                              label: 'Previsão de entrega',
                              value: order.eta,
                              valueStyle: const TextStyle(
                                color: RangoColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            _InfoRow(
                              label: 'Pagamento',
                              value: order.paymentLabel,
                              valueStyle: TextStyle(
                                color: colors.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: colors.outline,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '$count ${count == 1 ? 'item' : 'itens'}',
                                    style: TextStyle(
                                      color: colors.onSurface,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  formatMoney(order.total),
                                  style: const TextStyle(
                                    color: RangoColors.primary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: widget.onTrack,
                icon: const Icon(Icons.delivery_dining_outlined, size: 21),
                label: const Text('Acompanhar pedido'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: widget.onHome,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: colors.onSurface,
                  side: BorderSide(color: colors.outline, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(value, style: valueStyle),
      ],
    );
  }
}
