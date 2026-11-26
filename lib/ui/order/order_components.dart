import 'package:material_ui/material_ui.dart';

import '../../data/order.dart';
import '../components/auth_components.dart';
import '../components/product_card.dart';
import '../theme/rango_theme.dart';

// Peças repetidas no acompanhamento, em "Meus pedidos" e no detalhe.

const _mono = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: ['Courier'],
);

// Ícone de cada etapa do pedido, como no protótipo.
const stepIcons = [
  Icons.receipt_long_rounded,
  Icons.task_alt_rounded,
  Icons.soup_kitchen_rounded,
  Icons.delivery_dining_rounded,
  Icons.home_rounded,
];

// Cabeçalho com voltar, título, número do pedido e um item à direita.
class OrderHeader extends StatelessWidget {
  const OrderHeader({
    super.key,
    required this.title,
    required this.code,
    required this.onBack,
    this.titleSize = 16,
    this.trailing,
  });

  final String title;
  // Vazio enquanto o pedido carrega.
  final String code;
  final VoidCallback onBack;
  final double titleSize;
  final Widget? trailing;

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
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 13),
          child: Row(
            spacing: 12,
            children: [
              AuthBackButton(onPressed: onBack),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      code,
                      style: _mono.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// Etiqueta de status: laranja em andamento, verde entregue, vermelha cancelado.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status, required this.label});

  final OrderStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (color, background) = switch (status) {
      OrderStatus.live => (RangoColors.primary, RangoPalette.of(context).soft),
      OrderStatus.done => (RangoColors.success, const Color(0x1F22A447)),
      OrderStatus.cancel => (RangoColors.error, const Color(0x1FE53935)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// Texto em monoespaçada (número do pedido).
TextStyle monoStyle(Color color, double size) =>
    _mono.copyWith(color: color, fontSize: size, fontWeight: FontWeight.w700);

// Anel laranja que se expande e some (animação "ring" do protótipo).
class PulseRing extends StatefulWidget {
  const PulseRing({
    super.key,
    required this.child,
    required this.size,
    this.spread = 16,
  });

  final Widget child;
  final double size;
  final double spread;

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sem animação nos testes e com "remover animações" ligado.
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: RangoColors.primary.withValues(alpha: 0.4 * (1 - t)),
                spreadRadius: widget.spread * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// Mapa provisório do protótipo: verde claro com listras.
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({
    super.key,
    required this.height,
    required this.label,
    required this.child,
  });

  final double height;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: StripesPainter(
            color: oklch(0.86, 0.03, 160, 0.7),
            stripe: const Color(0x0D000000),
            width: 10,
          ),
          child: Stack(
            children: [
              Center(child: child),
              Positioned(
                left: 12,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCCFFFFFF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: _mono.copyWith(
                      fontSize: 9.5,
                      color: const Color(0x80000000),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
