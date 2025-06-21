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

      // Initialize app storage with IndexedDB/SQLite
      debugPrint('Initializing app storage...');
      await AppStorageManager.initialize();
      debugPrint('App storage initialized successfully');

      // Enhanced data checking and recovery process
      debugPrint('🔍 Starting comprehensive data check...');

      // Immediate storage check to see what's actually there
      final startupData = await SimplePersistenceFix.checkStartupData();
      debugPrint('Startup storage scan: ${startupData['hasAnyData']}');

      // First, check primary storage
      final hasData = await AppStorageManager.instance.hasStoredData();
      debugPrint('Primary storage has data: $hasData');

      // Get detailed storage info
      final storageInfo = await AppStorageManager.instance.getStorageInfo();
      debugPrint('Storage info: $storageInfo');

      // Check for backup data regardless of primary storage status
      debugPrint('🔄 Checking backup storage locations...');
      final recoveredData = await SimplePersistenceFix.tryRecoverData();

      if (!hasData && recoveredData == null) {
        debugPrint('❌ No data found in primary or backup storage');
      } else if (!hasData && recoveredData != null) {
        debugPrint('⚠️ No primary data but backup data found, restoring...');
        try {
          final restored = await SimplePersistenceFix.restoreData(
            recoveredData,
          );
          if (restored) {
            debugPrint('✅ Data successfully restored from backup');
          } else {
            debugPrint('❌ Failed to restore backup data');
          }
        } catch (e) {
          debugPrint('❌ Backup restore error: $e');
        }
      } else if (hasData && recoveredData != null) {
        debugPrint('✅ Both primary and backup data available');
      } else {
        debugPrint('✅ Primary data available, backup not needed');
      }

      // Final verification
      final finalHasData = await AppStorageManager.instance.hasStoredData();
      debugPrint('🎯 Final data status: $finalHasData');

      // Log storage implementation info
      debugPrint(
        '📊 Storage: ${kIsWeb ? 'Web (IndexedDB)' : 'Native (SQLite)'}',
      );

      debugPrint('App initialization completed successfully');
    } catch (e) {
      debugPrint('App initialization failed: $e');
      debugPrint('Stack trace: ${StackTrace.current}');

      // For web platform, provide more specific error information
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
    // Initialize persistent repository
    final storage = AppStorageManager.instance;
    final tradeRepository = PersistentTradeRepository(storage: storage.trades);

    // Initialize risk settings with validated default values
    final defaultRiskSettings = InitializationValidator.createDefaultSettings();

    // Log initial state for verification
    InitializationValidator.logCurrentState(
      defaultRiskSettings,
      'Application Startup',
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

    // Enhanced post-frame data verification and recovery
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        debugPrint('🔄 Post-frame data verification starting...');

        final trades = _viewModel.trades.value;
        final hasRiskSettings = await storage.config.hasRiskSettings();
        final tradesCount = await storage.trades.getTradesCount();

        debugPrint('View model trades: ${trades.length}');
        debugPrint('Has risk settings: $hasRiskSettings');
        debugPrint('Database trades count: $tradesCount');

        // Force refresh if view model is empty but database has data
        if (trades.isEmpty && tradesCount > 0) {
          debugPrint(
            '🔄 View model empty but database has data, forcing reload...',
          );
          await _viewModel.forceReload();
        }

        // Try recovery if both view model and database are empty
        if (trades.isEmpty && !hasRiskSettings && tradesCount == 0) {
          debugPrint('🔄 No data anywhere, attempting recovery...');
          await _viewModel.attemptDataRecovery();

          // Final check after recovery attempt
          final finalTrades = _viewModel.trades.value;
          final finalCount = await storage.trades.getTradesCount();
          debugPrint(
            'After recovery - View model: ${finalTrades.length}, Database: $finalCount',
          );
        }

        debugPrint('✅ Post-frame verification completed');
      } catch (e) {
        debugPrint('❌ Post-frame recovery check failed: $e');
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
