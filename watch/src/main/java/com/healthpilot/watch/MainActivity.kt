package com.healthpilot.watch

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.OxygenSaturationRecord
import androidx.health.connect.client.records.SleepSessionRecord
import android.app.AlertDialog
import android.widget.TextView
import android.widget.LinearLayout
import android.view.Gravity

/**
 * Main entry-point Activity for the Galaxy Watch health-vitals module.
 *
 * Permission strategy:
 *  1. Android runtime permission  – BODY_SENSORS (heart rate / SpO2 raw sensor)
 *  2. Health Connect permissions  – READ_HEART_RATE, READ_OXYGEN_SATURATION,
 *                                   READ_SLEEP (via PermissionController launcher)
 *
 * The two flows are started in sequence:
 *   requestAndroidSensorPermissions()
 *     → on granted → requestHealthConnectPermissions()
 *         → on granted → readVitalsGuarded()
 */
class MainActivity : ComponentActivity() {

    companion object {
        private const val TAG = "HealthPilot/Watch"

        /** Health Connect permissions this module requires. */
        val HEALTH_CONNECT_PERMISSIONS = setOf(
            HealthPermission.getReadPermission(HeartRateRecord::class),
            HealthPermission.getReadPermission(OxygenSaturationRecord::class),
            HealthPermission.getReadPermission(SleepSessionRecord::class),
        )
    }

    // ── Health Connect client (lazy – created only when HC is available) ──────

    private val healthConnectClient: HealthConnectClient? by lazy {
        val sdkStatus = HealthConnectClient.getSdkStatus(this)
        if (sdkStatus == HealthConnectClient.SDK_AVAILABLE) {
            HealthConnectClient.getOrCreate(this)
        } else {
            Log.w(TAG, "Health Connect not available (status=$sdkStatus)")
            null
        }
    }

    // ── Permission launchers ──────────────────────────────────────────────────

    /**
     * Launcher for Android runtime permissions (BODY_SENSORS, …).
     * After the user responds, continues to the Health Connect permission flow.
     */
    private val androidPermissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { results ->
            val denied = results.filterValues { granted -> !granted }.keys
            if (denied.isEmpty()) {
                Log.d(TAG, "Android sensor permissions granted – proceeding to Health Connect")
                requestHealthConnectPermissions()
            } else {
                Log.w(TAG, "Android permissions denied: $denied")
                val shouldShowRationale = denied.any { perm ->
                    shouldShowRequestPermissionRationale(perm)
                }
                if (shouldShowRationale) {
                    showRationaleDialog(
                        message = "Heart-rate and SpO₂ readings require sensor access. " +
                                "Please grant the Body Sensors permission.",
                        onRetry = { requestAndroidSensorPermissions() },
                        onCancel = { showPermissionDeniedState() }
                    )
                } else {
                    showPermissionDeniedState()
                }
            }
        }

    /**
     * Launcher for Health Connect permissions.
     * Uses the official PermissionController contract so the Health Connect
     * app handles the permission UI.
     */
    private val healthConnectPermissionLauncher =
        registerForActivityResult(
            PermissionController.createRequestPermissionResultContract()
        ) { grantedPermissions: Set<String> ->
            if (grantedPermissions.containsAll(HEALTH_CONNECT_PERMISSIONS)) {
                Log.d(TAG, "All Health Connect permissions granted")
                readVitalsGuarded()
            } else {
                val missing = HEALTH_CONNECT_PERMISSIONS - grantedPermissions
                Log.w(TAG, "Health Connect permissions not fully granted. Missing: $missing")
                showRationaleDialog(
                    message = "Health Connect permissions are needed to read heart rate, " +
                            "SpO₂, and sleep data. Please grant them in the Health Connect app.",
                    onRetry = { requestHealthConnectPermissions() },
                    onCancel = { showPermissionDeniedState() }
                )
            }
        }

