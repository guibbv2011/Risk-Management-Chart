import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import '../../view_model/risk_management_view_model.dart';

class RiskControlsWidget extends StatefulWidget {
  final RiskManagementViewModel viewModel;
  final VoidCallback onMaxDrawdownPressed;
  final VoidCallback onLossPerTradePressed;
  final VoidCallback onAddTradePressed;

  const RiskControlsWidget({
    super.key,
    required this.viewModel,
    required this.onMaxDrawdownPressed,
    required this.onLossPerTradePressed,
    required this.onAddTradePressed,
  });

  @override
  State<RiskControlsWidget> createState() => _RiskControlsWidgetState();
}

class _RiskControlsWidgetState extends State<RiskControlsWidget>
    with SignalsMixin {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Main controls card
          Expanded(
            child: Container(
              height: 80.0,
              margin: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Card(
                  color: Colors.grey.shade900,
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Max Drawdown Button
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                tooltip: "Set Max Drawdown (\$)",
                                color: Colors.deepPurpleAccent,
                                icon: const Icon(Icons.heart_broken, size: 24),
                                onPressed: widget.onMaxDrawdownPressed,
                              ),
                              const Text(
                                'Max DD (\$)',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Loss Per Trade Button
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                tooltip: "Set % Loss Per Trade",
                                color: Colors.deepPurpleAccent,
                                icon: const Icon(Icons.percent, size: 24),
                                onPressed: widget.onLossPerTradePressed,
                              ),
                              const Text(
                                '% Loss',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Max Loss Display
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.redAccent,
                                    width: 1,
                                  ),
                                ),
                                child: Watch((_) {
                                  return Text(
                                    widget.viewModel.formattedMaxLossPerTrade,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }),
                              ),
                              const Text(
                                'Max Loss (\$)',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Add Trade Button
          Container(
            height: 80.0,
            width: 80.0,
            child: Card(
              color: Colors.grey.shade900,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                onTap: widget.onAddTradePressed,
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle,
                      color: Colors.deepPurpleAccent,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Add Trade',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
