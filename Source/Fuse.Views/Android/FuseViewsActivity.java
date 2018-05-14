package com.fuse.views;

import android.content.Intent;
import android.content.res.Configuration;
import android.os.Bundle;
import android.support.design.widget.FloatingActionButton;
import android.support.design.widget.Snackbar;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.KeyEvent;
import android.view.View;
import android.view.Menu;
import android.view.MenuItem;

import com.fuse.App;

public class FuseViewsActivity extends AppCompatActivity {

    private static App fuseApp;

    public FuseViewsActivity()
    {
        super();
        fuseApp = App.Create(this);
        android.app.Activity foo = com.fuse.Activity.getRootActivity();
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        fuseApp.onCreate(savedInstanceState);
    }

    @Override
    protected void onNewIntent (Intent intent)
    {
        fuseApp.onNewIntent(intent);
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event)
    {
        return fuseApp.onKeyUp(keyCode, event);
    }
    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event)
    {
        return fuseApp.onKeyDown(keyCode, event);
    }

    @Override
    public void onActivityResult (int arg0, int arg1, android.content.Intent arg2)
    {
        fuseApp.onActivityResult(arg0, arg1, arg2);
    }

    @Override
    protected void onDestroy() {
        fuseApp.onDestroyPre();
        super.onDestroy();
        fuseApp.onDestroyPost();
    }

    @Override
    protected void onPause() {
        super.onPause();
        fuseApp.onPause();
    }

    @Override
    protected void onResume() {
        super.onResume();
        fuseApp.onResume();
    }

    @Override
    protected void onRestart() {
        super.onRestart();
        fuseApp.onRestart();
    }


    @Override
    protected void onStart() {
        super.onStart();
        fuseApp.onStart();
    }

    @Override
    protected void onStop() {
        super.onStop();
        fuseApp.onStop();
    }

    @Override
    public void onConfigurationChanged(Configuration arg0) {
        super.onConfigurationChanged(arg0);
        fuseApp.onConfigurationChanged(arg0);
    }

    @Override
    public void onLowMemory() {
        super.onLowMemory();
        fuseApp.onLowMemory();
    }

    @Override
    public void onWindowFocusChanged(boolean arg0) {
        super.onWindowFocusChanged(arg0);
        fuseApp.onWindowFocusChanged(arg0);
    }
}