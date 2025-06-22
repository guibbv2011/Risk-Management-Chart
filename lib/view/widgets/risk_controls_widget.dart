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
    return BottomAppBar(
      color: Colors.transparent,

      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Main controls card
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Card(
                color: Colors.grey.shade900,
                elevation: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Loss Per Trade Button
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            tooltip: "Set % Loss Per Trade",
                            color: Colors.deepPurpleAccent,
                            icon: const Icon(Icons.percent, size: 24),
                            onPressed: widget.onLossPerTradePressed,
                          ),
                        ],
                      ),
                    ),
                    // Max Drawdown Button
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: "Set Max Drawdown (\$)",
                            color: Colors.deepPurpleAccent,
                            icon: const Icon(Icons.trending_down, size: 24),
                            onPressed: widget.onMaxDrawdownPressed,
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
                              return Tooltip(
                                message: 'Max Loss (\$)',
                                child: Text(
                                  widget.viewModel.formattedMaxLossPerTrade,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                    Tooltip(
                      message: 'Add Trade',
                      child: Icon(
                        Icons.add_circle,
                        color: Colors.deepPurpleAccent,
                        size: 32,
                      ),
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
