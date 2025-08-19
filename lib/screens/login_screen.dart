import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/background_service.dart'; // Add this import
import '../utils/constants.dart';
import 'dashboard_screen.dart';
import 'location_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isPopped = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isPopped) return;

          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null) {
              _isPopped = true;
              Navigator.pop(context, code);
            }
          }
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _deploymentCodeController = TextEditingController();
  final _locationService = LocationService();
  
  bool _isDeploymentCodeVisible = false;
  bool _isLoading = false;
  bool _isLocationChecking = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    print('LoginScreen: initState called');
    _getAppVersion();
  }

  @override
  void dispose() {
    print('LoginScreen: dispose called');
    _tokenController.dispose();
    _deploymentCodeController.dispose();
    super.dispose();
  }

  Future<void> _getAppVersion() async {
    try {
      print('LoginScreen: Getting app version...');
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = packageInfo.version);
        print('LoginScreen: App version retrieved: $_appVersion');
      }
    } catch (e) {
      print('LoginScreen: Error getting app version: $e');
      if (mounted) {
        setState(() => _appVersion = '1.0.0');
      }
    }
  }

  Future<void> _scanQRCode() async {
    try {
      print('LoginScreen: Starting QR scan...');
      final scannedCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const QRScannerScreen()),
      );

      if (scannedCode != null && mounted) {
        print('LoginScreen: QR code scanned: ${scannedCode.substring(0, 10)}...');
        setState(() => _tokenController.text = scannedCode);
      }
    } catch (e) {
      print('LoginScreen: Error scanning QR code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to scan QR code: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _checkLocationRequirements() async {
    if (!mounted) return false;
    
    print('LoginScreen: Checking location requirements...');
    setState(() => _isLocationChecking = true);
    
    try {
      final hasAccess = await _locationService.checkLocationRequirements();
      print('LoginScreen: Location access: $hasAccess');
      if (mounted) {
        setState(() => _isLocationChecking = false);
      }
      return hasAccess;
    } catch (e) {
      print('LoginScreen: Error checking location requirements: $e');
      if (mounted) {
        setState(() => _isLocationChecking = false);
      }
      return false;
    }
  }

  void _showLocationRequirementDialog() {
    if (!mounted) return;
    
    print('LoginScreen: Showing location requirement dialog');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.location_off, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            const Text('Location Required'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This app requires location access to function properly.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('Please ensure:'),
            SizedBox(height: 8),
            Text('• Location permission is granted'),
            Text('• Location services are enabled on your device'),
            SizedBox(height: 12),
            Text(
              'You cannot login without enabling location access.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToLocationSetup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tealAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Setup Location'),
          ),
        ],
      ),
    );
  }

  void _navigateToLocationSetup() {
    if (!mounted) return;
    
    print('LoginScreen: Navigating to location setup');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationScreen()),
    );
  }

  Future<void> _startBackgroundServiceAfterLogin() async {
    try {
      print('LoginScreen: Starting background service after successful login...');
      
      // Start background service with a small delay to ensure app is stable
      await Future.delayed(const Duration(milliseconds: 500));
      
      final started = await startBackgroundServiceSafely();
      print('LoginScreen: Background service start result: $started');
      
      if (started && mounted) {
        // Show a brief success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Background monitoring enabled ✓'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('LoginScreen: Error starting background service: $e');
      // Don't show error to user - app should continue working even without background service
    }
  }

  Future<void> _login() async {
    if (!mounted || !_formKey.currentState!.validate()) return;
    
    print('LoginScreen: Starting login process...');
    setState(() => _isLoading = true);

    try {
      // Step 1: Check location requirements
      print('LoginScreen: Step 1 - Checking location...');
      final hasLocationAccess = await _checkLocationRequirements();
      if (!hasLocationAccess) {
        print('LoginScreen: Location access denied');
        if (mounted) {
          setState(() => _isLoading = false);
          _showLocationRequirementDialog();
        }
        return;
      }
      print('LoginScreen: Location access granted');

      // Step 2: Perform API login
      print('LoginScreen: Step 2 - Performing API login...');
      final response = await ApiService.login(
        _tokenController.text.trim(),
        _deploymentCodeController.text.trim(),
      );
      print('LoginScreen: API response received - success: ${response.success}');

      if (!mounted) {
        print('LoginScreen: Widget not mounted after API call');
        return;
      }

      if (response.success) {
        print('LoginScreen: Login successful, saving credentials...');
        
        // Step 3: Save credentials
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _tokenController.text.trim());
          await prefs.setString('deploymentCode', _deploymentCodeController.text.trim());
          print('LoginScreen: Credentials saved successfully');
          
          // Step 4: Start background service
          _startBackgroundServiceAfterLogin(); // Don't await - let it run in background
          
          // Step 5: Navigate to dashboard
          print('LoginScreen: Navigating to dashboard...');
          
          // Add a small delay to ensure everything is saved
          await Future.delayed(const Duration(milliseconds: 200));
          
          if (mounted) {
            print('LoginScreen: About to navigate to DashboardScreen');
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) {
                  print('LoginScreen: Building DashboardScreen...');
                  return DashboardScreen(
                    token: _tokenController.text.trim(),
                    deploymentCode: _deploymentCodeController.text.trim(),
                  );
                },
              ),
            );
            
            print('LoginScreen: Navigation completed');
          } else {
            print('LoginScreen: Widget not mounted, cannot navigate');
          }
        } catch (e) {
          print('LoginScreen: Error saving credentials or navigating: $e');
          print('LoginScreen: Stack trace: ${StackTrace.current}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving login data: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print('LoginScreen: Login failed - ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('LoginScreen: Login error: $e');
      print('LoginScreen: Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      print('LoginScreen: Login process completed');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('LoginScreen: Building UI');
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
        elevation: 0,
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        reverse: true,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryRed.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/pnp_logo.png',
                      width: 120,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) {
                        print('LoginScreen: Error loading logo: $error');
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: const Icon(
                            Icons.shield,
                            size: 60,
                            color: AppColors.primaryRed,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppConstants.appTitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRed,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppConstants.appMotto,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              Text(
                'Secure Access Required',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryRed,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your authentication credentials',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: 'Token',
                  hintText: 'Input your token here',
                  prefixIcon: Icon(Icons.vpn_key, color: AppColors.primaryRed),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.qr_code_scanner, color: AppColors.primaryRed),
                    onPressed: _scanQRCode,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please input your token';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _deploymentCodeController,
                obscureText: !_isDeploymentCodeVisible,
                decoration: InputDecoration(
                  labelText: 'Deployment Code',
                  hintText: 'Enter your deployment code',
                  prefixIcon: Icon(Icons.badge, color: AppColors.primaryRed),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isDeploymentCodeVisible ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.primaryRed,
                    ),
                    onPressed: () {
                      setState(() {
                        _isDeploymentCodeVisible = !_isDeploymentCodeVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryRed, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your deployment code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isLocationChecking) ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading || _isLocationChecking
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(_isLocationChecking ? 'Checking Location...' : 'Authenticating...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login),
                            SizedBox(width: 8),
                            Text(
                              'Secure Login',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[900]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.lightBlueAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Contact your administrator if you don\'t have a token or deployment code',
                        style: TextStyle(
                          color: Colors.lightBlueAccent[100],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900]?.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copyright, color: Colors.grey[400], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '2025 Philippine National Police',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primaryRed.withOpacity(0.3)),
                      ),
                      child: Text(
                        AppConstants.developerCredit,
                        style: TextStyle(
                          color: Colors.red[300],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              Text(
                'v$_appVersion',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}