import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/config/app_config.dart';
import '../../core/config/build_config.dart';
import '../../core/data/auth_state.dart';
import '../../core/data/market_state.dart';
import '../../core/data/paper_trading_state.dart';
import '../../core/onboarding/onboarding_state.dart';
import '../../core/sync/sync_state.dart';
import '../../core/sync/sync_status.dart';
import '../legal/disclaimer_screen.dart';
import '../export_reports/export_reports_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final paperState = PaperTradingScope.of(context);
    final marketState = MarketScope.of(context);
    final authState = AuthScope.of(context);

    return AppPage(
      title: 'Settings',
      subtitle: 'Paper account and app controls',
      children: [
        const SectionHeader('Account'),
        _AccountCard(authState: authState),
        const SectionHeader('Paper account'),
        _PaperAccountCard(paperState: paperState, marketState: marketState),
        const SectionHeader('Account controls'),
        _SettingsActionCard(
          icon: Icons.restart_alt,
          iconColor: AppTheme.danger,
          title: 'Reset paper portfolio',
          subtitle:
              'Restore default mock cash, positions, and clear order history.',
          actionLabel: 'Reset',
          destructive: true,
          onPressed: () => _confirmReset(context, paperState),
        ),
        const SizedBox(height: 10),
        _SettingsActionCard(
          icon: Icons.history_toggle_off,
          iconColor: AppTheme.warning,
          title: 'Clear order history',
          subtitle:
              'Remove activity records without changing cash or positions.',
          actionLabel: 'Clear',
          destructive: true,
          onPressed: () => _confirmClearHistory(context, paperState),
        ),
        const SectionHeader('App information'),
        _AppInfoCard(marketState: marketState),
        const SectionHeader('Legal'),
        _SettingsActionCard(
          icon: Icons.info_outline,
          iconColor: AppTheme.secondary,
          title: 'Disclaimer',
          subtitle:
              'Read the paper trading, options, and data limitation disclaimers.',
          actionLabel: 'Open',
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const DisclaimerScreen())),
        ),
        const SizedBox(height: 10),
        _SettingsActionCard(
          icon: Icons.privacy_tip_outlined,
          iconColor: AppTheme.secondary,
          title: 'Data & privacy',
          subtitle: 'Review what is stored locally and how backups work.',
          actionLabel: 'Open',
          onPressed: () =>
              Navigator.of(context).pushNamed(DataPrivacyScreen.routeName),
        ),
        const SizedBox(height: 10),
        _SettingsActionCard(
          icon: Icons.school_outlined,
          iconColor: AppTheme.primary,
          title: 'View onboarding again',
          subtitle: 'Review the paper trading guidance and acknowledgements.',
          actionLabel: 'Open',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const OnboardingScreen(requireAcceptance: false),
            ),
          ),
        ),
        const SectionHeader('Sync'),
        _SyncCard(syncState: SyncScope.of(context)),
        const SectionHeader('Diagnostics'),
        _DiagnosticsCard(
          marketState: marketState,
          authState: authState,
          syncState: SyncScope.of(context),
          onboardingState: OnboardingScope.maybeOf(context),
        ),
        const SectionHeader('Export & reports'),
        _SettingsActionCard(
          icon: Icons.file_download_outlined,
          iconColor: AppTheme.primary,
          title: 'Export data / reports',
          subtitle:
              'Generate JSON backups, CSV exports, and performance reports.',
          actionLabel: 'Open',
          onPressed: () =>
              Navigator.of(context).pushNamed(ExportReportsScreen.routeName),
        ),
        const SizedBox(height: 10),
        _SettingsActionCard(
          icon: Icons.file_upload_outlined,
          iconColor: AppTheme.warning,
          title: 'Import / restore backup',
          subtitle:
              'Paste a JSON backup and restore local data on this device.',
          actionLabel: 'Open',
          onPressed: () =>
              Navigator.of(context).pushNamed(ExportReportsScreen.routeName),
        ),
      ],
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    PaperTradingState paperState,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset paper portfolio?'),
        content: const Text(
          'This restores the default mock account, including cash and starting positions, and clears order history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset portfolio'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }
    await paperState.reset();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Paper portfolio reset.')));
  }

  Future<void> _confirmClearHistory(
    BuildContext context,
    PaperTradingState paperState,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear order history?'),
        content: const Text(
          'This removes activity records only. Cash balance and open positions will stay unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear history'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }
    await paperState.clearOrderHistory();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Order history cleared.')));
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({required this.syncState});

  final SyncState syncState;

  @override
  Widget build(BuildContext context) {
    final metadata = syncState.metadata;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SettingsRow(label: 'Mode', value: metadata.syncMode.label),
            const Divider(height: 22),
            _SettingsRow(label: 'Status', value: syncState.status.label),
            const Divider(height: 22),
            _SettingsRow(
              label: 'Pending operations',
              value: syncState.pendingOperations.length.toString(),
            ),
            const Divider(height: 22),
            _SettingsRow(
              label: 'Last synced',
              value: _formatDateTime(metadata.lastSyncedAt),
            ),
            const Divider(height: 22),
            _SettingsRow(
              label: 'Last attempt',
              value: _formatDateTime(metadata.lastAttemptedAt),
            ),
            if (syncState.errorMessage != null) ...[
              const Divider(height: 22),
              Text(
                syncState.errorMessage!,
                style: const TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: syncState.isSyncing
                  ? null
                  : () => _syncNow(context, syncState),
              icon: syncState.isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: const Text('Sync now'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: syncState.pendingOperations.isEmpty
                  ? null
                  : () => _confirmClearSynced(context, syncState),
              icon: const Icon(Icons.cleaning_services_outlined),
              label: const Text('Clear synced operations'),
            ),
            const SizedBox(height: 10),
            const Text(
              AppConfig.syncDisclaimer,
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncNow(BuildContext context, SyncState syncState) async {
    await syncState.syncNow();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sync status: ${syncState.status.label}.')),
    );
  }

  Future<void> _confirmClearSynced(
    BuildContext context,
    SyncState syncState,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear synced operations?'),
        content: const Text(
          'This removes operations that have already been synced. Pending local changes will stay queued.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear synced'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await syncState.clearSynced();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Synced operations cleared.')));
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({
    required this.marketState,
    required this.authState,
    required this.syncState,
    required this.onboardingState,
  });

  final MarketState marketState;
  final AuthState authState;
  final SyncState syncState;
  final OnboardingState? onboardingState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const _SettingsRow(
              label: 'Policy',
              value: AppConfig.syncDiagnosticsLabel,
            ),
            const Divider(height: 22),
            _SettingsRow(label: 'Build mode', value: AppConfig.buildModeLabel),
            const Divider(height: 22),
            _SettingsRow(
              label: 'Build label',
              value: AppConfig.buildConfig.buildLabel,
            ),
            const Divider(height: 22),
            _SettingsRow(
              label: 'Flavor',
              value: AppConfig.buildConfig.flavor.label,
            ),
            const Divider(height: 22),
            _SettingsRow(
              label: 'Test/demo mode',
              value: AppConfig.buildConfig.flavor == AppFlavor.demo
                  ? 'Demo build'
                  : 'Flavor-enabled build',
            ),
            const Divider(height: 22),
            _SettingsRow(
              label: 'Market mode',
              value: marketState.dataMode.label,
            ),
            const Divider(height: 22),
            _SettingsRow(
              label: 'Market provider',
              value: AppConfig.marketProviderConfig.providerLabel,
            ),
            const Divider(height: 22),
            _SettingsRow(
              label: 'Remote config',
              value: AppConfig.marketProviderConfig.hasRemoteConfig
                  ? 'Present'
                  : 'Missing',
            ),
            const Divider(height: 22),
            _SettingsRow(
              label: 'Auth mode',
              value: authState.isAuthenticated
                  ? 'Demo signed in'
                  : 'Signed out',
            ),
            const Divider(height: 22),
            _SettingsRow(
              label: 'Sync mode',
              value: syncState.metadata.syncMode.label,
            ),
            const Divider(height: 22),
            _SettingsRow(
              label: 'Onboarding',
              value: onboardingState?.isAccepted == true
                  ? 'Accepted'
                  : 'Not accepted',
            ),
            const Divider(height: 22),
            const _SettingsRow(label: 'Storage', value: 'Local-first'),
            const Divider(height: 22),
            const _SettingsRow(
              label: 'Support contact',
              value: AppConfig.supportUrlPlaceholder,
            ),
            const Divider(height: 22),
            const _SettingsRow(
              label: 'Privacy policy',
              value: AppConfig.privacyPolicyUrlPlaceholder,
            ),
            const Divider(height: 22),
            const _SettingsRow(
              label: 'Disclaimer version',
              value: '${AppConfig.legalDisclaimerVersion}',
            ),
            const Divider(height: 22),
            const _SettingsRow(
              label: 'Onboarding version',
              value: '${AppConfig.onboardingVersion}',
            ),
            const Divider(height: 22),
            const _SettingsRow(
              label: 'RC readiness',
              value: 'Validated for local-first demo mode',
            ),
            const Divider(height: 22),
            const Text(
              AppConfig.releaseCandidateNote,
              style: TextStyle(color: Colors.white60),
            ),
            const Divider(height: 22),
            const _SettingsRow(
              label: 'Backup reminder',
              value: 'Keep a JSON backup before restoring local data.',
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    final user = authState.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user == null) ...[
              const Text(
                'Signed out',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Paper trading remains available in demo mode.',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: authState.isLoading
                    ? null
                    : () => _signInDemo(context, authState),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Sign in demo account'),
              ),
            ] else ...[
              _SettingsRow(label: 'Name', value: user.displayName),
              const Divider(height: 22),
              _SettingsRow(label: 'Email', value: user.email),
              const Divider(height: 22),
              _SettingsRow(label: 'User ID', value: user.id),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: authState.isLoading
                    ? null
                    : () => _confirmSignOut(context, authState),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              AppConfig.demoAuthDisclaimer,
              style: TextStyle(color: Colors.white60),
            ),
            if (authState.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                authState.errorMessage!,
                style: const TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _signInDemo(BuildContext context, AuthState authState) async {
    await authState.signInDemo();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Signed in to demo account.')));
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    AuthState authState,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out of demo account?'),
        content: const Text(
          'This will end the local demo session only. Paper trading data will stay on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await authState.signOut();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out of demo account.')),
    );
  }
}

class _PaperAccountCard extends StatelessWidget {
  const _PaperAccountCard({
    required this.paperState,
    required this.marketState,
  });

  final PaperTradingState paperState;
  final MarketState marketState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SettingsRow(
              label: 'Starting cash',
              value:
                  '\$${PaperTradingState.defaultCashBalance.toStringAsFixed(2)}',
            ),
            const Divider(height: 22),
            _SettingsRow(
              label: 'Current cash',
              value: '\$${paperState.cashBalance.toStringAsFixed(2)}',
            ),
            const Divider(height: 22),
            _SettingsRow(
              label: 'Portfolio value',
              value:
                  '\$${paperState.totalPortfolioValueFor(marketState).toStringAsFixed(2)}',
            ),
            const Divider(height: 22),
            _SettingsRow(
              label: 'Open positions',
              value: paperState.positions.length.toString(),
            ),
            const Divider(height: 22),
            _SettingsRow(
              label: 'Market data',
              value: marketState.dataMode.label,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsActionCard extends StatelessWidget {
  const _SettingsActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 460;
            final actionButton = FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                    )
                  : null,
              onPressed: onPressed,
              child: Text(actionLabel),
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: iconColor.withValues(alpha: 0.12),
                        child: Icon(icon, color: iconColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerLeft, child: actionButton),
                ],
              );
            }
            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withValues(alpha: 0.12),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                actionButton,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AppInfoCard extends StatelessWidget {
  const _AppInfoCard({required this.marketState});

  final MarketState marketState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SettingsRow(label: 'App name', value: AppConfig.appName),
            const Divider(height: 22),
            const _SettingsRow(
              label: 'Version',
              value: AppConfig.appVersionLabel,
            ),
            const Divider(height: 22),
            const _SettingsRow(
              label: 'Build mode',
              value: AppConfig.buildModeLabel,
            ),
            const Divider(height: 22),
            _SettingsRow(
              label: 'Market mode',
              value: marketState.dataMode.label,
            ),
            const Divider(height: 22),
            const Text(
              AppConfig.paperTradingDisclaimer,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              AppConfig.simulatedPricesDisclaimer,
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white60)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return 'Never';
  }
  final local = value.toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