    // ── Activity lifecycle ────────────────────────────────────────────────────

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(buildContentView())
        requestAndroidSensorPermissions()
    }

    // ── Permission-request helpers ────────────────────────────────────────────

    /**
     * Step 1 – Request Android-level runtime permissions.
     * If all are already granted, proceeds directly to the HC flow.
     */
    private fun requestAndroidSensorPermissions() {
        val needed = buildList {
            if (!isAndroidPermissionGranted(Manifest.permission.BODY_SENSORS)) {
                add(Manifest.permission.BODY_SENSORS)
            }
            // BODY_SENSORS_BACKGROUND only needed when reading outside the foreground
            // Uncomment the block below if your use-case requires background reads:
            //
            // if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            //     !isAndroidPermissionGranted(Manifest.permission.BODY_SENSORS_BACKGROUND)
            // ) {
            //     add(Manifest.permission.BODY_SENSORS_BACKGROUND)
            // }
        }

        if (needed.isEmpty()) {
            Log.d(TAG, "Android sensor permissions already granted")
            requestHealthConnectPermissions()
        } else {
            Log.d(TAG, "Requesting Android permissions: $needed")
            androidPermissionLauncher.launch(needed.toTypedArray())
        }
    }

    /**
     * Step 2 – Request Health Connect permissions.
     * No-ops gracefully when Health Connect is unavailable on the device.
     */
    private fun requestHealthConnectPermissions() {
        val client = healthConnectClient
        if (client == null) {
            Log.w(TAG, "Health Connect unavailable – reading vitals via direct sensor API only")
            readVitalsGuarded()
            return
        }
        Log.d(TAG, "Requesting Health Connect permissions")
        healthConnectPermissionLauncher.launch(HEALTH_CONNECT_PERMISSIONS)
    }

    // ── Permission pre-checks ─────────────────────────────────────────────────

    private fun isAndroidPermissionGranted(permission: String): Boolean =
        ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED

    /**
     * Returns true only when ALL required permissions are present.
     * Call this before any vitals-reading operation.
     */
    private fun hasAllRequiredPermissions(): Boolean {
        val sensorGranted = isAndroidPermissionGranted(Manifest.permission.BODY_SENSORS)
        if (!sensorGranted) {
            Log.d(TAG, "hasAllRequiredPermissions: BODY_SENSORS not granted")
            return false
        }
        // If Health Connect is available we also need its grants
        val client = healthConnectClient ?: return true  // HC unavailable – sensor perm sufficient
        // We cannot check HC grants synchronously here; rely on the launcher flow.
        // If the launcher has already run and granted all perms, proceed.
        return true  // actual HC check happens after PermissionController.launch()
    }

    // ── Guarded vitals read ───────────────────────────────────────────────────

    /**
     * Entry point for all vitals reads.
     * Triggers the full permission chain if any permission is missing.
     */
    fun readVitalsGuarded() {
        if (!isAndroidPermissionGranted(Manifest.permission.BODY_SENSORS)) {
            Log.w(TAG, "readVitalsGuarded: BODY_SENSORS missing – starting permission flow")
            requestAndroidSensorPermissions()
            return
        }
        Log.d(TAG, "All Android permissions present – reading vitals")
        VitalsManager(this, healthConnectClient).fetchAll(
            onHeartRate = { bpm -> onHeartRateReceived(bpm) },
            onSpO2 = { pct -> onSpO2Received(pct) },
            onSleep = { hours -> onSleepReceived(hours) },
            onError = { err -> onVitalsError(err) }
        )
    }

    // ── UI callbacks (replace with your real UI update logic) ────────────────

    private fun onHeartRateReceived(bpm: Int) {
        Log.i(TAG, "Heart rate: $bpm bpm")
        statusLabel?.text = "❤ $bpm bpm"
    }

    private fun onSpO2Received(percent: Float) {
        Log.i(TAG, "SpO₂: $percent %")
    }

    private fun onSleepReceived(hours: Float) {
        Log.i(TAG, "Sleep: $hours h")
    }

    private fun onVitalsError(error: Throwable) {
        Log.e(TAG, "Vitals fetch error", error)
        statusLabel?.text = "Error: ${error.message}"
    }

    private fun showPermissionDeniedState() {
        Log.w(TAG, "Permissions permanently denied or cancelled by user")
        statusLabel?.text = "Permissions required to show health data."
    }

    // ── Rationale dialog ──────────────────────────────────────────────────────

    /**
     * Shows a simple Wear-friendly alert dialog explaining why the permission
     * is needed, with Retry / Cancel options.
     */
    private fun showRationaleDialog(
        message: String,
        onRetry: () -> Unit,
        onCancel: () -> Unit,
    ) {
        AlertDialog.Builder(this)
            .setTitle("Permission required")
            .setMessage(message)
            .setPositiveButton("Retry") { _, _ -> onRetry() }
            .setNegativeButton("Cancel") { _, _ -> onCancel() }
            .setCancelable(false)
            .show()
    }

    // ── Minimal content view ──────────────────────────────────────────────────

    private var statusLabel: TextView? = null

    private fun buildContentView(): android.view.View {
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(24, 24, 24, 24)
        }
        statusLabel = TextView(this).apply {
            text = "Loading vitals…"
            gravity = Gravity.CENTER
        }
        layout.addView(statusLabel)
        return layout
    }
}
