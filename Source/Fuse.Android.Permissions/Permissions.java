package com.fuse;

import android.content.pm.PackageManager;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.content.PermissionChecker;
import java.util.ArrayList;
import com.uno.UnoObject;
import com.fuse.Activity;

class PermissionsRequest
{
    public UnoObject promise;
    public String[] permissions;
    public int requestID;
    public PermissionsRequest(UnoObject inPromise, String[] inPermissions, int inId)
    {
        promise = inPromise;
        permissions = inPermissions;
        requestID = inId;
    }
}

public final class Permissions {

    public static boolean hasPermissions(String[] permissions)
    {
        for(String p : permissions)
        {
            if(!hasPermission(p)) return false;
        }
        return true;
    }

    public static boolean hasPermission(String permission)
    {
        return ContextCompat.checkSelfPermission (Activity.getRootActivity(), permission) == PackageManager.PERMISSION_GRANTED;
    }

    public static boolean shouldShowInformation(String permission)
    {
        return ActivityCompat.shouldShowRequestPermissionRationale(Activity.getRootActivity(), permission);
    }

    // _permissionRequestID is an int that the callback method gets the given
    // with result of the request.
    private static int _permissionRequestID = 0;
    private static ArrayList<PermissionsRequest> _requests = new ArrayList<PermissionsRequest>();
    private static PermissionsRequest _currentRequest = null;

    public static void startPermissionRequest(UnoObject promise, String permission)
    {
        startPermissionRequest(promise, new String[]{permission});
    }

    public static void startPermissionRequest(UnoObject promise, String[] permissions)
    {
        if (hasPermissions(permissions)) {
            com.foreign.ExternedBlockHost.permissionRequestSucceeded(promise);
        }else{
            _requests.add(new PermissionsRequest(promise, permissions, _permissionRequestID++));
            if(_currentRequest == null)
                nextRequest();
        }
    }
    
    private static void nextRequest()
    {
        if( _currentRequest != null || _requests.size() == 0) 
            return;
            
        _currentRequest = _requests.remove(0);
        ActivityCompat.requestPermissions(
            Activity.getRootActivity(),
            _currentRequest.permissions,
            _currentRequest.requestID);
    }

    public static void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) 
    {
        if( _currentRequest == null) 
            return;

        if (_currentRequest.requestID == requestCode && _currentRequest.promise != null && grantResults.length > 0) 
        {
            boolean ok = true;
            for(int result : grantResults)
            {
                if(result != PackageManager.PERMISSION_GRANTED)
                {
                    ok = false;
                    break;
                }
            }
            if (ok) {
                android.util.Log.d("Permissions", "Permissions granted");
                com.foreign.ExternedBlockHost.permissionRequestSucceeded(_currentRequest.promise);
            } else {
                android.util.Log.d("Permissions", "Permissions denied");
                com.foreign.ExternedBlockHost.permissionRequestFailed(_currentRequest.promise);
            }
        }
        _currentRequest = null;
        nextRequest();
    }
}
