package com.summie.mizan

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
            val prayerName = data.getString("prayer_name", "Prayer") ?: "Prayer"
            val prompt = data.getString("prayer_countdown", "Prepare with presence") ?: "Prepare with presence"
            val inline = data.getString("prayer_inline", "Next: $prayerName") ?: "Next: $prayerName"
            views.setTextViewText(R.id.prayer_name, prayerName)
            views.setTextViewText(R.id.prayer_countdown, prompt)
            views.setTextViewText(R.id.prayer_inline, inline)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
