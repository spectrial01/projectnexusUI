import 'package:flutter/material.dart';
import 'package:project_nexusv2/services/background_service.dart';
import 'screens/permission_screen.dart';
import 'utils/constants.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('Main: Flutter initialized');
    
    // Initialize background service but don't let it block app startup
    _initializeBackgroundServiceAsync();
    
    print('Main: Starting app...');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('Main: Error in main: $e');
    print('Main: Stack trace: $stackTrace');
    // Still try to run the app
    runApp(const MyApp());
  }
}

// Initialize background service asynchronously without blocking app startup
void _initializeBackgroundServiceAsync() {
  Future.delayed(const Duration(milliseconds: 500), () async {
    try {
      print('Main: Initializing background service asynchronously...');
      await initializeService();
      print('Main: Background service initialization completed');
    } catch (e) {
      print('Main: Background service initialization failed: $e');
      // App continues normally even if background service fails
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('MyApp: Building MaterialApp');
    
    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: AppColors.tealAccent,
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.cardBackground,
        colorScheme: const ColorScheme.dark().copyWith(
          secondary: AppColors.tealAccent,
          primary: AppColors.tealAccent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const PermissionScreen(),
    );
  }
}