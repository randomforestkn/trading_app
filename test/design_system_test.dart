import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/widgets/app_buttons.dart';
import 'package:trading_app/core/widgets/app_card.dart';
import 'package:trading_app/core/widgets/app_info_banner.dart';
import 'package:trading_app/core/widgets/app_pill_chip.dart';
import 'package:trading_app/core/widgets/app_stat_tile.dart';
import 'package:trading_app/core/widgets/empty_state_view.dart';
import 'package:trading_app/core/widgets/loading_state_view.dart';

void main() {
  testWidgets('reusable widgets render correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppCard(child: Text('Card content')),
                const SizedBox(height: 12),
                const LoadingStateView(message: 'Loading demo data...'),
                const SizedBox(height: 12),
                const EmptyStateView(
                  title: 'Empty',
                  message: 'Nothing to show here.',
                  icon: Icons.inbox_outlined,
                ),
                const SizedBox(height: 12),
                const AppInfoBanner(title: 'Banner', message: 'Banner copy'),
                const SizedBox(height: 12),
                const AppStatTile(label: 'Label', value: 'Value'),
                const SizedBox(height: 12),
                AppPillChip(label: 'Chip', selected: true, onSelected: (_) {}),
                const SizedBox(height: 12),
                AppPrimaryButton(label: 'Primary', onPressed: () {}),
                const SizedBox(height: 12),
                AppSecondaryButton(label: 'Secondary', onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Card content'), findsOneWidget);
    expect(find.text('Loading demo data...'), findsOneWidget);
    expect(find.text('Empty'), findsOneWidget);
    expect(find.text('Banner copy'), findsOneWidget);
    expect(find.text('Label'), findsOneWidget);
    expect(find.text('Chip'), findsOneWidget);
    expect(find.byType(AppPrimaryButton), findsOneWidget);
    expect(find.byType(AppSecondaryButton), findsOneWidget);
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Secondary'), findsOneWidget);
  });
}
