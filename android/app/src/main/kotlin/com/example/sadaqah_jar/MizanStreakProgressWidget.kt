package com.example.sadaqah_jar

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class MizanStreakProgressWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        internal fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.mizan_streak_progress_widget)
            val data = HomeWidgetPlugin.getData(context)
            val streak = data.getInt("streak_count", 0)
            val progressPct = data.getInt("goal_progress_pct", 0)
            val totalStars = data.getInt("total_stars", 0)
            val remaining = data.getInt("remaining_acts", 0)

            if (streak > 0) {
                views.setViewVisibility(R.id.streak_value, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.progress_bar, android.view.View.GONE)
                views.setViewVisibility(R.id.goal_value, android.view.View.GONE)
                views.setViewVisibility(R.id.progress_label, android.view.View.GONE)
                views.setTextViewText(R.id.streak_value, "$streak")
                views.setTextViewText(R.id.streak_label, "day streak")
            } else {
                views.setViewVisibility(R.id.streak_value, android.view.View.GONE)
                views.setViewVisibility(R.id.progress_bar, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.goal_value, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.progress_label, android.view.View.VISIBLE)
                views.setTextViewText(R.id.goal_value, "$totalStars of ${totalStars + remaining}")
                views.setTextViewText(R.id.streak_label, "Monthly progress")
                views.setTextViewText(R.id.progress_label, "$progressPct%")
                views.setProgressBar(R.id.progress_bar, 100, progressPct, false)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
