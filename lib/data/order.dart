// Pedido recém-criado, para a tela "Pedido realizado com sucesso!".
class PlacedOrder {
  const PlacedOrder({
    required this.code,
    required this.minMinutes,
    required this.maxMinutes,
    required this.paymentLabel,
    required this.itemCount,
    required this.total,
  });

  // Número exibido: RG-10482.
  final String code;
  final int minMinutes;
  final int maxMinutes;
  final String paymentLabel;
  final int itemCount;
  final double total;

  String get eta => '$minMinutes-$maxMinutes min';
}
