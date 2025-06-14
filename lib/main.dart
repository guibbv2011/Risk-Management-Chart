import 'package:flutter/material.dart';
import 'model/risk_management.dart';
import 'model/repository/trade_repository.dart';
import 'model/service/risk_management_service.dart';
import 'view_model/risk_management_view_model.dart';
import 'view/home_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      title: 'Risk Management',
      color: Colors.black,
      theme: ThemeData(brightness: Brightness.dark),
      home: const RiskManagementScreen(),
    );
  }
}

class RiskManagementScreen extends StatefulWidget {
  const RiskManagementScreen({super.key});

  @override
  State<RiskManagementScreen> createState() => _RiskManagementScreenState();
}

class _RiskManagementScreenState extends State<RiskManagementScreen> {
  late final RiskManagementViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _initializeViewModel();
  }

  void _initializeViewModel() {
    // Initialize repository
    final tradeRepository = InMemoryTradeRepository();

    // Initialize risk settings with default values
    final riskSettings = RiskManagement(
      maxDrawdown: 1000.0, // $1,000 max drawdown (absolute amount)
      lossPerTradePercentage: 5.0, // 5% risk per trade (of max drawdown)
      accountBalance: 10000.0, // $10,000 default account balance
      currentBalance: 10000.0, // Start with full balance
    );

    // Initialize service
    final riskService = RiskManagementService(
      tradeRepository: tradeRepository,
      riskSettings: riskSettings,
    );

    // Initialize view model
    _viewModel = RiskManagementViewModel(riskService: riskService);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeView(viewModel: _viewModel);
  }
}
