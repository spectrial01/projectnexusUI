import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/permission_status_widget.dart';
import '../services/permission_service.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final _permissionService = PermissionService();
  
  Map<String, bool> _permissions = {
    'location': false,
    'camera': false,
    'notification': false,
  };
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    setState(() => _isLoading = true);
    
    try {
      final permissions = await _permissionService.checkAllPermissions();
      if (mounted) {
        setState(() {
          _permissions = permissions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('PermissionScreen: Error checking permissions: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await _permissionService.requestAllPermissions();
      if (mounted) {
        setState(() {
          _permissions = results;
          _isLoading = false;
        });
        
        // Show results
        _showPermissionResults(results);
      }
    } catch (e) {
      print('PermissionScreen: Error requesting permissions: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _requestSpecificPermission(String permissionType) async {
    Permission permission;
    switch (permissionType) {
      case 'location':
        permission = Permission.location;
        break;
      case 'camera':
        permission = Permission.camera;
        break;
      case 'notification':
        permission = Permission.notification;
        break;
      default:
        return;
    }

    try {
      final granted = await _permissionService.requestPermission(permission);
      if (mounted) {
        setState(() {
          _permissions[permissionType] = granted;
        });
        
        if (!granted) {
          await _permissionService.showPermissionRationale(context, permissionType);
        }
      }
    } catch (e) {
      print('PermissionScreen: Error requesting $permissionType permission: $e');
    }
  }

  void _showPermissionResults(Map<String, bool> results) {
    final granted = results.values.where((v) => v).length;
    final total = results.length;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Permissions granted: $granted/$total'),
        backgroundColor: granted == total ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool get _canProceed => _permissions['location']! && _permissions['notification']!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Permissions'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAllPermissions,
            tooltip: 'Refresh Status',
          ),
        ],
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
                    'Please grant the following permissions for full functionality',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Location Permission
                  PermissionStatusWidget(
                    status: _permissions['location']! ? PermissionStatus.granted : PermissionStatus.denied,
                    title: 'Location Permission',
                    description: 'Required for GPS tracking and position monitoring',
                    onRequest: () => _requestSpecificPermission('location'),
                  ),
                  const SizedBox(height: 16),

                  // Camera Permission  
                  PermissionStatusWidget(
                    status: _permissions['camera']! ? PermissionStatus.granted : PermissionStatus.denied,
                    title: 'Camera Permission',
                    description: 'Used for QR code scanning and evidence capture',
                    onRequest: () => _requestSpecificPermission('camera'),
                  ),
                  const SizedBox(height: 16),

                  // Notification Permission
                  PermissionStatusWidget(
                    status: _permissions['notification']! ? PermissionStatus.granted : PermissionStatus.denied,
                    title: 'Notification Permission',
                    description: 'Essential for background monitoring alerts',
                    onRequest: () => _requestSpecificPermission('notification'),
                  ),
                  const SizedBox(height: 32),

                  // Grant All Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _requestAllPermissions,
                      icon: _isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.security),
                      label: Text(
                        _isLoading ? 'Requesting Permissions...' : 'Grant All Permissions',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Continue Button
                  if (_canProceed) ...[
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
                                  'Ready to Continue!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  'Essential permissions granted. Camera permission is optional.',
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
                      onPressed: _canProceed
                          ? () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              )
                          : null,
                      icon: Icon(
                        _canProceed ? Icons.login : Icons.lock,
                      ),
                      label: Text(
                        _canProceed
                            ? 'Continue to Login'
                            : 'Location & Notification Required',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canProceed
                            ? AppColors.tealAccent
                            : Colors.grey[700],
                        foregroundColor: _canProceed
                            ? Colors.black
                            : Colors.grey[400],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Information Cards
                  Card(
                    color: Colors.blue[900],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info, color: Colors.lightBlueAccent),
                              const SizedBox(width: 12),
                              const Text(
                                'Permission Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.lightBlueAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '📍 Location: GPS tracking for security monitoring\n'
                            '📷 Camera: QR code scanning and evidence capture\n'
                            '🔔 Notifications: Background monitoring alerts',
                            style: TextStyle(
                              color: Colors.lightBlueAccent[100],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    color: Colors.orange[900],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.settings, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Manual Setup',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                Text(
                                  'You can also enable permissions manually in Settings > Apps > Project Nexus > Permissions',
                                  style: TextStyle(
                                    color: Colors.orange[100],
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