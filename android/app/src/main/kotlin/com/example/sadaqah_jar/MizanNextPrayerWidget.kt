package com.example.sadaqah_jar

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class MizanNextPrayerWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        internal fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.mizan_next_prayer_widget)
            val data = HomeWidgetPlugin.getData(context)
            val prayerName = data.getString("prayer_name", "Asr")
            val countdown = data.getString("prayer_countdown", "45")
            views.setTextViewText(R.id.prayer_name, prayerName)
            views.setTextViewText(R.id.prayer_countdown, "in $countdown min")
            views.setTextViewText(R.id.prayer_inline, "$prayerName in $countdown min")
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
