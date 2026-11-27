// Tema escolhido pelo usuário, salvo no servidor.
enum ThemePreference {
  light('light', 'Claro'),
  dark('dark', 'Escuro'),
  system('system', 'Sistema');

  const ThemePreference(this.apiKey, this.label);

  final String apiKey;
  // Valor mostrado no Perfil e nas Configurações.
  final String label;

  static ThemePreference fromApi(String key) =>
      values.where((t) => t.apiKey == key).firstOrNull ?? light;
}

// Avisos que o usuário quer receber (tela Notificações das Configurações).
enum NotificationTopic { orders, promos, news }

class NotificationPrefs {
  const NotificationPrefs({
    required this.orders,
    required this.promos,
    required this.news,
  });

  // Valores iniciais do protótipo.
  static const initial = NotificationPrefs(
    orders: true,
    promos: true,
    news: false,
  );

  final bool orders;
  final bool promos;
  final bool news;

  bool operator [](NotificationTopic topic) => switch (topic) {
    NotificationTopic.orders => orders,
    NotificationTopic.promos => promos,
    NotificationTopic.news => news,
  };

  NotificationPrefs copyWith(NotificationTopic topic, bool on) =>
      NotificationPrefs(
        orders: topic == NotificationTopic.orders ? on : orders,
        promos: topic == NotificationTopic.promos ? on : promos,
        news: topic == NotificationTopic.news ? on : news,
      );

  Map<String, bool> toJson() => {
    'orders': orders,
    'promos': promos,
    'news': news,
  };
}

class Profile {
  const Profile({required this.name, required this.email, required this.phone});

  final String name;
  final String email;
  final String phone;

  String get initials => avatarInitials(name);
}

// Avatar sem foto: as duas primeiras letras do primeiro nome, como na Home.
String avatarInitials(String name) {
  final first = name.trim().split(' ').first;
  return String.fromCharCodes(first.runes.take(2)).toUpperCase();
}

// Dicas das linhas do Perfil, no singular e no plural.
String addressCountLabel(int count) =>
    '$count ${count == 1 ? 'salvo' : 'salvos'}';

String paymentCountLabel(int count) =>
    count == 1 ? '1 método disponível' : '$count métodos disponíveis';

String unreadLabel(int count) => switch (count) {
  0 => 'tudo lido',
  1 => '1 não lida',
  _ => '$count não lidas',
};
