import 'package:material_ui/material_ui.dart';

import '../../data/product.dart';
import '../../data/search.dart';
import '../checkout/checkout_components.dart';
import '../components/empty_state.dart';
import '../components/product_card.dart';
import '../theme/rango_theme.dart';

// Favoritos: lista do servidor, mais recentes primeiro.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
    required this.favorites,
    required this.onLoad,
    required this.onOpenProduct,
    required this.onRemove,
    required this.onAddToCart,
    required this.onExplore,
  });

  // null = carregando.
  final List<Product>? favorites;
  // Recarrega sempre que a aba abre.
  final VoidCallback onLoad;
  final ValueChanged<String> onOpenProduct;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onAddToCart;
  // "Explorar produtos", no estado vazio.
  final VoidCallback onExplore;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    widget.onLoad();
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.favorites;

    return Scaffold(
      backgroundColor: RangoPalette.of(context).background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(count: list?.length),
          Expanded(
            child: list == null
                ? const CheckoutLoading()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                    children: [
                      if (list.isEmpty)
                        EmptyState(
                          icon: Icons.favorite_border_rounded,
                          title: 'Nenhum favorito ainda',
                          text:
                              'Toque no coração dos pratos que você ama para '
                              'encontrá-los rápido aqui.',
                          action: EmptyStateButton(
                            label: 'Explorar produtos',
                            onPressed: widget.onExplore,
                          ),
                        )
                      else
                        for (final product in list) ...[
                          _FavoriteCard(
                            product: product,
                            onOpen: () => widget.onOpenProduct(product.id),
                            onRemove: () => widget.onRemove(product.id),
                            onAdd: () => widget.onAddToCart(product.id),
                          ),
                          const SizedBox(height: 12),
                        ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final count = this.count;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outline)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
          // Título e contador alinhados pela linha do texto.
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'Favoritos',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              if (count != null)
                Text(
                  savedCountLabel(count),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.product,
    required this.onOpen,
    required this.onRemove,
    required this.onAdd,
  });

  final Product product;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  final VoidCallback onAdd;

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onOpen,
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Semantics(
                      container: true,
                      button: true,
                      label: 'Remover dos favoritos',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 21,
                          color: colors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${product.restaurant} · ${product.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                // Preço à esquerda e botão encostado à direita; em tela
                // estreita os dois encolhem em vez de estourar.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 8,
                  children: [
                    Flexible(
                      flex: 2,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatMoney(product.price),
                          style: const TextStyle(
                            color: RangoColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 3,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _AddButton(onTap: onAdd),
                      ),
                    ),
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

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add_shopping_cart_rounded, size: 17),
      label: const Text('Adicionar'),
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        iconSize: 17,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
