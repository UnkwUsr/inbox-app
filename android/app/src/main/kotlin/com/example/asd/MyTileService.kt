package com.example.asd

import android.service.quicksettings.TileService
import android.service.quicksettings.Tile
import android.content.Intent
import android.util.Log

class MyTileService : TileService() {
    override fun onClick() {
        super.onClick()
            try{
                val newIntent = MainActivity.withNewEngine().dartEntrypointArgs(listOf("launchFromQuickTile")).build(this)

                newIntent.flags= Intent.FLAG_ACTIVITY_NEW_TASK
                startActivityAndCollapse(newIntent)
            }
        catch (e:Exception){
            Log.d("debug","Exception ${e.toString()}")
        }
    }
}
