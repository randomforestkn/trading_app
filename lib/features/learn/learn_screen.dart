import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/data/mock_market_data.dart';
import '../../core/models/asset.dart';
import '../../core/models/learn_topic.dart';
import '../../core/widgets/app_page.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Learn',
      subtitle: 'Beginner guides for each asset class',
      children: MockMarketData.learnTopics
          .map(
            (topic) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LearnCard(topic: topic),
            ),
          )
          .toList(),
    );
  }
}

class _LearnCard extends StatelessWidget {
  const _LearnCard({required this.topic});

  final LearnTopic topic;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: _colorForType(
                topic.type,
              ).withValues(alpha: 0.14),
              child: Icon(
                _iconForType(topic.type),
                color: _colorForType(topic.type),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    topic.summary,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    topic.takeaway,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(AssetType type) {
    return switch (type) {
      AssetType.stock => Icons.business_center_outlined,
      AssetType.etf => Icons.grid_view_rounded,
      AssetType.cfd => Icons.speed_outlined,
      AssetType.option => Icons.call_split_outlined,
      AssetType.crypto => Icons.currency_bitcoin,
      AssetType.bond => Icons.account_balance_outlined,
    };
  }

  Color _colorForType(AssetType type) {
    return switch (type) {
      AssetType.stock => AppTheme.primary,
      AssetType.etf => AppTheme.secondary,
      AssetType.cfd => AppTheme.warning,
      AssetType.option => const Color(0xFFBCA8FF),
      AssetType.crypto => const Color(0xFFFFD166),
      AssetType.bond => const Color(0xFF9FE7F5),
    };
  }
}
