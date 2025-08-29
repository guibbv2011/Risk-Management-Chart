import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'model/repository/persistent_trade_repository.dart';
import 'model/service/risk_management_service.dart';
import 'model/storage/app_storage.dart';

import 'view_model/risk_management_view_model.dart';
import 'view/home_view.dart';
import 'view/screens/initialization_screen.dart';

import 'services/simple_persistence_fix.dart';
import 'utils/initialization_validator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb && kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return InitializationScreen(
      onInitialize: _initializeApp,
      buildMainApp: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        title: 'Risk Management',
        color: Colors.black,
        theme: ThemeData(brightness: Brightness.dark),
        home: const RiskManagementScreen(),
      ),
    );
  }

  Future<void> _initializeApp() async {
    try {
      await AppStorageManager.initialize();
      await SimplePersistenceFix.checkStartupData();
      final hasData = await AppStorageManager.instance.hasStoredData();

      await AppStorageManager.instance.getStorageInfo();

      final recoveredData = await SimplePersistenceFix.tryRecoverData();

      if (!hasData && recoveredData == null) {

      } else if (!hasData && recoveredData != null) {

        try {
          final restored = await SimplePersistenceFix.restoreData(
            recoveredData,
          );
          if (restored) {

          } else {

          }
        } catch (e) {
          rethrow;
        }
      } else if (hasData && recoveredData != null) {

      } else {
      }

      await AppStorageManager.instance.hasStoredData();

    } catch (e) {
      if (kIsWeb) {
        throw Exception(
          'IndexedDB storage initialization failed. This may be due to:\n'
          '• Browser storage restrictions\n'
          '• IndexedDB not being available\n'
          '• Third-party cookies disabled\n'
          '• Private browsing mode\n\n'
          'Original error: ${e.toString()}',
        );
      }

      rethrow;
    }
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
    final storage = AppStorageManager.instance;
    final tradeRepository = PersistentTradeRepository(storage: storage.trades);

    final defaultRiskSettings = InitializationValidator.createDefaultSettings();

    final riskService = RiskManagementService(
      tradeRepository: tradeRepository,
      riskSettings: defaultRiskSettings,
    );

    _viewModel = RiskManagementViewModel(
      riskService: riskService,
      configStorage: storage.config,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {

        final trades = _viewModel.trades.value;
        final hasRiskSettings = await storage.config.hasRiskSettings();
        final tradesCount = await storage.trades.getTradesCount();

        if (trades.isEmpty && tradesCount > 0) {
          await _viewModel.forceReload();
        }

        if (trades.isEmpty && !hasRiskSettings && tradesCount == 0) {
          await _viewModel.attemptDataRecovery();

          // final finalTrades = _viewModel.trades.value;
          // final finalCount = await storage.trades.getTradesCount();
        }

      } catch (e) {
        rethrow;
      }
    });
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
