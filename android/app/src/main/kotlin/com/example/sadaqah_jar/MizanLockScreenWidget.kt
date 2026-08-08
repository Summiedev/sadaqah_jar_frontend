package com.example.sadaqah_jar

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class MizanLockScreenWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        internal fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.mizan_lock_screen_widget)
            val data = HomeWidgetPlugin.getData(context)
            val text = data.getString("daily_text", "Remember Allah with much remembrance.") ?: "Remember Allah with much remembrance."
            val source = data.getString("daily_source", "Quran 33:41-42") ?: "Quran 33:41-42"
            val shortText = data.getString("daily_short", "Remember Allah often") ?: "Remember Allah often"
            val contextLine = data.getString("daily_context", "A quiet reminder for the day") ?: "A quiet reminder for the day"
            views.setTextViewText(R.id.widget_label, contextLine.uppercase())
            views.setTextViewText(R.id.widget_text, text)
            views.setTextViewText(R.id.widget_source, source)
            views.setTextViewText(R.id.widget_inline_text, shortText)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
