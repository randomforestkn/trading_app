import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/onboarding/onboarding_state.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_info_banner.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/section_header.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.requireAcceptance = true});

  final bool requireAcceptance;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _paperTradingAcknowledged = false;
  bool _noAdviceAcknowledged = false;
  bool _localDataAcknowledged = false;

  @override
  Widget build(BuildContext context) {
    final onboardingState = OnboardingScope.maybeOf(context);

    final canContinue =
        !widget.requireAcceptance ||
        (_paperTradingAcknowledged &&
            _noAdviceAcknowledged &&
            _localDataAcknowledged);

    return AppPage(
      title: 'Welcome to ${AppConfig.appName}',
      subtitle: 'Before you begin, review how this demo works',
      children: [
        AppInfoBanner(
          title: AppConfig.paperTradingDisclaimer,
          message:
              '${AppConfig.simulatedPricesDisclaimer} ${AppConfig.insightsDisclaimer}',
        ),
        const SizedBox(height: 12),
        const SectionHeader('How this app works'),
        const _InfoCard(
          title: 'Paper trading only',
          message:
              'Orders are simulated locally. No real brokerage execution occurs.',
        ),
        const SizedBox(height: 10),
        const _InfoCard(
          title: 'Market data mode',
          message:
              'Prices are simulated demo data unless you later configure remote market mode.',
        ),
        const SizedBox(height: 10),
        const _InfoCard(
          title: 'Strategy tools',
          message:
              'Options calculators and strategy simulators are educational only.',
        ),
        const SizedBox(height: 10),
        const _InfoCard(
          title: 'Journal and insights',
          message:
              'Insights are rule-based summaries of your local notes and trading activity.',
        ),
        const SizedBox(height: 10),
        const _InfoCard(
          title: 'Local-first data',
          message:
              'Your data stays on this device unless you export or restore a backup yourself.',
        ),
        const SizedBox(height: 12),
        if (widget.requireAcceptance) ...[
          const SectionHeader('Required acknowledgement'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _paperTradingAcknowledged,
                  onChanged: (value) {
                    setState(() => _paperTradingAcknowledged = value ?? false);
                  },
                  title: const Text('I understand this is paper trading only.'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _noAdviceAcknowledged,
                  onChanged: (value) {
                    setState(() => _noAdviceAcknowledged = value ?? false);
                  },
                  title: const Text(
                    'I understand this is not investment advice.',
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _localDataAcknowledged,
                  onChanged: (value) {
                    setState(() => _localDataAcknowledged = value ?? false);
                  },
                  title: const Text(
                    'I understand local data and backups are my responsibility.',
                  ),
                ),
                const SizedBox(height: 8),
                AppPrimaryButton(
                  label: onboardingState?.isLoading == true
                      ? 'Saving...'
                      : 'Agree and continue',
                  icon: Icons.verified_outlined,
                  onPressed: !canContinue || onboardingState?.isLoading == true
                      ? null
                      : () => _accept(context, onboardingState),
                ),
              ],
            ),
          ),
        ] else ...[
          const SectionHeader('Review'),
          const AppInfoBanner(
            title: 'Viewed from Settings',
            message:
                'This is the same onboarding content shown on first launch. Use the back button to return to Settings.',
            icon: Icons.open_in_new_outlined,
          ),
          const SizedBox(height: 12),
          AppSecondaryButton(
            label: 'Close',
            icon: Icons.close,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
        if (onboardingState?.errorMessage != null) ...[
          const SizedBox(height: 12),
          AppInfoBanner(
            title: 'Onboarding unavailable',
            message: onboardingState!.errorMessage!,
            icon: Icons.warning_amber_outlined,
            accentColor: Theme.of(context).colorScheme.error,
          ),
        ],
      ],
    );
  }

  Future<void> _accept(
    BuildContext context,
    OnboardingState? onboardingState,
  ) async {
    if (onboardingState == null) {
      return;
    }
    final result = await onboardingState.accept();
    if (!context.mounted) {
      return;
    }
    result.when(
      success: (_) {},
      failure: (message) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.message});

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
