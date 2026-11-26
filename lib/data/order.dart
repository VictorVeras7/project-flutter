// Pedidos: o recém-criado, a lista do histórico e o detalhe com a timeline.

enum OrderStatus {
  live('live'),
  done('done'),
  cancel('cancel');

  const OrderStatus(this.apiKey);

  final String apiKey;

  static OrderStatus fromApi(String key) =>
      values.firstWhere((s) => s.apiKey == key, orElse: () => live);
}

// Abas de "Meus pedidos".
enum OrderGroup {
  live('live'),
  past('past');

  const OrderGroup(this.apiKey);

  final String apiKey;
}

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

// Linha de "Meus pedidos".
class OrderSummary {
  const OrderSummary({
    required this.code,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
    required this.total,
    required this.itemCount,
    required this.itemsSummary,
    required this.hue,
  });

  final String code;
  final OrderStatus status;
  // "Em preparação", "Entregue", "Cancelado".
  final String statusLabel;
  final DateTime createdAt;
  final double total;
  final int itemCount;
  // "1× Burger duplo cheddar, 2× Limonada suíça".
  final String itemsSummary;
  // Cor do primeiro item, para a miniatura.
  final double hue;
}

enum TimelineState { done, current, upcoming }

class TimelineStep {
  const TimelineStep({
    required this.step,
    required this.label,
    required this.state,
    required this.reachedAt,
  });

  final int step;
  final String label;
  final TimelineState state;
  final DateTime? reachedAt;
}

class OrderItem {
  const OrderItem({
    required this.name,
    required this.restaurant,
    required this.hue,
    required this.quantity,
    required this.total,
  });

  final String name;
  final String restaurant;
  final double hue;
  final int quantity;
  final double total;
}

// Detalhe do pedido: usado no acompanhamento e em "Detalhes do pedido".
class OrderDetail {
  const OrderDetail({
    required this.summary,
    required this.step,
    required this.hint,
    required this.timeline,
    required this.minMinutes,
    required this.maxMinutes,
    required this.items,
    required this.addressLine,
    required this.paymentType,
    required this.paymentLabel,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.courierName,
    required this.courierVehicle,
  });

  final OrderSummary summary;
  // Etapa atual, de 0 (recebido) a 4 (entregue).
  final int step;
  // Texto de apoio da etapa: "Seu pedido está sendo preparado".
  final String hint;
  final List<TimelineStep> timeline;
  final int minMinutes;
  final int maxMinutes;
  final List<OrderItem> items;
  final String addressLine;
  // "pix", "credit", "debit" ou "cash", para o ícone.
  final String paymentType;
  final String paymentLabel;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final String courierName;
  final String courierVehicle;

  String get code => summary.code;
  bool get isLive => summary.status == OrderStatus.live;

  // Previsão do cartão de status, como no protótipo.
  String get eta => switch (summary.status) {
    OrderStatus.live => '$minMinutes-$maxMinutes min',
    OrderStatus.done => 'Entregue',
    OrderStatus.cancel => '',
  };
}

const _months = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

String _twoDigits(int value) => value.toString().padLeft(2, '0');

// "19:42", no fuso do aparelho.
String formatTime(DateTime value) {
  final local = value.toLocal();
  return '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}

// "Hoje · 19:42" ou "12 ago · 20:15", como no protótipo.
String formatOrderDate(DateTime value, {DateTime? now}) {
  final local = value.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  final sameDay =
      local.year == today.year &&
      local.month == today.month &&
      local.day == today.day;
  final day = sameDay
      ? 'Hoje'
      : '${_twoDigits(local.day)} ${_months[local.month - 1]}';
  return '$day · ${formatTime(local)}';
}
