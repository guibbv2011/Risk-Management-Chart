import 'package:risk_management/model/trade.dart';
import 'dart:math' as math;

class DrawdownCalculator {
  static List<double> calculateDrawdownPerTrade(
    List<Trade> trades,
    double initialBalance,
    double maxDrawdown,
    bool isDynamic,
  ) {
    if (trades.isEmpty) {
      return [];
    }

    final List<double> drawdowns = [];
    double currentBalance = initialBalance;
    double peakBalance = initialBalance;
    double currentDrawdown = -maxDrawdown;

    for (final trade in trades) {
      currentBalance += trade.result;

      if (currentBalance > peakBalance) {
        peakBalance = currentBalance;
      }

      double potentialDrawdown = isDynamic
          ? currentBalance - peakBalance
          : currentBalance - initialBalance;

      if (trade.result < 0) {
      } else if (trade.result > 0) {
        double distanceToMax = (currentDrawdown) - maxDrawdown;
        if (distanceToMax < 0) {
        } else {
          currentDrawdown = math.min(currentDrawdown + trade.result, 0.0);
        }
      } else {
        currentDrawdown = math.max(potentialDrawdown, -maxDrawdown);
      }

      if (isDynamic && currentDrawdown > 0) {
      } else {
        currentDrawdown = math.max(currentDrawdown, -maxDrawdown);
      }

      drawdowns.add(currentDrawdown);
    }

    return drawdowns;
  }
}
