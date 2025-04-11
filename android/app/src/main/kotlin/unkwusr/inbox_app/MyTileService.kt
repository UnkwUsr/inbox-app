package unkwusr.inbox_app

import android.service.quicksettings.TileService
import android.service.quicksettings.Tile
import android.content.Intent
import android.app.PendingIntent
import android.util.Log
import android.os.Build

class MyTileService : TileService() {
    override fun onClick() {
        super.onClick()
            try{
                val newIntent = MainActivity.withNewEngine().dartEntrypointArgs(listOf("launchFromQuickTile")).build(this)

                newIntent.flags= Intent.FLAG_ACTIVITY_NEW_TASK
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    startActivityAndCollapse(
                        PendingIntent.getActivity(this, 0, newIntent, PendingIntent.FLAG_IMMUTABLE)
                    )
                } else {
                    startActivityAndCollapse(newIntent)
                }

            }
        catch (e:Exception){
            Log.d("debug","Exception ${e.toString()}")
        }
    }
}
