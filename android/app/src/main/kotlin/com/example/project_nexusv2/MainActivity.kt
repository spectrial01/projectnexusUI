package com.example.project_nexusv2

import android.os.Bundle
import android.os.PowerManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "pnp_device_monitor/wakelock"
    private var wakeLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableWakeLock" -> {
                    enableWakeLock()
                    result.success(true)
                }
                "disableWakeLock" -> {
                    disableWakeLock()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Keep screen on when app is running
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
    }

    private fun enableWakeLock() {
        try {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "PNPDeviceMonitor:WakeLock"
            )
            wakeLock?.acquire(10*60*1000L /*10 minutes*/)
            
            // Also keep screen on
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            
            android.util.Log.d("WakeLock", "Wake lock enabled successfully")
        } catch (e: Exception) {
            android.util.Log.e("WakeLock", "Error enabling wake lock", e)
        }
    }

    private fun disableWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                }
            }
            wakeLock = null
            
            // Remove screen on flag
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            
            android.util.Log.d("WakeLock", "Wake lock disabled successfully")
        } catch (e: Exception) {
            android.util.Log.e("WakeLock", "Error disabling wake lock", e)
        }
    }

    override fun onDestroy() {
        disableWakeLock()
        super.onDestroy()
    }
}