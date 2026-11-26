import 'package:material_ui/material_ui.dart';

import '../../data/order.dart';
import '../../data/product.dart';
import '../checkout/checkout_components.dart';
import '../components/product_card.dart';
import '../theme/rango_theme.dart';
import 'order_components.dart';

// Meus pedidos: abas "Em andamento" e "Anteriores", vindas do servidor.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    super.key,
    required this.orders,
    required this.group,
    required this.onSelectGroup,
    required this.onLoad,
    required this.onOpen,
    required this.onTrack,
    required this.onReorder,
    required this.onOrderNow,
  });

  // Pedidos por aba; ausente = carregando.
  final Map<OrderGroup, List<OrderSummary>> orders;
  // Aba aberta; a troca fica com quem chama (busca a aba nova no servidor).
  final OrderGroup group;
  final ValueChanged<OrderGroup> onSelectGroup;
  // Busca a aba no servidor (ao abrir a tela e ao puxar para atualizar).
  final Future<void> Function(OrderGroup group) onLoad;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onTrack;
  final ValueChanged<String> onReorder;
  // "Fazer um pedido", no estado vazio.
  final VoidCallback onOrderNow;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // Ao abrir (e ao voltar do detalhe), atualiza a aba aberta.
  @override
  void initState() {
    super.initState();
    widget.onLoad(widget.group);
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final list = widget.orders[group];

    return Scaffold(
      backgroundColor: RangoPalette.of(context).background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(group: group, onSelect: widget.onSelectGroup),
          Expanded(
            child: list == null
                ? const CheckoutLoading()
                : RefreshIndicator(
                    color: RangoColors.primary,
                    onRefresh: () => widget.onLoad(group),
                    child: ListView(
                      // Puxar para atualizar funciona até com a lista vazia.
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                      children: [
                        if (list.isEmpty)
                          _Empty(group: group, onOrderNow: widget.onOrderNow)
                        else
                          for (final order in list) ...[
                            _OrderCard(
                              order: order,
                              onOpen: () => widget.onOpen(order.code),
                              onTrack: () => widget.onTrack(order.code),
                              onReorder: () => widget.onReorder(order.code),
                            ),
                            const SizedBox(height: 13),
                          ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.group, required this.onSelect});

  final OrderGroup group;
  final ValueChanged<OrderGroup> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outline)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(
                'Meus pedidos',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              // Com fonte grande, as abas rolam em vez de estourar.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 22,
                  children: [
                    for (final (tab, label) in [
                      (OrderGroup.live, 'Em andamento'),
                      (OrderGroup.past, 'Anteriores'),
                    ])
                      _Tab(
                        label: label,
                        selected: tab == group,
                        onTap: () => onSelect(tab),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: selected ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onOpen,
    required this.onTrack,
    required this.onReorder,
  });

  final OrderSummary order;
  final VoidCallback onOpen;
  final VoidCallback onTrack;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final count = order.itemCount;
    const buttonText = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    // Dois botões lado a lado em tela estreita: pouco recuo e texto que encolhe.
    const buttonPadding = EdgeInsets.symmetric(horizontal: 8);
    Widget label(String text) =>
        FittedBox(fit: BoxFit.scaleDown, child: Text(text));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline),
        boxShadow: [
          BoxShadow(
            color: RangoPalette.of(context).shadow,
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 11,
        children: [
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(order.code, style: monoStyle(colors.onSurface, 12.5)),
                    Text(
                      formatOrderDate(order.createdAt),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              OrderStatusChip(status: order.status, label: order.statusLabel),
            ],
          ),
          Semantics(
            button: true,
            label: 'Ver detalhes do pedido ${order.code}',
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                spacing: 11,
                children: [
                  SizedBox.square(
                    dimension: 44,
                    child: ProductImage(
                      hue: order.hue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          order.itemsSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$count ${count == 1 ? 'item' : 'itens'} · '
                          '${formatMoney(order.total)}',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          Row(
            spacing: 9,
            children: [
              if (order.status == OrderStatus.live)
                Expanded(
                  child: FilledButton(
                    onPressed: onTrack,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: buttonShape,
                      textStyle: buttonText,
                      padding: buttonPadding,
                    ),
                    child: label('Acompanhar'),
                  ),
                ),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReorder,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: colors.onSurface,
                    side: BorderSide(color: colors.outline, width: 1.5),
                    shape: buttonShape,
                    textStyle: buttonText,
                    padding: buttonPadding,
                  ),
                  child: label('Pedir novamente'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.group, required this.onOrderNow});

  final OrderGroup group;
  final VoidCallback onOrderNow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 50),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: colors.outline),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 42,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            group == OrderGroup.live
                ? 'Nenhum pedido em andamento'
                : 'Nenhum pedido anterior',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              'Quando você fizer um pedido, ele aparece aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 17),
          FilledButton(
            onPressed: onOrderNow,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Fazer um pedido'),
          ),
        ],
      ),
    );
  }
}
