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

      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Card(
                color: Colors.grey.shade900,
                elevation: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            tooltip: "Set % Loss Per Trade",
                            color: Colors.deepPurpleAccent,
                            icon: const Icon(Icons.percent, size: 20),
                            onPressed: widget.onLossPerTradePressed,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: "Set Max Drawdown (\$)",
                            color: Colors.deepPurpleAccent,
                            icon: const Icon(Icons.trending_down, size: 20),
                            onPressed: widget.onMaxDrawdownPressed,
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.2),
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
                                    fontSize: 14,
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
          SizedBox(
            height: 60.0,
            width: 60.0,
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
                        size: 24,
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
