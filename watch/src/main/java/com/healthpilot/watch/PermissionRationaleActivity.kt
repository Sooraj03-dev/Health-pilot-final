package com.healthpilot.watch

import android.os.Bundle
import android.widget.LinearLayout
import android.widget.TextView
import android.view.Gravity
import androidx.activity.ComponentActivity

/**
 * Rationale Activity declared in AndroidManifest so the Health Connect app
 * can display a "Why this app needs these permissions" screen.
 *
 * Required entry point:
 *   action: android.intent.action.VIEW_PERMISSION_USAGE
 *   category: android.intent.category.HEALTH_PERMISSIONS
 *
 * See: https://developer.android.com/health-and-fitness/guides/health-connect/develop/get-permissions#show-rationale
 */
class PermissionRationaleActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(32, 32, 32, 32)
        }

        val title = TextView(this).apply {
            text = "Health Permissions"
            textSize = 18f
            gravity = Gravity.CENTER
        }

        val body = TextView(this).apply {
            text = "Health Pilot needs access to your heart rate, SpO₂, and sleep data " +
                    "to provide personalized health insights on your Galaxy Watch. " +
                    "No data is shared outside this device without your consent."
            gravity = Gravity.CENTER
            setPadding(0, 24, 0, 0)
        }

        layout.addView(title)
        layout.addView(body)
        setContentView(layout)
    }
}
