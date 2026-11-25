// Carrinho como o servidor devolve: linhas com preços e totais já calculados.

class CartLine {
  const CartLine({
    required this.id,
    required this.productId,
    required this.name,
    required this.hue,
    required this.quantity,
    required this.addons,
    required this.notes,
    required this.unitPrice,
    required this.total,
    required this.available,
  });

  // Id da linha no servidor (usado para alterar e remover).
  final int id;
  final String productId;
  final String name;
  final double hue;
  final int quantity;
  // Nomes dos adicionais escolhidos.
  final List<String> addons;
  final String notes;
  final double unitPrice;
  final double total;
  // Produto indisponível fica no carrinho, mas fora do subtotal.
  final bool available;
}

class Cart {
  const Cart({
    required this.lines,
    required this.itemCount,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.couponCode,
    required this.couponApplied,
    required this.couponPercentOff,
  });

  static const empty = Cart(
    lines: [],
    itemCount: 0,
    subtotal: 0,
    deliveryFee: 0,
    discount: 0,
    total: 0,
    couponCode: null,
    couponApplied: false,
    couponPercentOff: 0,
  );

  final List<CartLine> lines;
  // Soma das quantidades (badge da sacola).
  final int itemCount;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String? couponCode;
  // false quando o cupom salvo deixou de valer (subtotal abaixo do mínimo).
  final bool couponApplied;
  final int couponPercentOff;

  bool get isEmpty => lines.isEmpty;
}
