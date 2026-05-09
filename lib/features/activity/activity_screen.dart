import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/data/paper_trading_state.dart';
import '../../core/models/paper_order.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill_chip.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/app_page.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  static const routeName = '/activity';

  @override
  Widget build(BuildContext context) {
    final tradingState = PaperTradingScope.of(context);
    final orders = tradingState.orders;

    return AppPage(
      title: 'Activity',
      subtitle: 'Recent paper transactions and orders',
      children: [
        if (orders.isEmpty)
          const EmptyStateView(
            title: 'No paper orders yet',
            message:
                'Executed paper trades will appear here after confirmation.',
            icon: Icons.receipt_long_outlined,
          )
        else
          ...orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        (order.side == PaperOrderSide.buy
                                ? AppTheme.primary
                                : AppTheme.danger)
                            .withValues(alpha: 0.14),
                    child: Icon(
                      order.side == PaperOrderSide.buy
                          ? Icons.add_chart
                          : Icons.remove_circle_outline,
                      color: order.side == PaperOrderSide.buy
                          ? AppTheme.primary
                          : AppTheme.danger,
                    ),
                  ),
                  title: Row(
                    children: [
                      AppPillChip(
                        label: order.side.label,
                        selected: true,
                        onSelected: (_) {},
                        selectedColor: order.side == PaperOrderSide.buy
                            ? AppTheme.primary
                            : AppTheme.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${order.quantity.toStringAsFixed(4)} ${order.assetSymbol}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${order.assetName} • ${_formatTimestamp(order.timestamp)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: SizedBox(
                    width: 92,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${order.estimatedTotal.toStringAsFixed(2)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          order.status.label,
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final month = _monthName(timestamp.month);
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$month ${timestamp.day}, ${timestamp.year} at $hour:$minute';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
