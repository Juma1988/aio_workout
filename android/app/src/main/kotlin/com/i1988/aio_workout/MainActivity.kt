package com.i1988.aio_workout

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity(), SensorEventListener, EventChannel.StreamHandler {
    private val METHOD_CHANNEL = "com.aio_workout/step_counter"
    private val EVENT_CHANNEL = "com.aio_workout/step_events"

    private var sensorManager: SensorManager? = null
    private var stepSensor: Sensor? = null
    private var eventSink: EventChannel.EventSink? = null
    private val isListening = AtomicBoolean(false)
    private var baselineSteps = -1
    private var wakeLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        stepSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> {
                    result.success(stepSensor != null)
                }
                "requestPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val perm = android.Manifest.permission.ACTIVITY_RECOGNITION
                        if (checkSelfPermission(perm) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                            requestPermissions(arrayOf(perm), 1001)
                            result.success(false)
                        } else {
                            result.success(true)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "startListening" -> {
                    startStepListening()
                    result.success(true)
                }
                "stopListening" -> {
                    stopStepListening()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(this)
    }

    private fun startStepListening() {
        if (isListening.getAndSet(true)) return
        stepSensor?.let { sensor ->
            sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL)
            acquireWakeLock()
        }
    }

    private fun stopStepListening() {
        if (!isListening.getAndSet(false)) return
        sensorManager?.unregisterListener(this)
        releaseWakeLock()
    }

    private fun acquireWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            wakeLock = powerManager?.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "aio_workout::StepCounterLock"
            )?.apply {
                acquire(10 * 60 * 1000L)
            }
        } catch (_: Exception) {}
    }

    private fun releaseWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) it.release()
            }
            wakeLock = null
        } catch (_: Exception) {}
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_STEP_COUNTER) {
            val totalSteps = event.values[0].toInt()
            if (baselineSteps < 0) {
                baselineSteps = totalSteps
                val data = HashMap<String, Any>()
                data["steps"] = totalSteps
                data["isBaseline"] = true
                eventSink?.success(data)
            } else {
                val data = HashMap<String, Any>()
                data["steps"] = totalSteps
                data["isBaseline"] = false
                eventSink?.success(data)
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onDestroy() {
        stopStepListening()
        releaseWakeLock()
        super.onDestroy()
    }
}
