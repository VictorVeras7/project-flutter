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
