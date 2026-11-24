import 'package:material_ui/material_ui.dart';

import '../../data/product.dart';
import '../components/product_card.dart';
import '../theme/rango_theme.dart';

// Seções da Home na ordem e com os ícones do protótipo.
const _sections = [
  (
    tag: ProductTag.offer,
    title: 'Ofertas para você',
    icon: Icons.local_offer_rounded,
  ),
  (
    tag: ProductTag.popular,
    title: 'Mais pedidos',
    icon: Icons.local_fire_department_rounded,
  ),
  (
    tag: ProductTag.recommended,
    title: 'Recomendados',
    icon: Icons.thumb_up_rounded,
  ),
  (tag: ProductTag.fast, title: 'Entrega rápida', icon: Icons.bolt_rounded),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.userName,
    required this.address,
    required this.cartCount,
    required this.hasUnread,
    required this.loading,
    required this.categories,
    required this.sections,
    required this.categoryProducts,
    required this.favoriteIds,
    required this.onCategoryChange,
    required this.onToggleFavorite,
    required this.onAddToCart,
    required this.onOpenProduct,
    required this.onOpenCart,
    required this.onOpenNotifications,
    required this.onOpenSearch,
    required this.onOpenProfile,
    required this.onOpenAddress,
    required this.onSeeAll,
  });

  final String userName;
  final String? address;
  final int cartCount;
  final bool hasUnread;
  // Primeira carga: mostra o skeleton no lugar do catálogo.
  final bool loading;
  final List<String> categories;
  final Map<ProductTag, List<Product>> sections;
  final Map<String, List<Product>> categoryProducts;
  final Set<String> favoriteIds;
  final ValueChanged<String> onCategoryChange;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<String> onAddToCart;
  final ValueChanged<String> onOpenProduct;
  final VoidCallback onOpenCart;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenAddress;
  final ValueChanged<ProductTag> onSeeAll;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _category = allCategories;

  void _select(String category) {
    setState(() => _category = category);
    if (category != allCategories) widget.onCategoryChange(category);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _category != allCategories;

    return Scaffold(
      backgroundColor: RangoPalette.of(context).background,
      body: Column(
        children: [
          _Header(
            userName: widget.userName,
            // Sem endereço salvo, pede um; enquanto carrega, deixa vazio.
            address:
                widget.address ?? (widget.loading ? '' : 'Escolha um endereço'),
            cartCount: widget.cartCount,
            hasUnread: widget.hasUnread,
            categories: widget.categories,
            selected: _category,
            onSelect: _select,
            onOpenCart: widget.onOpenCart,
            onOpenNotifications: widget.onOpenNotifications,
            onOpenSearch: widget.onOpenSearch,
            onOpenProfile: widget.onOpenProfile,
            onOpenAddress: widget.onOpenAddress,
          ),
          Expanded(
            child: SingleChildScrollView(
              key: PageStorageKey('home-$_category'),
              padding: EdgeInsets.fromLTRB(
                0,
                16,
                0,
                22 + MediaQuery.paddingOf(context).bottom,
              ),
              child: widget.loading
                  ? const _Skeleton()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 22,
                      children: [
                        const _PromoBanner(),
                        if (filtered)
                          _CategoryList(
                            title: _category,
                            products: widget.categoryProducts[_category],
                            favoriteIds: widget.favoriteIds,
                            onToggleFavorite: widget.onToggleFavorite,
                            onAddToCart: widget.onAddToCart,
                            onOpenProduct: widget.onOpenProduct,
                          )
                        else
                          for (final section in _sections)
                            if (widget.sections[section.tag]
                                case final products? when products.isNotEmpty)
                              _Rail(
                                title: section.title,
                                icon: section.icon,
                                products: products,
                                favoriteIds: widget.favoriteIds,
                                onSeeAll: () => widget.onSeeAll(section.tag),
                                onToggleFavorite: widget.onToggleFavorite,
                                onAddToCart: widget.onAddToCart,
                                onOpenProduct: widget.onOpenProduct,
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

class _Header extends StatelessWidget {
  const _Header({
    required this.userName,
    required this.address,
    required this.cartCount,
    required this.hasUnread,
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.onOpenCart,
    required this.onOpenNotifications,
    required this.onOpenSearch,
    required this.onOpenProfile,
    required this.onOpenAddress,
  });

  final String userName;
  final String? address;
  final int cartCount;
  final bool hasUnread;
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onOpenCart;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenAddress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final firstName = userName.split(' ').first;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outline)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 13,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  spacing: 11,
                  children: [
                    _HeaderButton(
                      tooltip: 'Perfil',
                      radius: 15,
                      color: RangoPalette.of(context).soft,
                      border: colors.outline,
                      onTap: onOpenProfile,
                      child: Text(
                        firstName.characters.take(2).toString().toUpperCase(),
                        style: const TextStyle(
                          color: RangoColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 1,
                        children: [
                          Text(
                            'Olá, $firstName',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _AddressButton(
                            address: address ?? '',
                            onTap: onOpenAddress,
                          ),
                        ],
                      ),
                    ),
                    _HeaderButton(
                      tooltip: 'Notificações',
                      color: colors.surface,
                      border: colors.outline,
                      onTap: onOpenNotifications,
                      badge: hasUnread
                          ? Positioned(
                              top: 8,
                              right: 9,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colors.error,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.surface,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            )
                          : null,
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 21,
                        color: colors.onSurface,
                      ),
                    ),
                    _HeaderButton(
                      tooltip: cartCount > 0
                          ? 'Carrinho, $cartCount itens'
                          : 'Carrinho',
                      color: RangoColors.primary,
                      onTap: onOpenCart,
                      badge: cartCount > 0
                          ? Positioned(
                              top: -5,
                              right: -5,
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 19),
                                height: 19,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: colors.onSurface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: colors.surface,
                                    width: 2,
                                  ),
                                ),
                                // O total já está no rótulo do botão.
                                child: Text(
                                  '$cartCount',
                                  semanticsLabel: '',
                                  style: TextStyle(
                                    color: colors.surface,
                                    fontSize: 10.5,
                                    height: 1,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                          : null,
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 21,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SearchButton(onTap: onOpenSearch),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  spacing: 8,
                  children: [
                    for (final category in categories)
                      _CategoryChip(
                        label: category,
                        selected: category == selected,
                        onTap: () => onSelect(category),
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

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.tooltip,
    required this.color,
    required this.onTap,
    required this.child,
    this.radius = 14,
    this.border,
    this.badge,
  });

  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  final Widget child;
  final double radius;
  final Color? border;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: border == null ? BorderSide.none : BorderSide(color: border!),
    );

    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 42,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Material(
                color: color,
                shape: shape,
                child: InkWell(
                  customBorder: shape,
                  onTap: onTap,
                  child: Center(child: child),
                ),
              ),
            ),
            ?badge,
          ],
        ),
      ),
    );
  }
}

class _AddressButton extends StatelessWidget {
  const _AddressButton({required this.address, required this.onTap});

  final String address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          const Icon(
            Icons.location_on_rounded,
            size: 16,
            color: RangoColors.primary,
          ),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Icon(
            Icons.expand_more_rounded,
            size: 16,
            color: colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: BorderSide(color: colors.outline),
    );

    return Material(
      color: colors.surfaceContainerHighest,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              spacing: 10,
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                Expanded(
                  child: Text(
                    'O que você quer comer hoje?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.tune_rounded,
                  size: 19,
                  color: RangoColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: BorderSide(color: selected ? RangoColors.primary : colors.outline),
    );

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? RangoColors.primary : colors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : colors.onSurfaceVariant,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  static const _mono = TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: ['Courier'],
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment(-0.85, -0.5),
          end: Alignment(0.85, 0.5),
          colors: [RangoColors.primary, RangoColors.primarySoft],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xCCFF6B00),
            offset: Offset(0, 14),
            blurRadius: 28,
            spreadRadius: -14,
          ),
        ],
      ),
      child: Row(
        spacing: 14,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                const Text(
                  'SÓ HOJE',
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const Text(
                  '20% OFF acima\nde R\$ 40',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x38FFFFFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'RANGO10',
                    style: _mono.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox.square(
            dimension: 88,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CustomPaint(
                painter: const StripesPainter(
                  color: Color(0x38FFFFFF),
                  stripe: Color(0x0F000000),
                  width: 8,
                ),
                child: Center(
                  child: Text(
                    'promo\nimg',
                    textAlign: TextAlign.center,
                    style: _mono.copyWith(
                      fontSize: 9,
                      color: const Color(0xE6FFFFFF),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.icon, required this.trailing});

  final String title;
  final IconData? icon;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 19, color: RangoColors.primary),
            const SizedBox(width: 7),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.title,
    required this.icon,
    required this.products,
    required this.favoriteIds,
    required this.onSeeAll,
    required this.onToggleFavorite,
    required this.onAddToCart,
    required this.onOpenProduct,
  });

  final String title;
  final IconData icon;
  final List<Product> products;
  final Set<String> favoriteIds;
  final VoidCallback onSeeAll;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<String> onAddToCart;
  final ValueChanged<String> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 13,
      children: [
        _SectionTitle(
          title: title,
          icon: icon,
          trailing: GestureDetector(
            onTap: onSeeAll,
            child: const Text(
              'Ver tudo',
              style: TextStyle(
                color: RangoColors.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 13,
            children: [
              for (final product in products)
                ProductTile(
                  product: product,
                  favorite: favoriteIds.contains(product.id),
                  onOpen: () => onOpenProduct(product.id),
                  onToggleFavorite: () => onToggleFavorite(product.id),
                  onAdd: () => onAddToCart(product.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.title,
    required this.products,
    required this.favoriteIds,
    required this.onToggleFavorite,
    required this.onAddToCart,
    required this.onOpenProduct,
  });

  final String title;
  // null enquanto a categoria carrega.
  final List<Product>? products;
  final Set<String> favoriteIds;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<String> onAddToCart;
  final ValueChanged<String> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final products = this.products;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 13,
      children: [
        _SectionTitle(
          title: title,
          trailing: Text(
            products == null ? '' : '${products.length} itens',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: products == null
                ? [for (var i = 0; i < 3; i++) const _SkeletonRow()]
                : [
                    for (final product in products)
                      ProductRow(
                        product: product,
                        favorite: favoriteIds.contains(product.id),
                        onOpen: () => onOpenProduct(product.id),
                        onToggleFavorite: () => onToggleFavorite(product.id),
                        onAdd: () => onAddToCart(product.id),
                      ),
                  ],
          ),
        ),
      ],
    );
  }
}

// Skeleton

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            const _Shimmer(height: 118, radius: 20),
            const _Bone(width: 150, height: 16, radius: 6),
            // Três cartões, cortados na borda como no protótipo.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                spacing: 12,
                children: [
                  for (var i = 0; i < 3; i++)
                    SizedBox(
                      width: 176,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 9,
                        children: [
                          _Shimmer(height: 112, radius: 16),
                          FractionallySizedBox(
                            widthFactor: .8,
                            child: _Bone(height: 12, radius: 5),
                          ),
                          FractionallySizedBox(
                            widthFactor: .55,
                            child: _Bone(height: 10, radius: 5),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const _Bone(width: 120, height: 16, radius: 6),
            for (var i = 0; i < 3; i++) const _SkeletonRow(),
          ],
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      spacing: 12,
      children: [
        SizedBox(width: 84, child: _Shimmer(height: 84, radius: 16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              FractionallySizedBox(
                widthFactor: .7,
                child: _Bone(height: 13, radius: 5),
              ),
              FractionallySizedBox(
                widthFactor: .9,
                child: _Bone(height: 10, radius: 5),
              ),
              FractionallySizedBox(
                widthFactor: .4,
                child: _Bone(height: 10, radius: 5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({this.width, required this.height, required this.radius});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: RangoPalette.of(context).skeleton,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// Faixa clara que atravessa o bloco, como o shimmer do protótipo (1,15 s).
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.height, required this.radius});

  final double height;
  final double radius;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = RangoPalette.of(context).skeleton;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shift = _controller.value * 4 - 2;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(shift - 1, 0),
              end: Alignment(shift + 1, 0),
              colors: [base, const Color(0x52FFFFFF), base],
            ),
          ),
        );
      },
    );
  }
}
