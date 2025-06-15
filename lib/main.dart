import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'model/risk_management.dart';
import 'model/repository/persistent_trade_repository.dart';
import 'model/service/risk_management_service.dart';
import 'model/storage/app_storage.dart';
import 'model/storage/web_storage_init.dart';
import 'view_model/risk_management_view_model.dart';
import 'view/home_view.dart';
import 'view/screens/initialization_screen.dart';
import 'services/simple_persistence_fix.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable debug mode in production for web
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
      debugPrint('Starting app initialization...');
      debugPrint('Platform: ${kIsWeb ? 'Web' : 'Native'}');
      debugPrint('Mode: ${kDebugMode ? 'Debug' : 'Release'}');

      // Initialize platform-specific storage
      debugPrint('Initializing platform storage...');
      await StorageInitializer.initialize();
      debugPrint('Platform storage initialized successfully');

      // Initialize app storage
      debugPrint('Initializing app storage...');
      await AppStorageManager.initialize();
      debugPrint('App storage initialized successfully');

      // Check if we have stored data, if not attempt recovery
      debugPrint('Checking for existing data...');
      final hasData = await AppStorageManager.instance.hasStoredData();

      if (!hasData) {
        debugPrint('No existing data found, attempting simple recovery...');
        try {
          final recoveredData = await SimplePersistenceFix.tryRecoverData();
          if (recoveredData != null) {
            debugPrint('Recovery data found, attempting restore...');
            final restored = await SimplePersistenceFix.restoreData(
              recoveredData,
            );
            if (restored) {
              debugPrint('Data recovery successful');
            } else {
              debugPrint('Data recovery failed during restore');
            }
          } else {
            debugPrint('No recoverable data found');
          }
        } catch (recoveryError) {
          debugPrint('Data recovery failed: $recoveryError');
          // Continue without recovery - not a critical error
        }
      } else {
        debugPrint('Existing data found');
      }

      debugPrint('App initialization completed successfully');
    } catch (e) {
      debugPrint('App initialization failed: $e');
      debugPrint('Stack trace: ${StackTrace.current}');

      // For web platform, provide more specific error information
      if (kIsWeb) {
        throw Exception(
          'Web storage initialization failed. This may be due to:\n'
          '• Browser storage restrictions\n'
          '• IndexedDB not being available\n'
          '• Third-party cookies disabled\n\n'
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
    // Initialize persistent repository
    final storage = AppStorageManager.instance;
    final tradeRepository = PersistentTradeRepository(storage: storage.trades);

    // Initialize risk settings with default values
    final defaultRiskSettings = RiskManagement(
      maxDrawdown: 1000.0, // $1,000 max drawdown (absolute amount)
      lossPerTradePercentage: 5.0, // 5% risk per trade (of max drawdown)
      accountBalance: 10000.0, // $10,000 default account balance
      currentBalance: 10000.0, // Start with full balance
    );

    // Initialize service
    final riskService = RiskManagementService(
      tradeRepository: tradeRepository,
      riskSettings: defaultRiskSettings,
    );

    // Initialize view model
    _viewModel = RiskManagementViewModel(
      riskService: riskService,
      configStorage: storage.config,
    );

    // Attempt data recovery if the view model detects empty data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final trades = _viewModel.trades.value;
        final hasRiskSettings = await storage.config.hasRiskSettings();

        if (trades.isEmpty && !hasRiskSettings) {
          debugPrint('No data found in view model, attempting recovery...');
          await _viewModel.attemptDataRecovery();
        }
      } catch (e) {
        debugPrint('Post-frame recovery check failed: $e');
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
