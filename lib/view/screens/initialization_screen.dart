import 'package:flutter/material.dart';
import '../../model/storage/web_storage_init.dart';

class InitializationScreen extends StatefulWidget {
  final Future<void> Function() onInitialize;
  final Widget Function() buildMainApp;

  const InitializationScreen({
    super.key,
    required this.onInitialize,
    required this.buildMainApp,
  });

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  bool _isInitializing = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _isInitializing = true;
        _hasError = false;
        _errorMessage = null;
      });

      await widget.onInitialize();

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return _buildLoadingScreen();
    }

    if (_hasError) {
      return _buildErrorScreen();
    }

    return widget.buildMainApp();
  }

  Widget _buildLoadingScreen() {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.deepPurpleAccent, width: 2),
                ),
                child: const Icon(
                  Icons.trending_up,
                  size: 40,
                  color: Colors.deepPurpleAccent,
                ),
              ),

              const SizedBox(height: 32),

              // App Title
              const Text(
                'Risk Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Loading indicator
              const CircularProgressIndicator(
                color: Colors.deepPurpleAccent,
                strokeWidth: 3,
              ),

              const SizedBox(height: 16),

              // Loading text
              const Text(
                'Initializing storage...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),

              const SizedBox(height: 8),

              // Platform info
              Text(
                'Platform: ${StorageInitializer.getPlatformInfo()}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),

              const SizedBox(height: 4),

              // Additional info
              const Text(
                'Setting up local database and preferences',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 40,
                    color: Colors.red,
                  ),
                ),

                const SizedBox(height: 32),

                // Error Title
                const Text(
                  'Initialization Failed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Error Message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Storage Initialization Failed',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Platform: ${StorageInitializer.getPlatformInfo()}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Error Details:',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _errorMessage ?? 'Unknown error occurred',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _initialize,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Initialization'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _continueWithoutStorage,
                        icon: const Icon(Icons.warning),
                        label: const Text('Continue Without Storage'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Warning Text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Continuing without storage will use in-memory data only. Your data will not be saved.',
                          style: TextStyle(color: Colors.orange, fontSize: 11),
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
    );
  }

  void _continueWithoutStorage() {
    // Set a flag or call a method to continue with in-memory storage
    // For now, just set the state to not initializing and not error
    setState(() {
      _isInitializing = false;
      _hasError = false;
      _errorMessage = null;
    });
  }
}
