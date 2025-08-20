import 'package:risk_management/model/trade.dart';

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

    import 'dart:math' as math;
    final List<double> drawdowns = [];
    double currentBalance = initialBalance;
    double peakBalance = initialBalance;
    double currentDrawdown = -maxDrawdown; // Start at negative max drawdown as requested

    for (final trade in trades) {
      currentBalance += trade.result;

      // Update peak for dynamic mode
      if (currentBalance > peakBalance) {
        peakBalance = currentBalance;
      }

      // Calculate potential new drawdown
      double potentialDrawdown = isDynamic
          ? currentBalance - peakBalance
          : currentBalance - initialBalance;

      if (trade.result < 0) {
        // For losses: don't change drawdown (add 0)
        // Keep current drawdown as is
      } else if (trade.result > 0) {
        // For profits: only change if drawdown hasn't reached maxDrawdown distance
        double distanceToMax = math.abs(currentDrawdown) - maxDrawdown;
        if (distanceToMax < 0) { // Hasn't reached max distance yet
          // Do not change drawdown
        } else {
          // Adjust drawdown toward 0 by the profit amount
          currentDrawdown = math.min(currentDrawdown + trade.result, 0.0);
        }
      } else {
        // Neutral trade: clamp to max drawdown
        currentDrawdown = math.max(potentialDrawdown, -maxDrawdown);
      }

      // In dynamic mode, allow jumping above 0
      if (isDynamic && currentDrawdown > 0) {
        // Allow it to jump higher than 0
      } else {
        // Always clamp to not exceed max drawdown negatively
        currentDrawdown = math.max(currentDrawdown, -maxDrawdown);
      }

      drawdowns.add(currentDrawdown);
    }

    return drawdowns;
  }
}
