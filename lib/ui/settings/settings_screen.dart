import 'package:material_ui/material_ui.dart';

import '../../data/profile.dart';
import '../checkout/checkout_components.dart';
import '../theme/rango_theme.dart';
import 'settings_components.dart';

// Fundo cinza com cabeçalho de voltar, comum às três telas.
class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({
    super.key,
    required this.title,
    required this.onBack,
    required this.children,
    this.spacing = 18,
  });

  final String title;
  final VoidCallback onBack;
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RangoPalette.of(context).background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckoutHeader(title: title, onBack: onBack),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                18,
                16,
                18,
                22 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) SizedBox(height: spacing),
                  child,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Configurações: preferências, conta, dados e sobre.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.theme,
    required this.onBack,
    required this.onTheme,
    required this.onNotifications,
    required this.onLanguage,
    required this.onPersonalData,
    required this.onAddresses,
    required this.onPayments,
    required this.onSync,
    required this.onClearData,
    required this.onHelp,
    required this.onTerms,
  });

  final ThemePreference theme;
  final VoidCallback onBack;
  final VoidCallback onTheme;
  final VoidCallback onNotifications;
  final VoidCallback onLanguage;
  final VoidCallback onPersonalData;
  final VoidCallback onAddresses;
  final VoidCallback onPayments;
  final VoidCallback onSync;
  final VoidCallback onClearData;
  final VoidCallback onHelp;
  final VoidCallback onTerms;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SettingsScaffold(
      title: 'Configurações',
      onBack: onBack,
      children: [
        SettingsGroup(
          title: 'Preferências',
          rows: [
            SettingsRow(
              icon: Icons.dark_mode_outlined,
              label: 'Tema',
              value: theme.label,
              onTap: onTheme,
            ),
            SettingsRow(
              icon: Icons.notifications_none_rounded,
              label: 'Notificações',
              onTap: onNotifications,
            ),
            SettingsRow(
              icon: Icons.language_rounded,
              label: 'Idioma',
              value: 'Português',
              onTap: onLanguage,
            ),
          ],
        ),
        SettingsGroup(
          title: 'Conta',
          rows: [
            SettingsRow(
              icon: Icons.person_outline_rounded,
              label: 'Dados pessoais',
              onTap: onPersonalData,
            ),
            SettingsRow(
              icon: Icons.location_on_outlined,
              label: 'Endereços',
              onTap: onAddresses,
            ),
            SettingsRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Formas de pagamento',
              onTap: onPayments,
            ),
          ],
        ),
        // O "Modo offline" do protótipo é só simulação e ficou de fora.
        SettingsGroup(
          title: 'Dados e conexão',
          rows: [
            SettingsRow(
              icon: Icons.sync_rounded,
              label: 'Sincronizar agora',
              hint: 'busca de novo pedidos, carrinho e favoritos',
              onTap: onSync,
            ),
            SettingsRow(
              icon: Icons.delete_sweep_outlined,
              label: 'Limpar dados locais',
              hint: 'sessão salva neste aparelho',
              danger: true,
              onTap: onClearData,
            ),
          ],
        ),
        SettingsGroup(
          title: 'Sobre',
          rows: [
            SettingsRow(
              icon: Icons.help_outline_rounded,
              label: 'Central de ajuda',
              onTap: onHelp,
            ),
            SettingsRow(
              icon: Icons.description_outlined,
              label: 'Termos e privacidade',
              onTap: onTerms,
            ),
          ],
        ),
        Text(
          'rango v1.0.0 · build 2026.08',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 10,
            fontFamily: 'monospace',
            fontFamilyFallback: const ['Courier'],
          ),
        ),
      ],
    );
  }
}

// Tema: miniaturas Claro e Escuro e as três opções.
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({
    super.key,
    required this.theme,
    required this.onBack,
    required this.onSelect,
  });

  final ThemePreference theme;
  final VoidCallback onBack;
  final ValueChanged<ThemePreference> onSelect;

  static const _options = [
    (
      ThemePreference.light,
      'Claro',
      'Fundo branco, laranja de destaque',
      Icons.light_mode_outlined,
    ),
    (
      ThemePreference.dark,
      'Escuro',
      'Fundo escuro, laranja preservado',
      Icons.dark_mode_outlined,
    ),
    (
      ThemePreference.system,
      'Usar configuração do sistema',
      'Segue o tema do smartphone',
      Icons.brightness_auto_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Em "Sistema", a miniatura marcada segue o aparelho.
    final systemDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final darkActive =
        theme == ThemePreference.dark ||
        (theme == ThemePreference.system && systemDark);

    return SettingsScaffold(
      title: 'Tema',
      onBack: onBack,
      spacing: 16,
      children: [
        Row(
          spacing: 11,
          children: [
            Expanded(child: _ThemePreview.light(selected: !darkActive)),
            Expanded(child: _ThemePreview.dark(selected: darkActive)),
          ],
        ),
        SettingsGroup(
          rows: [
            for (final (value, label, hint, icon) in _options)
              Semantics(
                selected: value == theme,
                inMutuallyExclusiveGroup: true,
                child: SettingsRow(
                  icon: icon,
                  label: label,
                  hint: hint,
                  hintSize: 11.5,
                  trailing: RadioMark(selected: value == theme),
                  onTap: () => onSelect(value),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// Miniatura de tela com as cores de cada tema, como no protótipo.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview.light({required this.selected})
    : name = 'Claro',
      background = const Color(0xFFFFFFFF),
      block = const Color(0xFFF7F7F7),
      line = const Color(0xFFE8E8E8),
      text = const Color(0xFF1F1F1F);

  const _ThemePreview.dark({required this.selected})
    : name = 'Escuro',
      background = const Color(0xFF17181B),
      block = const Color(0xFF1E2024),
      line = const Color(0xFF2A2C31),
      text = const Color(0xFFF4F4F5);

  final bool selected;
  final String name;
  final Color background;
  final Color block;
  final Color line;
  final Color text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget bar(double height, double widthFactor, Color color, double r) =>
        FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: widthFactor,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(r),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? colors.primary : colors.outline,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 7,
        children: [
          bar(8, 0.6, RangoColors.primary, 4),
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: block,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: line),
            ),
          ),
          bar(8, 0.75, line, 4),
          bar(22, 1, RangoColors.primary, 8),
          Text(
            name,
            style: TextStyle(
              color: text,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// Notificações: uma chave para cada tipo de aviso.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({
    super.key,
    required this.prefs,
    required this.onBack,
    required this.onToggle,
  });

  final NotificationPrefs prefs;
  final VoidCallback onBack;
  final void Function(NotificationTopic topic, bool on) onToggle;

  static const _options = [
    (
      NotificationTopic.orders,
      'Pedidos',
      'Confirmação, preparo e entrega',
      Icons.receipt_long_outlined,
    ),
    (
      NotificationTopic.promos,
      'Promoções',
      'Cupons e ofertas exclusivas',
      Icons.local_offer_outlined,
    ),
    (
      NotificationTopic.news,
      'Novidades',
      'Novos restaurantes e recursos',
      Icons.campaign_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Notificações',
      onBack: onBack,
      children: [
        // O teste de notificação e o aviso de permissão do protótipo
        // dependem de notificação do sistema e ficaram de fora.
        SettingsGroup(
          rows: [
            for (final (topic, label, hint, icon) in _options)
              SettingsRow(
                icon: icon,
                label: label,
                hint: hint,
                hintSize: 11.5,
                trailing: RangoSwitch(value: prefs[topic]),
                onTap: () => onToggle(topic, !prefs[topic]),
              ),
          ],
        ),
      ],
    );
  }
}
