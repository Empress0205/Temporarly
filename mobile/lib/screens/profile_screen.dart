import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../widgets/jh_header.dart';
import '../widgets/jh_lang_toggle.dart';
import '../widgets/jh_scaffold.dart';
import '../widgets/jh_scope.dart';
import '../widgets/jh_tab_bar.dart';

/// Account screen: identity, the verified number, member-since, the settings
/// a customer can reach from here, and the way out.
///
/// A light page rather than the flat green band every other authenticated
/// screen opens with -- Account reads as a settings surface, not a place with
/// its own destination content, and the second-pass mockups draw it that way.
class JhProfileScreen extends StatelessWidget {
  const JhProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 18),
          child: Row(
            children: [
              JhRoundBackButton(onPressed: () => state.selectTab(JhTab.home)),
              const SizedBox(width: 14),
              Text(
                t.account,
                style: JhText.ui(
                  size: 18,
                  weight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const Spacer(),
              const JhLangToggle(onDark: false),
            ],
          ),
        ),
        Expanded(
          child: ScrollConfiguration(
            behavior: const JhScrollBehavior(),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                JhTabBar.heightOf(context) + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _IdentityCard(
                    initials: state.initials,
                    name: state.account.name,
                    roleFallback: t.customerRole,
                    statusLabel: t.activeAccount,
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    rows: [
                      _InfoRow(
                        icon: JhIcons.fullName,
                        label: t.fullName,
                        value: state.account.name.isEmpty
                            ? '—'
                            : state.account.name,
                      ),
                      _InfoRow(
                        icon: JhIcons.phone,
                        label: t.phoneLabel,
                        value: state.prettyAccountPhone,
                      ),
                      _InfoRow(
                        icon: JhIcons.calendar,
                        label: t.memberSince,
                        value: state.prettyMemberSince,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionLabel(t.accountSettingsSection),
                  _SettingsCard(
                    rows: [
                      _SettingsRow(
                        icon: JhIcons.changeNumber,
                        iconColor: JhColors.primaryText,
                        title: t.changePhone,
                        subtitle: t.changePhoneRowSub,
                        onTap: state.goChangePhone,
                      ),
                      _SettingsRow(
                        icon: JhIcons.email,
                        iconColor: JhColors.primaryText,
                        title: t.updateEmail,
                        subtitle: t.updateEmailSub,
                        onTap: () => state.showComingSoon(t.updateEmail),
                      ),
                      _SettingsRow(
                        icon: JhIcons.notifications,
                        iconColor: JhColors.primaryText,
                        title: t.notificationsRow,
                        subtitle: t.notificationsRowSub,
                        onTap: () => state.showComingSoon(t.notificationsRow),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionLabel(t.support),
                  _SettingsCard(
                    rows: [
                      _SettingsRow(
                        icon: JhIcons.help,
                        iconColor: JhColors.primaryText,
                        title: t.helpFaq,
                        subtitle: t.helpFaqSub,
                        onTap: () => state.showComingSoon(t.helpFaq),
                      ),
                      _SettingsRow(
                        icon: JhIcons.lock,
                        iconColor: JhColors.primaryText,
                        title: t.privacySecurity,
                        subtitle: t.privacySecuritySub,
                        onTap: () => state.showComingSoon(t.privacySecurity),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionLabel(t.sessionSection),
                  _SettingsCard(
                    rows: [
                      _SettingsRow(
                        icon: JhIcons.logout,
                        iconColor: JhColors.danger,
                        title: t.logout,
                        subtitle: t.logoutRowSub,
                        onTap: state.askLogout,
                      ),
                      _SettingsRow(
                        icon: JhIcons.delete,
                        iconColor: JhColors.danger,
                        title: t.deleteAccount,
                        subtitle: t.deleteAccountSub,
                        onTap: state.askDeleteAccount,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.initials,
    required this.name,
    required this.roleFallback,
    required this.statusLabel,
  });

  final String initials;
  final String name;
  final String roleFallback;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final hasName = initials.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JhColors.surface,
        borderRadius: BorderRadius.circular(JhRadii.card),
        boxShadow: JhShadows.card,
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: JhColors.primaryText,
                  shape: BoxShape.circle,
                ),
                child: hasName
                    ? Text(
                        initials,
                        style: JhText.ui(
                          size: 20,
                          weight: FontWeight.w800,
                          color: JhColors.onDark,
                        ),
                      )
                    : const Icon(
                        JhIcons.identityUnknown,
                        size: 24,
                        color: JhColors.onDark,
                      ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: JhColors.primary,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: JhColors.surface, width: 2),
                    ),
                  ),
                  child: const Icon(
                    JhIcons.verified,
                    size: 12,
                    color: JhColors.onDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? name : roleFallback,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JhText.ui(
                    size: 18,
                    weight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: JhColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: JhText.ui(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: JhColors.textMuted,
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

class _InfoRow {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return _Card(
      children: [
        for (final (i, row) in rows.indexed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: i == rows.length - 1
                ? null
                : const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: JhColors.cardBorder),
                    ),
                  ),
            child: Row(
              children: [
                _IconBox(icon: row.icon, color: JhColors.primaryText),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.label.toUpperCase(),
                        style: JhText.ui(
                          size: 10.5,
                          weight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: JhColors.textFaint,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(row.value, style: JhText.mono(size: 14.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Text(
        label.toUpperCase(),
        style: JhText.ui(
          size: 11.5,
          weight: FontWeight.w800,
          letterSpacing: 0.7,
          color: JhColors.textMuted,
        ),
      ),
    );
  }
}

class _SettingsRow {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.rows});

  final List<_SettingsRow> rows;

  @override
  Widget build(BuildContext context) {
    return _Card(
      children: [
        for (final (i, row) in rows.indexed)
          Semantics(
            button: true,
            label: '${row.title}. ${row.subtitle}',
            child: GestureDetector(
              onTap: row.onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: i == rows.length - 1
                    ? null
                    : const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: JhColors.cardBorder),
                        ),
                      ),
                child: Row(
                  children: [
                    _IconBox(icon: row.icon, color: row.iconColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.title,
                            style: JhText.ui(size: 14.5, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            row.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: JhText.ui(
                              size: 12,
                              weight: FontWeight.w500,
                              color: JhColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      JhIcons.chevron,
                      size: 20,
                      color: JhColors.textFaint,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A colour-washed square behind a row's icon.
class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: JhColors.wash(color),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

/// The white card every grouped list on this screen sits in -- identical
/// shell, different rows. A shadow lifts it off the page rather than an
/// outline, so a screen full of these reads as whitespace, not a stack of
/// outlined boxes.
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: JhColors.surface,
        borderRadius: BorderRadius.circular(JhRadii.card),
        boxShadow: JhShadows.card,
      ),
      child: Column(children: children),
    );
  }
}
