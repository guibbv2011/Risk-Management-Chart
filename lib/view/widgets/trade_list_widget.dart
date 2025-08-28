import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import '../../view_model/risk_management_view_model.dart';
import '../../model/trade.dart';

class TradeListWidget extends StatefulWidget {
  final RiskManagementViewModel viewModel;

  const TradeListWidget({super.key, required this.viewModel});

  @override
  State<TradeListWidget> createState() => _TradeListWidgetState();
}

class _TradeListWidgetState extends State<TradeListWidget> with SignalsMixin {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      padding: const EdgeInsets.only(left: 18.0, right: 18),
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height,
        maxHeight: MediaQuery.of(context).size.height,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trade History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Watch((_) {
                final tradesCount = widget.viewModel.trades.value.length;
                return Text(
                  'Total: $tradesCount trades',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                );
              }),
            ],
          ),
          const SizedBox(height: 4),

          Expanded(
            child: Watch((_) {
              final trades = widget.viewModel.trades.value;
              final riskSettings = widget.viewModel.riskSettings.value;

              return ListView.builder(
                itemCount: trades.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildInitialBalanceRow(riskSettings.accountBalance);
                  }

                  final tradeIndex = trades.length - index;
                  final trade = trades[tradeIndex];
                  final tradeNumber = tradeIndex + 1;
                  final runningBalance = _calculateRunningBalance(
                    trades,
                    tradeIndex,
                    riskSettings.accountBalance,
                  );

                  return _buildTradeRow(
                    trade: trade,
                    tradeNumber: tradeNumber,
                    runningBalance: runningBalance,
                    isLatest: index == 1,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialBalanceRow(double accountBalance) {
    return Container(
      height: 65,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '0',
                  style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Initial Balance',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Starting Point',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                  ),
                ],
              ),
            ),

            Tooltip(
              message: 'Balance',
              preferBelow: true,
              child: Text(
                '\$ ${accountBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeRow({
    required Trade trade,
    required int tradeNumber,
    required double runningBalance,
    required bool isLatest,
  }) {
    final isProfit = trade.result > 0;
    final color = isProfit ? Colors.green : Colors.red;
    final icon = isProfit ? Icons.trending_up : Icons.trending_down;

    return Container(
      height: 65,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLatest
            ? Colors.deepPurpleAccent.withValues(alpha: 0.1)
            : Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLatest
              ? Colors.deepPurpleAccent.withValues(alpha: 0.5)
              : Colors.grey.shade800,
          width: 1,
        ),
      ),
      child: Center(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$tradeNumber',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        isProfit ? 'Profit' : 'Loss',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      if (isLatest) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LATEST',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(trade.timestamp),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Tooltip(
                  message: 'Result',
                  preferBelow: true,
                  child: Text(
                    '\$\ ${isProfit ? '+' : ''}${trade.result.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Tooltip(
                  message: 'Balance',
                  preferBelow: true,
                  child: Text(
                    '\$ ${runningBalance.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateRunningBalance(
    List<Trade> trades,
    int upToIndex,
    double initialBalance,
  ) {
    double balance = initialBalance;

    for (int i = 0; i <= upToIndex && i < trades.length; i++) {
      balance += trades[i].result;
    }

    return balance;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
