import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_info_banner.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/section_header.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  static const routeName = '/legal/disclaimer';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Disclaimer',
      subtitle: 'Release and legal information',
      children: [
        AppInfoBanner(
          title: 'Not financial advice',
          message:
              'ClearTrade is an educational paper trading app. It does not provide brokerage execution or investment advice.',
          accentColor: Theme.of(context).colorScheme.error,
          icon: Icons.gavel_outlined,
        ),
        const SizedBox(height: 12),
        const SectionHeader('Important disclaimers'),
        const _DisclaimerCard(
          title: 'Paper trading only',
          message:
              'All orders are simulated locally. No real money is involved.',
        ),
        const SizedBox(height: 10),
        const _DisclaimerCard(
          title: 'No brokerage execution',
          message:
              'The app does not connect to a live brokerage account or execute real trades.',
        ),
        const SizedBox(height: 10),
        const _DisclaimerCard(
          title: 'Market data limitations',
          message:
              'Market data may be simulated demo data or remote market data configured later. Either way it is not a substitute for your own due diligence.',
        ),
        const SizedBox(height: 10),
        const _DisclaimerCard(
          title: 'Options risk',
          message: AppConfig.optionsRiskDisclaimer,
        ),
        const SizedBox(height: 10),
        const _DisclaimerCard(
          title: 'Journal and insights',
          message: AppConfig.insightsDisclaimer,
        ),
        const SizedBox(height: 10),
        const _DisclaimerCard(
          title: 'Local data responsibility',
          message:
              'Exports, restores, and backups are your responsibility. Keep a copy before replacing local data.',
        ),
        const SizedBox(height: 10),
        const _DisclaimerCard(
          title: 'Disclaimer version',
          message: '${AppConfig.legalDisclaimerVersion}',
        ),
      ],
    );
  }
}

class DataPrivacyScreen extends StatelessWidget {
  const DataPrivacyScreen({super.key});

  static const routeName = '/legal/data-privacy';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Data & privacy',
      subtitle: 'Local-first storage and backup behavior',
      children: [
        AppInfoBanner(
          title: 'Local-first by default',
          message:
              'Trading, journal, options, sync metadata, and demo auth all stay on this device unless you export or restore data manually.',
          accentColor: Theme.of(context).colorScheme.secondary,
          icon: Icons.storage_outlined,
        ),
        const SizedBox(height: 12),
        const SectionHeader('What is stored locally'),
        const _DisclaimerCard(
          title: 'Paper trading account',
          message:
              'Cash, positions, order history, and paper trading timestamps are stored locally.',
        ),
        const SizedBox(height: 10),
        const _DisclaimerCard(
          title: 'Journal and strategy notes',
          message:
              'Journal entries, moods, lessons learned, and strategy notes are stored locally.',
        ),
        const SizedBox(height: 10),
        const _DisclaimerCard(
          title: 'Options portfolio',
          message:
              'Option positions, lifecycle events, and income tracking are stored locally.',
        ),
        const SizedBox(height: 10),
        const _DisclaimerCard(
          title: 'Demo auth and sync metadata',
          message:
              'Demo session state and sync metadata are also stored locally for future backend compatibility.',
        ),
        const SizedBox(height: 10),
        const _DisclaimerCard(
          title: 'Backups and restores',
          message:
              'JSON backups are created and restored locally. Restores can replace the local state on this device.',
        ),
        const SizedBox(height: 12),
        const SectionHeader('Placeholders'),
        const _DisclaimerCard(
          title: 'Support contact',
          message: AppConfig.supportContactPlaceholder,
        ),
        const SizedBox(height: 10),
        const _DisclaimerCard(
          title: 'Privacy policy',
          message: AppConfig.privacyPolicyUrlPlaceholder,
        ),
      ],
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(color: Colors.white60)),
        ],
      ),
    );
  }
}
