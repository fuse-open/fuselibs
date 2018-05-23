package com.fuse.views;

import android.content.res.Configuration;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.support.v7.app.AppCompatActivity;

import com.fuse.App;

public class FuseViewsFragment extends Fragment {

    public static App fuseApp;

    public static void init(AppCompatActivity activity, Bundle savedInstanceState) {
        fuseApp = App.Create(activity);
        fuseApp.onCreate(savedInstanceState);
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void onActivityResult (int arg0, int arg1, android.content.Intent arg2) {
        fuseApp.onActivityResult(arg0, arg1, arg2);
    }

    @Override
    public void onDestroy() {
        fuseApp.onDestroyPre();
        super.onDestroy();
        fuseApp.onDestroyPost();
    }

    @Override
    public void onPause() {
        super.onPause();
        fuseApp.onPause();
    }

    @Override
    public void onResume() {
        super.onResume();
        fuseApp.onResume();
    }

    @Override
    public void onStart() {
        super.onStart();
        fuseApp.onStart();
    }

    @Override
    public void onStop() {
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
}
