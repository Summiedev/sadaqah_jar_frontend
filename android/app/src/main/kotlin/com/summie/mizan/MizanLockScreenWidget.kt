package com.summie.mizan

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider

class MizanLockScreenWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    companion object {
        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            widgetData: SharedPreferences,
        ) {
            val views = RemoteViews(context.packageName, R.layout.mizan_lock_screen_widget)
            val text = widgetData.getString("daily_text", "Remember Allah with much remembrance.") ?: "Remember Allah with much remembrance."
            val source = widgetData.getString("daily_source", "Quran 33:41-42") ?: "Quran 33:41-42"
            val shortText = widgetData.getString("daily_short", "Remember Allah often") ?: "Remember Allah often"
            val contextLine = widgetData.getString("daily_context", "A quiet reminder for the day") ?: "A quiet reminder for the day"
            views.setTextViewText(R.id.widget_label, contextLine.uppercase())
            views.setTextViewText(R.id.widget_text, text)
            views.setTextViewText(R.id.widget_source, source)
            views.setTextViewText(R.id.widget_inline_text, shortText)
            val refreshIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("mizan://refresh_rhythm"),
            )
            views.setOnClickPendingIntent(R.id.widget_refresh, refreshIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
