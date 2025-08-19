import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/permission_status_widget.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  PermissionStatus _locationPermissionStatus = PermissionStatus.denied;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    setState(() => _isLoading = true);
    
    try {
      final status = await Permission.location.status;
      if (mounted) {
        setState(() {
          _locationPermissionStatus = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      if (mounted) {
        setState(() => _locationPermissionStatus = status);

        if (status.isPermanentlyDenied) {
          _showSettingsDialog();
        } else if (status.isGranted) {
          _showSuccessMessage();
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Please enable location permission in Settings to use this app. This permission is required for security purposes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location permission granted! You can now login.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Monitor Permissions'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project Nexus',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This app requires location permission for security purposes',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 32),

                  PermissionStatusWidget(
                    status: _locationPermissionStatus,
                    title: 'Location Permission',
                    description: 'Location permission is required to access this app for security purposes.',
                    onRequest: _requestLocationPermission,
                  ),

                  const SizedBox(height: 32),

                  if (_locationPermissionStatus.isGranted) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[900]?.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ready to Go!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  'All permissions are granted. You can now access the app.',
                                  style: TextStyle(
                                    color: Colors.green[200],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _locationPermissionStatus.isGranted
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              )
                          : null,
                      icon: Icon(
                        _locationPermissionStatus.isGranted
                            ? Icons.login
                            : Icons.lock,
                      ),
                      label: Text(
                        _locationPermissionStatus.isGranted
                            ? 'Continue to Login'
                            : 'Location Required for Login',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _locationPermissionStatus.isGranted
                            ? AppColors.tealAccent
                            : Colors.grey[700],
                        foregroundColor: _locationPermissionStatus.isGranted
                            ? Colors.black
                            : Colors.grey[400],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Card(
                    color: Colors.blue[900],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.security, color: Colors.lightBlueAccent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Why Location Permission?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.lightBlueAccent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'This app requires location access for security verification and real-time device monitoring features.',
                                  style: TextStyle(
                                    color: Colors.lightBlueAccent[100],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}