import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../data/product.dart';
import '../theme/rango_theme.dart';

const _star = Color(0xFFF5A623);
const _mono = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: ['Courier'],
);

// Cor oklch() do CSS do protótipo convertida para sRGB.
Color oklch(double lightness, double chroma, double hue, double opacity) {
  final h = hue * math.pi / 180;
  final a = chroma * math.cos(h);
  final b = chroma * math.sin(h);
  double cube(double v) => v * v * v;
  final l = cube(lightness + 0.3963377774 * a + 0.2158037573 * b);
  final m = cube(lightness - 0.1055613458 * a - 0.0638541728 * b);
  final s = cube(lightness - 0.0894841775 * a - 1.2914855480 * b);
  double encode(double v) {
    final c = v.clamp(0.0, 1.0);
    return c <= 0.0031308 ? 12.92 * c : 1.055 * math.pow(c, 1 / 2.4) - 0.055;
  }

  return Color.from(
    alpha: opacity,
    red: encode(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
    green: encode(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
    blue: encode(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s),
  );
}

// Imagem provisória do protótipo: cor do produto com listras diagonais.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.hue,
    this.borderRadius = BorderRadius.zero,
    this.child,
  });

  final double hue;
  final BorderRadius borderRadius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        painter: StripesPainter(
          color: oklch(0.83, 0.10, hue, 0.55),
          stripe: const Color(0x0D000000),
          width: 9,
        ),
        child: child ?? const SizedBox.expand(),
      ),
    );
  }
}

// Fundo com listras a 135°, como o repeating-linear-gradient do protótipo.
class StripesPainter extends CustomPainter {
  const StripesPainter({
    required this.color,
    required this.stripe,
    required this.width,
  });

  final Color color;
  final Color stripe;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    final paint = Paint()
      ..color = stripe
      ..strokeWidth = width;
    final span = size.width + size.height;
    for (var x = -size.height; x < span; x += width * 2) {
      final start = x + width / 2;
      canvas.drawLine(
        Offset(start, 0),
        Offset(start + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StripesPainter old) =>
      old.color != color || old.stripe != stripe || old.width != width;
}

class FavoriteIcon extends StatelessWidget {
  const FavoriteIcon({super.key, required this.favorite});

  final bool favorite;

  @override
  Widget build(BuildContext context) {
    return Icon(
      favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      size: 19,
      color: favorite
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.size,
    required this.radius,
    required this.color,
    required this.onTap,
    required this.tooltip,
    required this.child,
    this.border,
    this.shadow,
  });

  final double size;
  final double radius;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  final Widget child;
  final Color? border;
  final BoxShadow? shadow;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: border == null ? BorderSide.none : BorderSide(color: border!),
    );

    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: ShapeDecoration(
          shape: shape,
          color: color,
          shadows: [?shadow],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: shape,
            onTap: onTap,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.product, required this.size, this.clock = true});

  final Product product;
  final double size;
  final bool clock;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = TextStyle(
      color: colors.onSurfaceVariant,
      fontSize: size,
      fontWeight: FontWeight.w600,
    );

    return DefaultTextStyle(
      style: style,
      child: Row(
        spacing: size < 11 ? 8 : 9,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 3,
            children: [
              Icon(Icons.star_rounded, size: size + 2.5, color: _star),
              Text(
                formatRating(product.rating),
                style: style.copyWith(color: colors.onSurface),
              ),
            ],
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 3,
              children: [
                if (clock)
                  Icon(
                    Icons.schedule_rounded,
                    size: size + 2.5,
                    color: colors.onSurfaceVariant,
                  ),
                Flexible(
                  child: Text(
                    '${product.minMinutes}-${product.maxMinutes} min',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.size,
    required this.radius,
    required this.onTap,
    this.glow = false,
  });

  final double size;
  final double radius;
  final VoidCallback onTap;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return _SquareButton(
      size: size,
      radius: radius,
      color: RangoColors.primary,
      tooltip: 'Adicionar ao carrinho',
      onTap: onTap,
      shadow: glow
          ? const BoxShadow(
              color: Color(0xE6FF6B00),
              offset: Offset(0, 6),
              blurRadius: 14,
              spreadRadius: -6,
            )
          : null,
      child: Icon(Icons.add_rounded, size: size - 14, color: Colors.white),
    );
  }
}

// Card das listas horizontais da Home.
class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    required this.favorite,
    required this.onOpen,
    required this.onToggleFavorite,
    required this.onAdd,
  });

  final Product product;
  final bool favorite;
  final VoidCallback onOpen;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final oldPrice = product.oldPrice;

    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline),
        boxShadow: [
          BoxShadow(
            color: RangoPalette.of(context).shadow,
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onOpen,
            child: SizedBox(
              height: 118,
              child: ProductImage(
                hue: product.hue,
                child: Stack(
                  children: [
                    if (oldPrice != null)
                      Positioned(
                        top: 9,
                        left: 9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'OFERTA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _SquareButton(
                        size: 30,
                        radius: 11,
                        color: const Color(0xE6FFFFFF),
                        tooltip: favorite
                            ? 'Remover dos favoritos'
                            : 'Adicionar aos favoritos',
                        onTap: onToggleFavorite,
                        shadow: const BoxShadow(
                          color: Color(0x29000000),
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                        child: FavoriteIcon(favorite: favorite),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xBFFFFFFF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'IMG',
                          style: _mono.copyWith(
                            fontSize: 9,
                            color: const Color(0x80000000),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 5,
              children: [
                GestureDetector(
                  onTap: onOpen,
                  child: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  product.restaurant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                _Meta(product: product, size: 10.5),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (oldPrice != null)
                            Text(
                              formatMoney(oldPrice),
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: colors.onSurfaceVariant,
                              ),
                            ),
                          Text(
                            formatMoney(product.price),
                            style: const TextStyle(
                              color: RangoColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _AddButton(size: 34, radius: 12, onTap: onAdd, glow: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Linha da lista de uma categoria e dos resultados da busca.
class ProductRow extends StatelessWidget {
  const ProductRow({
    super.key,
    required this.product,
    required this.favorite,
    required this.onOpen,
    required this.onToggleFavorite,
    required this.onAdd,
    this.subtitle,
  });

  final Product product;
  final bool favorite;
  final VoidCallback onOpen;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAdd;
  // Texto embaixo do nome; sem ele, a descrição do produto.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
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
          GestureDetector(
            onTap: onOpen,
            child: SizedBox.square(
              dimension: 84,
              child: ProductImage(
                hue: product.hue,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                GestureDetector(
                  onTap: onOpen,
                  child: Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  subtitle ?? product.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                _Meta(product: product, size: 11, clock: false),
                const SizedBox(height: 2),
                Row(
                  spacing: 7,
                  children: [
                    Expanded(
                      child: Text(
                        formatMoney(product.price),
                        style: const TextStyle(
                          color: RangoColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _SquareButton(
                      size: 32,
                      radius: 11,
                      color: colors.surface,
                      border: colors.outline,
                      tooltip: favorite
                          ? 'Remover dos favoritos'
                          : 'Adicionar aos favoritos',
                      onTap: onToggleFavorite,
                      child: FavoriteIcon(favorite: favorite),
                    ),
                    _AddButton(size: 32, radius: 11, onTap: onAdd),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
