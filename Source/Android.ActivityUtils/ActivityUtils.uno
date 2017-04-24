using Uno;
using Uno.Graphics;
using Uno.Platform;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Android
{
    public extern(android) delegate void ActivityResultCallback(int resultCode, Java.Object intent, object info);
    public extern(!android) delegate void ActivityResultCallback(int resultCode, object intent, object info);

    [ForeignInclude(Language.Java, "android.app.Activity", "android.content.Intent")]
    public static extern(android) class ActivityUtils
    {
        static int _requestID = 0;
        static Java.Object _intentListener;
        static Dictionary<int, ActivityResultCallback> _pendingResults;
        static Dictionary<int, object> _pendingInfos;
        public static event Action<int, int, Java.Object> Results;

        static ActivityUtils()
        {
            if (_intentListener == null)
            {
                _pendingResults = new Dictionary<int, ActivityResultCallback>();
                _pendingInfos = new Dictionary<int, object>();
                _intentListener = Init();
            }
        }

        [Foreign(Language.Java)]
        static Java.Object Init()
        @{
            com.fuse.Activity.ResultListener l = new com.fuse.Activity.ResultListener() {
                @Override public boolean onResult(int requestCode, int resultCode, android.content.Intent data) {
                    return @{OnReceived(int,int,Java.Object):Call(requestCode, resultCode, data)};
                }
            };
            com.fuse.Activity.subscribeToResults(l);
            return l;
        @}

        [Foreign(Language.Java)]
        public static Java.Object GetRootActivity()
        @{
            return com.fuse.Activity.getRootActivity();
        @}

        [Foreign(Language.Java)]
        public static void StartActivity(Java.Object _intent)
        @{
            Activity a = com.fuse.Activity.getRootActivity();
            a.startActivity((Intent)_intent);
        @}

        public static void StartActivity(Java.Object intent, ActivityResultCallback callback)
        {
            StartActivity(intent, callback, null);
        }

        public static void StartActivity(Java.Object intent, ActivityResultCallback callback, object info)
        {
            _requestID += 1; // note that unless >0 the requestID is not returned
            _pendingResults[_requestID] = callback;
            _pendingInfos[_requestID] = info;
            StartForResultJava(_requestID, intent);
        }

        [Foreign(Language.Java)]
        static void StartForResultJava(int id, Java.Object _intent)
        @{
            Activity a = com.fuse.Activity.getRootActivity();
            a.startActivityForResult((Intent)_intent, id);
        @}

        static bool OnReceived(int requestCode, int resultCode, Java.Object data)
        {
            // fire for people expecting results
            if (_pendingResults.ContainsKey(requestCode))
            {
                var callback = _pendingResults[requestCode];
                _pendingResults.Remove(requestCode);
                var info = _pendingInfos[requestCode];
                _pendingInfos.Remove(requestCode);
                callback(resultCode, data, info);
            }

            // fire for people listening to every result
            var handler = Results;
            if (handler != null)
                handler(requestCode, resultCode, data);

            return false;
        }
    }

    public static extern(!android) class ActivityUtils
    {
        public static object GetRootActivity()
        {
            debug_log "Android ActivityUtils is an android only api and as such cannot be used from this backend";
            return null;
        }

        public static void StartActivity(object intent)
        {
            debug_log "Android ActivityUtils is an android only api and as such cannot be used from this backend";
        }

        public static void StartActivity(object intent, ActivityResultCallback callback, object info=null)
        {
            debug_log "Android ActivityUtils is an android only api and as such cannot be used from this backend";
        }
    }
}
