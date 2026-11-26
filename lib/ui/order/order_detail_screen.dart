import 'package:material_ui/material_ui.dart';

import '../../data/checkout.dart';
import '../../data/order.dart';
import '../../data/product.dart';
import '../checkout/checkout_components.dart';
import '../components/product_card.dart';
import '../theme/rango_theme.dart';
import 'order_components.dart';

// Detalhes do pedido: produtos, entrega, pagamento e valores pagos.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.onBack,
    required this.onReorder,
  });

  // null enquanto carrega.
  final OrderDetail? order;
  final VoidCallback onBack;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final order = this.order;

    return Scaffold(
      backgroundColor: RangoPalette.of(context).background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderHeader(
            title: 'Detalhes do pedido',
            titleSize: 15.5,
            code: order?.code ?? '',
            onBack: onBack,
            trailing: order == null
                ? null
                : OrderStatusChip(
                    status: order.summary.status,
                    label: order.summary.statusLabel,
                  ),
          ),
          Expanded(
            child: order == null
                ? const CheckoutLoading()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                    children: [
                      _Products(items: order.items),
                      const SizedBox(height: 13),
                      _Info(order: order),
                      const SizedBox(height: 13),
                      _Values(order: order),
                    ],
                  ),
          ),
          CheckoutBottomBar(
            child: FilledButton.icon(
              onPressed: order == null ? null : onReorder,
              icon: const Icon(Icons.replay_rounded, size: 21),
              label: const Text('Pedir novamente'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: RangoColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: RangoColors.primary.withValues(
                  alpha: 0.6,
                ),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Products extends StatelessWidget {
  const _Products({required this.items});

  final List<OrderItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(
            'Produtos',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          for (final item in items)
            Row(
              spacing: 11,
              children: [
                SizedBox.square(
                  dimension: 38,
                  child: ProductImage(
                    hue: item.hue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 1,
                    children: [
                      Text(
                        '${item.quantity}× ${item.name}',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.restaurant.isNotEmpty)
                        Text(
                          item.restaurant,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  formatMoney(item.total),
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rows = [
      (Icons.location_on_outlined, 'Endereço de entrega', order.addressLine),
      (
        paymentIcon(PaymentType.fromApi(order.paymentType)),
        'Pagamento',
        order.paymentLabel,
      ),
      (
        Icons.schedule_rounded,
        'Realizado em',
        formatOrderDate(order.summary.createdAt),
      ),
      (Icons.flag_outlined, 'Status final', order.summary.statusLabel),
    ];

    return SectionCard(
      child: Column(
        spacing: 13,
        children: [
          for (final (icon, label, value) in rows)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 11,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 18, color: RangoColors.primary),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 1,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Values extends StatelessWidget {
  const _Values({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rows = [
      ('Subtotal', formatMoney(order.subtotal)),
      (
        'Taxa de entrega',
        order.deliveryFee == 0 ? 'Grátis' : formatMoney(order.deliveryFee),
      ),
      if (order.discount > 0.01)
        ('Desconto', '- ${formatMoney(order.discount)}'),
    ];

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          for (final (label, value) in rows)
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          Divider(height: 1, thickness: 1, color: colors.outline),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'Total pago',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                formatMoney(order.summary.total),
                style: const TextStyle(
                  color: RangoColors.primary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
