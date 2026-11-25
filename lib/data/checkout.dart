// Endereços e formas de pagamento do checkout, como o servidor devolve.

class Address {
  const Address({
    required this.id,
    required this.label,
    required this.street,
    required this.line,
    required this.cityLine,
    required this.selected,
  });

  final int id;
  // "Casa", "Trabalho".
  final String label;
  // Rua e número, usado no cabeçalho da Home.
  final String street;
  // "Rua das Palmeiras, 128 · apto 42".
  final String line;
  // "Pinheiros · São Paulo".
  final String cityLine;
  // Endereço de entrega atual no servidor.
  final bool selected;
}

// Campos da tela "Novo endereço".
class AddressForm {
  const AddressForm({
    required this.cep,
    required this.street,
    required this.complement,
    required this.neighborhood,
    required this.city,
  });

  final String cep;
  final String street;
  final String complement;
  final String neighborhood;
  final String city;
}

enum PaymentType {
  pix('pix'),
  credit('credit'),
  debit('debit'),
  cash('cash');

  const PaymentType(this.apiKey);

  final String apiKey;

  static PaymentType fromApi(String key) =>
      values.firstWhere((t) => t.apiKey == key, orElse: () => pix);

  // Crédito e débito mostram os dados do cartão, como no protótipo.
  bool get isCard => this == credit || this == debit;
}

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    required this.detail,
  });

  final int id;
  final PaymentType type;
  // "Cartão de crédito".
  final String label;
  // "Visa •••• 4410", "Aprovação imediata".
  final String detail;
}
