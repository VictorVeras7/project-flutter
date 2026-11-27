import 'package:material_ui/material_ui.dart';

import '../theme/rango_theme.dart';

// Peças do Perfil e das Configurações do protótipo.

const _dangerSoft = Color(0x1FE53935);

// Ícone laranja em quadro suave (vermelho em "Sair" e "Limpar dados").
class RowIcon extends StatelessWidget {
  const RowIcon({super.key, required this.icon, this.danger = false});

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: danger ? _dangerSoft : RangoPalette.of(context).soft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 19,
        color: danger ? colors.error : colors.primary,
      ),
    );
  }
}

// Linha com ícone, título, dica e o que vier à direita (valor, seta,
// chave ou rádio).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.hint = '',
    this.value = '',
    this.trailing,
    this.chevron = true,
    this.danger = false,
    this.hintSize = 11,
    this.semanticsLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String hint;
  // Valor em laranja antes da seta ("Claro", "Português").
  final String value;
  // Chave ou rádio no lugar da seta.
  final Widget? trailing;
  final bool chevron;
  final bool danger;
  final double hintSize;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Semantics(
        label: semanticsLabel,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            spacing: 12,
            children: [
              RowIcon(icon: icon, danger: danger),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 1,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: danger ? colors.error : colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (hint.isNotEmpty)
                      Text(
                        hint,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: hintSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (value.isNotEmpty)
                Text(
                  value,
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ?trailing,
              if (trailing == null && chevron)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Linha do Perfil: cada uma num cartão próprio.
class ProfileRowCard extends StatelessWidget {
  const ProfileRowCard({super.key, required this.row, this.danger = false});

  final SettingsRow row;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(
          color: danger ? const Color(0x59E53935) : colors.outline,
        ),
      ),
      child: row,
    );
  }
}

// Grupo das Configurações: título em caixa alta e um cartão com as linhas
// separadas por uma borda.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.title, required this.rows});

  final String? title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = this.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 11,
                letterSpacing: 0.9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        Material(
          color: colors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, row) in rows.indexed)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : Border(top: BorderSide(color: colors.outline)),
                  ),
                  child: row,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// Chave liga/desliga do protótipo: trilho de 40 × 23 e bolinha de 18.
class RangoSwitch extends StatelessWidget {
  const RangoSwitch({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      toggled: value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        height: 23,
        padding: const EdgeInsets.all(2.5),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? colors.primary : colors.outline,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
