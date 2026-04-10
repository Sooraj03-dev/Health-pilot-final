package com.healthpilot.watch

import android.content.Context
import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.OxygenSaturationRecord
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.temporal.ChronoUnit

/**
 * Reads health vitals (heart rate, SpO₂, sleep) from Health Connect.
 *
 * All reads are guarded: if the [healthConnectClient] is null (Health Connect
 * unavailable on the device) the individual callbacks simply won't fire for
 * that data type and no crash occurs.
 *
 * Permissions must be granted **before** calling [fetchAll]. The calling
 * Activity (MainActivity) enforces this via [MainActivity.readVitalsGuarded].
 */
class VitalsManager(
    private val context: Context,
    private val healthConnectClient: HealthConnectClient?,
) {

    companion object {
        private const val TAG = "HealthPilot/VitalsMgr"
        /** Look-back window for each query (last 24 hours). */
        private const val LOOKBACK_HOURS = 24L
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    /**
     * Kicks off concurrent reads for all three vitals types.
     *
     * @param onHeartRate called with the latest average BPM, or skipped if unavailable.
     * @param onSpO2      called with the latest SpO₂ percentage, or skipped.
     * @param onSleep     called with total sleep hours in the last 24h, or skipped.
     * @param onError     called for each individual error; does NOT abort other reads.
     */
    fun fetchAll(
        onHeartRate: (Int) -> Unit,
        onSpO2: (Float) -> Unit,
        onSleep: (Float) -> Unit,
        onError: (Throwable) -> Unit,
    ) {
        val client = healthConnectClient
        if (client == null) {
            Log.w(TAG, "Health Connect unavailable – skipping vitals fetch")
            return
        }

        val end = Instant.now()
        val start = end.minus(LOOKBACK_HOURS, ChronoUnit.HOURS)
        val timeRange = TimeRangeFilter.between(start, end)

        scope.launch { readHeartRate(client, timeRange, onHeartRate, onError) }
        scope.launch { readSpO2(client, timeRange, onSpO2, onError) }
        scope.launch { readSleep(client, timeRange, onSleep, onError) }
    }

    // ── Individual read functions ─────────────────────────────────────────────

    private suspend fun readHeartRate(
        client: HealthConnectClient,
        timeRange: TimeRangeFilter,
        onResult: (Int) -> Unit,
        onError: (Throwable) -> Unit,
    ) {
        try {
            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = HeartRateRecord::class,
                    timeRangeFilter = timeRange,
                )
            )
            val samples = response.records.flatMap { it.samples }
            if (samples.isNotEmpty()) {
                val avgBpm = samples.map { it.beatsPerMinute }.average().toInt()
                Log.d(TAG, "Heart rate avg (last ${LOOKBACK_HOURS}h): $avgBpm bpm")
                onResult(avgBpm)
            } else {
                Log.d(TAG, "No heart-rate records found in window")
            }
        } catch (e: Exception) {
            Log.e(TAG, "readHeartRate failed", e)
            onError(e)
        }
    }

    private suspend fun readSpO2(
        client: HealthConnectClient,
        timeRange: TimeRangeFilter,
        onResult: (Float) -> Unit,
        onError: (Throwable) -> Unit,
    ) {
        try {
            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = OxygenSaturationRecord::class,
                    timeRangeFilter = timeRange,
                )
            )
            val records = response.records
            if (records.isNotEmpty()) {
                // Use the most-recent reading
                val latest = records.last().percentage.value.toFloat()
                Log.d(TAG, "Latest SpO₂: $latest %")
                onResult(latest)
            } else {
                Log.d(TAG, "No SpO₂ records found in window")
            }
        } catch (e: Exception) {
            Log.e(TAG, "readSpO2 failed", e)
            onError(e)
        }
    }

    private suspend fun readSleep(
        client: HealthConnectClient,
        timeRange: TimeRangeFilter,
        onResult: (Float) -> Unit,
        onError: (Throwable) -> Unit,
    ) {
        try {
            val response = client.readRecords(
                ReadRecordsRequest(
                    recordType = SleepSessionRecord::class,
                    timeRangeFilter = timeRange,
                )
            )
            if (response.records.isNotEmpty()) {
                val totalMillis = response.records.sumOf { session ->
                    session.endTime.toEpochMilli() - session.startTime.toEpochMilli()
                }
                val hours = totalMillis / 3_600_000f
                Log.d(TAG, "Total sleep last ${LOOKBACK_HOURS}h: $hours h")
                onResult(hours)
            } else {
                Log.d(TAG, "No sleep records found in window")
            }
        } catch (e: Exception) {
            Log.e(TAG, "readSleep failed", e)
            onError(e)
        }
    }
}
