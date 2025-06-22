import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import '../view_model/risk_management_view_model.dart';
import '../view_model/dialog_view_model.dart';
import '../model/service/risk_management_service.dart';
import 'widgets/trade_chart_widget.dart';
import 'widgets/trade_list_widget.dart';
import 'widgets/risk_controls_widget.dart';
import 'dialogs/input_dialog.dart';
import 'screens/settings_screen.dart';

class HomeView extends StatefulWidget {
  final RiskManagementViewModel viewModel;

  const HomeView({super.key, required this.viewModel});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SignalsMixin {
  late final DialogViewModel _dialogViewModel;

  @override
  void initState() {
    super.initState();
    _dialogViewModel = DialogViewModel();
  }

  @override
  void dispose() {
    _dialogViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.deepPurpleAccent,
        title: const Text('Risk Management App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'Risk Information',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _showClearAllDialog,
            tooltip: 'Clear All Trades',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Error message display
          Watch((_) {
            final errorMessage = widget.viewModel.errorMessage.value;
            if (errorMessage != null) {
              return Container(
                width: double.infinity,
                color: Colors.red.shade900,
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: widget.viewModel.clearError,
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Loading indicator
          Watch((_) {
            if (widget.viewModel.isLoading.value) {
              return const LinearProgressIndicator(
                color: Colors.deepPurpleAccent,
                backgroundColor: Colors.grey,
              );
            }
            return const SizedBox.shrink();
          }),

          // Risk Status Indicator
          Watch((_) {
            final riskStatus = widget.viewModel.riskStatus.value;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              color: widget.viewModel.getRiskStatusColor().withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getRiskStatusIcon(riskStatus),
                    color: widget.viewModel.getRiskStatusColor(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Risk Status: ${widget.viewModel.getRiskStatusText()}',
                    style: TextStyle(
                      color: widget.viewModel.getRiskStatusColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Main content - responsive layout
          Expanded(child: _buildResponsiveLayout()),
        ],
      ),
    );
  }

  IconData _getRiskStatusIcon(RiskStatus status) {
    switch (status) {
      case RiskStatus.low:
        return Icons.check_circle;
      case RiskStatus.medium:
        return Icons.warning;
      case RiskStatus.high:
        return Icons.error;
      case RiskStatus.critical:
        return Icons.dangerous;
    }
  }

  void _showMaxDrawdownDialog() {
    _dialogViewModel.openMaxDrawdownDialog(
      isDynamicEnabled:
          widget.viewModel.riskSettings.value.isDynamicMaxDrawdown,
      currentBalance: widget.viewModel.riskSettings.value.accountBalance
          .toStringAsFixed(2),
      currentMaxDrawdown: widget.viewModel.riskSettings.value.maxDrawdown
          .toStringAsFixed(2),
    );
    _showInputDialog(
      onConfirm: (value, accountBalance, [isDynamicEnabled]) async {
        await widget.viewModel.updateMaxDrawdown(
          value,
          accountBalance,
          isDynamicEnabled,
        );
      },
    );
  }

  void _showLossPerTradeDialog() {
    _dialogViewModel.openLossPerTradeDialog(
      currentValue: widget.viewModel.riskSettings.value.lossPerTradePercentage
          .toStringAsFixed(0),
    );
    _showInputDialog(
      onConfirm: (value, _, [__]) async {
        await widget.viewModel.updateLossPerTrade(value);
      },
    );
  }

  void _showAddTradeDialog() {
    _dialogViewModel.openTradeResultDialog();
    _showInputDialog(
      onConfirm: (value, _, [__]) async {
        await widget.viewModel.addTrade(value);
      },
    );
  }

  void _showInputDialog({
    required Future<void> Function(String, String?, [bool?]) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) =>
          InputDialog(viewModel: _dialogViewModel, onConfirm: onConfirm),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Risk Management Info'),
        content: Watch((_) {
          final stats = widget.viewModel.statistics.value;
          if (stats == null) {
            return const Text('Loading statistics...');
          }

          return //SingleChildScrollView(child:
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('Total Trades', '${stats.totalTrades}'),
              _buildStatRow(
                'Total P&L',
                '${stats.totalPnL.toStringAsFixed(2)}',
              ),
              _buildStatRow('Win Rate', '${stats.winRate.toStringAsFixed(1)}%'),
              _buildStatRow(
                'Current Drawdown',
                '${stats.currentDrawdown.toStringAsFixed(2)}',
              ),
              _buildStatRow(
                'Max Allowed Drawdown',
                '${stats.maxAllowedDrawdown.toStringAsFixed(2)}',
              ),
              _buildStatRow(
                'Remaining Risk',
                '${stats.remainingRiskCapacity.toStringAsFixed(2)}',
              ),
              _buildStatRow(
                'Average Win',
                '${stats.averageWin.toStringAsFixed(2)}',
              ),
              _buildStatRow(
                'Average Loss',
                '${stats.averageLoss.toStringAsFixed(2)}',
              ),
              _buildStatRow(
                'Risk/Reward Ratio',
                '${stats.riskRewardRatio.toStringAsFixed(2)}',
              ),
            ],
            // ),
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Trades'),
        content: const Text(
          'Are you sure you want to clear all trades? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await widget.viewModel.clearAllTrades();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(viewModel: widget.viewModel),
      ),
    );
  }

  Widget _buildResponsiveLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktopOrWeb = _isDesktopOrWeb();
        final isMobile = _isMobile(constraints);

        if (isDesktopOrWeb && !isMobile) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  bool _isDesktopOrWeb() {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  bool _isMobile(BoxConstraints constraints) {
    // Consider it mobile if width is less than 800px
    return constraints.maxWidth < 800;
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Chart widget (top half)
        Expanded(flex: 2, child: TradeChartWidget(viewModel: widget.viewModel)),
        // Trade list widget (bottom half)
        Expanded(flex: 2, child: TradeListWidget(viewModel: widget.viewModel)),

        // Risk controls (bottom)
        RiskControlsWidget(
          viewModel: widget.viewModel,
          onMaxDrawdownPressed: () => _showMaxDrawdownDialog(),
          onLossPerTradePressed: () => _showLossPerTradeDialog(),
          onAddTradePressed: () => _showAddTradeDialog(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // Main content area - side by side
        Expanded(
          child: Row(
            children: [
              // Chart widget (left side)
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: TradeChartWidget(viewModel: widget.viewModel),
                ),
              ),

              // Trade list widget (right side)
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: TradeListWidget(viewModel: widget.viewModel),
                ),
              ),
            ],
          ),
        ),

        // Risk controls (bottom)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: RiskControlsWidget(
            viewModel: widget.viewModel,
            onMaxDrawdownPressed: () => _showMaxDrawdownDialog(),
            onLossPerTradePressed: () => _showLossPerTradeDialog(),
            onAddTradePressed: () => _showAddTradeDialog(),
          ),
        ),
      ],
    );
  }
}
