import 'package:flutter/material.dart';

import '../../core/data/mock_market_data.dart';
import '../../core/widgets/app_page.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  static const routeName = '/activity';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Activity',
      subtitle: 'Recent paper transactions and orders',
      children: [
        ...MockMarketData.activity.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.14),
                  child: const Icon(Icons.receipt_long_outlined),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(item.subtitle),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.amount,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      item.status,
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
