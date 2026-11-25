import 'package:material_ui/material_ui.dart';

import '../../data/order.dart';
import '../checkout/checkout_components.dart';
import '../components/product_card.dart';
import '../theme/rango_theme.dart';
import 'order_components.dart';

// Acompanhar pedido: o App atualiza o pedido a cada 5 s enquanto a tela
// está aberta; aqui só se desenha o estado atual.
class TrackingScreen extends StatelessWidget {
  const TrackingScreen({
    super.key,
    required this.order,
    required this.onBack,
    required this.onChat,
    required this.onCall,
  });

  // null enquanto carrega.
  final OrderDetail? order;
  final VoidCallback onBack;
  final VoidCallback onChat;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final order = this.order;

    return Scaffold(
      backgroundColor: RangoPalette.of(context).background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderHeader(
            title: 'Acompanhar pedido',
            code: order?.code ?? '',
            onBack: onBack,
          ),
          Expanded(
            child: order == null
                ? const CheckoutLoading()
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      16,
                      18,
                      22 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      MapPlaceholder(
                        height: 150,
                        label: 'mapa · rota em tempo real',
                        child: PulseRing(
                          size: 52,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: RangoColors.primary,
                            ),
                            child: const Icon(
                              Icons.delivery_dining_rounded,
                              size: 27,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _StatusCard(order: order),
                      const SizedBox(height: 14),
                      _Timeline(steps: order.timeline),
                      const SizedBox(height: 14),
                      _CourierCard(
                        order: order,
                        onChat: onChat,
                        onCall: onCall,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cancelled = order.summary.status == OrderStatus.cancel;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        spacing: 13,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: RangoPalette.of(context).soft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              cancelled ? Icons.cancel_rounded : stepIcons[order.step],
              size: 24,
              color: cancelled ? RangoColors.error : RangoColors.primary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  order.summary.statusLabel,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  order.hint,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            order.eta,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: RangoColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    // Padding do protótipo: 18 em cima e embaixo; a última etapa já traz 16.
    return SectionCard(
      padding: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 2),
        child: Column(
          children: [
            for (final (index, step) in steps.indexed)
              _TimelineRow(step: step, last: index == steps.length - 1),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.last});

  final TimelineStep step;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final done = step.state == TimelineState.done;
    final current = step.state == TimelineState.current;
    final reachedAt = step.reachedAt;

    final dot = Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? RangoColors.success
            : current
            ? RangoColors.primary
            : colors.surfaceContainerHighest,
        border: done || current
            ? null
            : Border.all(color: colors.outline, width: 1.5),
      ),
      child: Icon(
        done ? Icons.check_rounded : stepIcons[step.step],
        size: 15,
        color: done || current ? Colors.white : colors.onSurfaceVariant,
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 13,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                if (current)
                  PulseRing(size: 26, spread: 10, child: dot)
                else
                  dot,
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      constraints: const BoxConstraints(minHeight: 26),
                      color: done ? RangoColors.success : colors.outline,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      color: current
                          ? RangoColors.primary
                          : done
                          ? colors.onSurface
                          : colors.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: current ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                  Text(
                    done && reachedAt != null
                        ? formatTime(reachedAt)
                        : current
                        ? 'agora'
                        : 'previsto',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourierCard extends StatelessWidget {
  const _CourierCard({
    required this.order,
    required this.onChat,
    required this.onCall,
  });

  final OrderDetail order;
  final VoidCallback onChat;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SectionCard(
      child: Row(
        spacing: 13,
        children: [
          ClipOval(
            child: SizedBox.square(
              dimension: 44,
              child: CustomPaint(
                painter: StripesPainter(
                  color: oklch(0.82, 0.09, 250, 0.55),
                  stripe: const Color(0x0D000000),
                  width: 6,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 1,
              children: [
                Text(
                  order.courierName,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Entregador · ${order.courierVehicle}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _CourierButton(
            icon: Icons.chat_bubble_rounded,
            tooltip: 'Conversar com o entregador',
            filled: false,
            onTap: onChat,
          ),
          _CourierButton(
            icon: Icons.call_rounded,
            tooltip: 'Ligar para o entregador',
            filled: true,
            onTap: onCall,
          ),
        ],
      ),
    );
  }
}

class _CourierButton extends StatelessWidget {
  const _CourierButton({
    required this.icon,
    required this.tooltip,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      iconSize: 20,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(40),
        minimumSize: const Size.square(40),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: filled ? Colors.white : colors.primary,
        backgroundColor: filled ? colors.primary : colors.surface,
        side: filled ? null : BorderSide(color: colors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }
}
