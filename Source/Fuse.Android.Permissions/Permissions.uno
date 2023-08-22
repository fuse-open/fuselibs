using Uno;
using Uno.Collections;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;
using Uno.Compiler.ExportTargetInterop.Android;

namespace Fuse.Android.Permissions
{
    public struct PlatformPermission
    {
        public readonly string Name;

        internal PlatformPermission(string name)
        {
            Name = name;
        }
    }

    interface IPermissionPromise
    {
        void Resolve();
        void Reject(Exception e);
    }

    class PermissionPromise : Promise<PlatformPermission>, IPermissionPromise
    {
        PlatformPermission _permission;
        public PermissionPromise(PlatformPermission p)
        {
            _permission = p;
        }

        public void Resolve()
        {
            Resolve(_permission);
        }
    }

    class PermissionsPromise : Promise<PlatformPermission[]>, IPermissionPromise
    {
        PlatformPermission[] _permissions;
        public PermissionsPromise(PlatformPermission[] permissions)
        {
            _permissions = permissions;
        }

        public void Resolve()
        {
            Resolve(_permissions);
        }
    }

    public static extern(android) class Permissions
    {

        public static bool ShouldShowInformation(PlatformPermission x)
        {
            return shouldShowInformation(x.Name);
        }

        [Foreign(Language.Java)]
        static bool shouldShowInformation(string x)
        @{
            return com.fuse.Permissions.shouldShowInformation(x);
        @}

        public static Future<PlatformPermission> Request(PlatformPermission x)
        {
            var futurePermission = new PermissionPromise(x);
            requestPermission(futurePermission, x.Name);
            return futurePermission;
        }

        public static Future<PlatformPermission[]> Request(PlatformPermission[] x)
        {
            var futurePermission = new PermissionsPromise(x);
            var names = new String[x.Length];
            for(var i = 0; i<x.Length; i++)
            {
                names[i] = x[i].Name;
            }
            requestPermissions(futurePermission, names);
            return futurePermission;
        }

        [Foreign(Language.Java)]
        static void requestPermission(Promise<PlatformPermission> promise, string permissionName)
        @{
            com.fuse.Permissions.startPermissionRequest((UnoObject)promise, permissionName);
        @}

        [Foreign(Language.Java)]
        static void requestPermissions(Promise<PlatformPermission[]> promise, string[] permissionNames)
        @{
            com.fuse.Permissions.startPermissionRequest((UnoObject)promise, permissionNames.copyArray());
        @}

        static void Succeeded(object promise)
        {
            ((IPermissionPromise)promise).Resolve();
        }

        static void Failed(object promise)
        {
            ((IPermissionPromise)promise).Reject(new Exception("Permissions could not be requested or granted."));
        }

        [Foreign(Language.Java), ForeignFixedName]
        static void permissionRequestSucceeded(object x)
        @{
            @{Succeeded(object):Call(x)};
        @}

        [Foreign(Language.Java), ForeignFixedName]
        static void permissionRequestFailed(object x)
        @{
            @{Failed(object):Call(x)};
        @}

        public static extern(android) class Android
        {
            public static PlatformPermission ACCESS_CHECKIN_PROPERTIES { get { return Internal.Android._access_checkin_properties(); } }
            public static PlatformPermission ACCESS_BACKGROUND_LOCATION { get { return Internal.Android._access_background_location(); } }
            public static PlatformPermission ACCESS_COARSE_LOCATION { get { return Internal.Android._access_coarse_location(); } }
            public static PlatformPermission ACCESS_FINE_LOCATION { get { return Internal.Android._access_fine_location(); } }
            public static PlatformPermission ACCESS_LOCATION_EXTRA_COMMANDS { get { return Internal.Android._access_location_extra_commands(); } }
            public static PlatformPermission ACCESS_MOCK_LOCATION { get { return Internal.Android._access_mock_location(); } }
            public static PlatformPermission ACCESS_NETWORK_STATE { get { return Internal.Android._access_network_state(); } }
            public static PlatformPermission ACCESS_SURFACE_FLINGER { get { return Internal.Android._access_surface_flinger(); } }
            public static PlatformPermission ACCESS_WIFI_STATE { get { return Internal.Android._access_wifi_state(); } }
            public static PlatformPermission ACCOUNT_MANAGER { get { return Internal.Android._account_manager(); } }
            public static PlatformPermission ADD_VOICEMAIL { get { return Internal.Android._add_voicemail(); } }
            public static PlatformPermission AUTHENTICATE_ACCOUNTS { get { return Internal.Android._authenticate_accounts(); } }
            public static PlatformPermission BATTERY_STATS { get { return Internal.Android._battery_stats(); } }
            public static PlatformPermission BIND_ACCESSIBILITY_SERVICE { get { return Internal.Android._bind_accessibility_service(); } }
            public static PlatformPermission BIND_APPWIDGET { get { return Internal.Android._bind_appwidget(); } }
            public static PlatformPermission BIND_DEVICE_ADMIN { get { return Internal.Android._bind_device_admin(); } }
            public static PlatformPermission BIND_DREAM_SERVICE { get { return Internal.Android._bind_dream_service(); } }
            public static PlatformPermission BIND_INPUT_METHOD { get { return Internal.Android._bind_input_method(); } }
            public static PlatformPermission BIND_NFC_SERVICE { get { return Internal.Android._bind_nfc_service(); } }
            public static PlatformPermission BIND_NOTIFICATION_LISTENER_SERVICE { get { return Internal.Android._bind_notification_listener_service(); } }
            public static PlatformPermission BIND_PRINT_SERVICE { get { return Internal.Android._bind_print_service(); } }
            public static PlatformPermission BIND_REMOTEVIEWS { get { return Internal.Android._bind_remoteviews(); } }
            public static PlatformPermission BIND_TEXT_SERVICE { get { return Internal.Android._bind_text_service(); } }
            public static PlatformPermission BIND_TV_INPUT { get { return Internal.Android._bind_tv_input(); } }
            public static PlatformPermission BIND_VOICE_INTERACTION { get { return Internal.Android._bind_voice_interaction(); } }
            public static PlatformPermission BIND_VPN_SERVICE { get { return Internal.Android._bind_vpn_service(); } }
            public static PlatformPermission BIND_WALLPAPER { get { return Internal.Android._bind_wallpaper(); } }
            public static PlatformPermission BLUETOOTH { get { return Internal.Android._bluetooth(); } }
            public static PlatformPermission BLUETOOTH_ADMIN { get { return Internal.Android._bluetooth_admin(); } }
            public static PlatformPermission BLUETOOTH_PRIVILEGED { get { return Internal.Android._bluetooth_privileged(); } }
            public static PlatformPermission BODY_SENSORS { get { return Internal.Android._body_sensors(); } }
            public static PlatformPermission BRICK { get { return Internal.Android._brick(); } }
            public static PlatformPermission BROADCAST_PACKAGE_REMOVED { get { return Internal.Android._broadcast_package_removed(); } }
            public static PlatformPermission BROADCAST_SMS { get { return Internal.Android._broadcast_sms(); } }
            public static PlatformPermission BROADCAST_STICKY { get { return Internal.Android._broadcast_sticky(); } }
            public static PlatformPermission BROADCAST_WAP_PUSH { get { return Internal.Android._broadcast_wap_push(); } }
            public static PlatformPermission CALL_PHONE { get { return Internal.Android._call_phone(); } }
            public static PlatformPermission CALL_PRIVILEGED { get { return Internal.Android._call_privileged(); } }
            public static PlatformPermission CAMERA { get { return Internal.Android._camera(); } }
            public static PlatformPermission CAPTURE_AUDIO_OUTPUT { get { return Internal.Android._capture_audio_output(); } }
            public static PlatformPermission CAPTURE_SECURE_VIDEO_OUTPUT { get { return Internal.Android._capture_secure_video_output(); } }
            public static PlatformPermission CAPTURE_VIDEO_OUTPUT { get { return Internal.Android._capture_video_output(); } }
            public static PlatformPermission CHANGE_COMPONENT_ENABLED_STATE { get { return Internal.Android._change_component_enabled_state(); } }
            public static PlatformPermission CHANGE_CONFIGURATION { get { return Internal.Android._change_configuration(); } }
            public static PlatformPermission CHANGE_NETWORK_STATE { get { return Internal.Android._change_network_state(); } }
            public static PlatformPermission CHANGE_WIFI_MULTICAST_STATE { get { return Internal.Android._change_wifi_multicast_state(); } }
            public static PlatformPermission CHANGE_WIFI_STATE { get { return Internal.Android._change_wifi_state(); } }
            public static PlatformPermission CLEAR_APP_CACHE { get { return Internal.Android._clear_app_cache(); } }
            public static PlatformPermission CLEAR_APP_USER_DATA { get { return Internal.Android._clear_app_user_data(); } }
            public static PlatformPermission CONTROL_LOCATION_UPDATES { get { return Internal.Android._control_location_updates(); } }
            public static PlatformPermission DELETE_CACHE_FILES { get { return Internal.Android._delete_cache_files(); } }
            public static PlatformPermission DELETE_PACKAGES { get { return Internal.Android._delete_packages(); } }
            public static PlatformPermission DEVICE_POWER { get { return Internal.Android._device_power(); } }
            public static PlatformPermission DIAGNOSTIC { get { return Internal.Android._diagnostic(); } }
            public static PlatformPermission DISABLE_KEYGUARD { get { return Internal.Android._disable_keyguard(); } }
            public static PlatformPermission DUMP { get { return Internal.Android._dump(); } }
            public static PlatformPermission EXPAND_STATUS_BAR { get { return Internal.Android._expand_status_bar(); } }
            public static PlatformPermission FACTORY_TEST { get { return Internal.Android._factory_test(); } }
            public static PlatformPermission FLASHLIGHT { get { return Internal.Android._flashlight(); } }
            public static PlatformPermission FORCE_BACK { get { return Internal.Android._force_back(); } }
            public static PlatformPermission GET_ACCOUNTS { get { return Internal.Android._get_accounts(); } }
            public static PlatformPermission GET_PACKAGE_SIZE { get { return Internal.Android._get_package_size(); } }
            public static PlatformPermission GET_TASKS { get { return Internal.Android._get_tasks(); } }
            public static PlatformPermission GET_TOP_ACTIVITY_INFO { get { return Internal.Android._get_top_activity_info(); } }
            public static PlatformPermission GLOBAL_SEARCH { get { return Internal.Android._global_search(); } }
            public static PlatformPermission HARDWARE_TEST { get { return Internal.Android._hardware_test(); } }
            public static PlatformPermission INJECT_EVENTS { get { return Internal.Android._inject_events(); } }
            public static PlatformPermission INSTALL_LOCATION_PROVIDER { get { return Internal.Android._install_location_provider(); } }
            public static PlatformPermission INSTALL_PACKAGES { get { return Internal.Android._install_packages(); } }
            public static PlatformPermission INSTALL_SHORTCUT { get { return Internal.Android._install_shortcut(); } }
            public static PlatformPermission INTERNAL_SYSTEM_WINDOW { get { return Internal.Android._internal_system_window(); } }
            public static PlatformPermission INTERNET { get { return Internal.Android._internet(); } }
            public static PlatformPermission KILL_BACKGROUND_PROCESSES { get { return Internal.Android._kill_background_processes(); } }
            public static PlatformPermission LOCATION_HARDWARE { get { return Internal.Android._location_hardware(); } }
            public static PlatformPermission MANAGE_ACCOUNTS { get { return Internal.Android._manage_accounts(); } }
            public static PlatformPermission MANAGE_APP_TOKENS { get { return Internal.Android._manage_app_tokens(); } }
            public static PlatformPermission MANAGE_DOCUMENTS { get { return Internal.Android._manage_documents(); } }
            public static PlatformPermission MASTER_CLEAR { get { return Internal.Android._master_clear(); } }
            public static PlatformPermission MEDIA_CONTENT_CONTROL { get { return Internal.Android._media_content_control(); } }
            public static PlatformPermission MODIFY_AUDIO_SETTINGS { get { return Internal.Android._modify_audio_settings(); } }
            public static PlatformPermission MODIFY_PHONE_STATE { get { return Internal.Android._modify_phone_state(); } }
            public static PlatformPermission MOUNT_FORMAT_FILESYSTEMS { get { return Internal.Android._mount_format_filesystems(); } }
            public static PlatformPermission MOUNT_UNMOUNT_FILESYSTEMS { get { return Internal.Android._mount_unmount_filesystems(); } }
            public static PlatformPermission NFC { get { return Internal.Android._nfc(); } }
            public static PlatformPermission PERSISTENT_ACTIVITY { get { return Internal.Android._persistent_activity(); } }
            public static PlatformPermission PROCESS_OUTGOING_CALLS { get { return Internal.Android._process_outgoing_calls(); } }
            public static PlatformPermission READ_CALENDAR { get { return Internal.Android._read_calendar(); } }
            public static PlatformPermission READ_CALL_LOG { get { return Internal.Android._read_call_log(); } }
            public static PlatformPermission READ_CONTACTS { get { return Internal.Android._read_contacts(); } }
            public static PlatformPermission READ_EXTERNAL_STORAGE { get { return Internal.Android._read_media_images(); } }
            public static PlatformPermission READ_MEDIA_IMAGES { get { return 
            Internal.Android._read_media_audio(); } }
            public static PlatformPermission READ_MEDIA_AUDIO { get { return 
            Internal.Android._read_media_video(); } }
            public static PlatformPermission READ_MEDIA_VIDEO { get { return 
            Internal.Android._read_external_storage(); } }
            public static PlatformPermission READ_FRAME_BUFFER { get { return Internal.Android._read_frame_buffer(); } }
            public static PlatformPermission READ_HISTORY_BOOKMARKS { get { return Internal.Android._read_history_bookmarks(); } }
            public static PlatformPermission READ_INPUT_STATE { get { return Internal.Android._read_input_state(); } }
            public static PlatformPermission READ_LOGS { get { return Internal.Android._read_logs(); } }
            public static PlatformPermission READ_PHONE_STATE { get { return Internal.Android._read_phone_state(); } }
            public static PlatformPermission READ_PROFILE { get { return Internal.Android._read_profile(); } }
            public static PlatformPermission READ_SMS { get { return Internal.Android._read_sms(); } }
            public static PlatformPermission READ_SOCIAL_STREAM { get { return Internal.Android._read_social_stream(); } }
            public static PlatformPermission READ_SYNC_SETTINGS { get { return Internal.Android._read_sync_settings(); } }
            public static PlatformPermission READ_SYNC_STATS { get { return Internal.Android._read_sync_stats(); } }
            public static PlatformPermission READ_USER_DICTIONARY { get { return Internal.Android._read_user_dictionary(); } }
            public static PlatformPermission READ_VOICEMAIL { get { return Internal.Android._read_voicemail(); } }
            public static PlatformPermission REBOOT { get { return Internal.Android._reboot(); } }
            public static PlatformPermission RECEIVE_BOOT_COMPLETED { get { return Internal.Android._receive_boot_completed(); } }
            public static PlatformPermission RECEIVE_MMS { get { return Internal.Android._receive_mms(); } }
            public static PlatformPermission RECEIVE_SMS { get { return Internal.Android._receive_sms(); } }
            public static PlatformPermission RECEIVE_WAP_PUSH { get { return Internal.Android._receive_wap_push(); } }
            public static PlatformPermission RECORD_AUDIO { get { return Internal.Android._record_audio(); } }
            public static PlatformPermission REORDER_TASKS { get { return Internal.Android._reorder_tasks(); } }
            public static PlatformPermission RESTART_PACKAGES { get { return Internal.Android._restart_packages(); } }
            public static PlatformPermission SEND_RESPOND_VIA_MESSAGE { get { return Internal.Android._send_respond_via_message(); } }
            public static PlatformPermission SEND_SMS { get { return Internal.Android._send_sms(); } }
            public static PlatformPermission SET_ACTIVITY_WATCHER { get { return Internal.Android._set_activity_watcher(); } }
            public static PlatformPermission SET_ALARM { get { return Internal.Android._set_alarm(); } }
            public static PlatformPermission SET_ALWAYS_FINISH { get { return Internal.Android._set_always_finish(); } }
            public static PlatformPermission SET_ANIMATION_SCALE { get { return Internal.Android._set_animation_scale(); } }
            public static PlatformPermission SET_DEBUG_APP { get { return Internal.Android._set_debug_app(); } }
            public static PlatformPermission SET_ORIENTATION { get { return Internal.Android._set_orientation(); } }
            public static PlatformPermission SET_POINTER_SPEED { get { return Internal.Android._set_pointer_speed(); } }
            public static PlatformPermission SET_PREFERRED_APPLICATIONS { get { return Internal.Android._set_preferred_applications(); } }
            public static PlatformPermission SET_PROCESS_LIMIT { get { return Internal.Android._set_process_limit(); } }
            public static PlatformPermission SET_TIME { get { return Internal.Android._set_time(); } }
            public static PlatformPermission SET_TIME_ZONE { get { return Internal.Android._set_time_zone(); } }
            public static PlatformPermission SET_WALLPAPER { get { return Internal.Android._set_wallpaper(); } }
            public static PlatformPermission SET_WALLPAPER_HINTS { get { return Internal.Android._set_wallpaper_hints(); } }
            public static PlatformPermission SIGNAL_PERSISTENT_PROCESSES { get { return Internal.Android._signal_persistent_processes(); } }
            public static PlatformPermission STATUS_BAR { get { return Internal.Android._status_bar(); } }
            public static PlatformPermission SUBSCRIBED_FEEDS_READ { get { return Internal.Android._subscribed_feeds_read(); } }
            public static PlatformPermission SUBSCRIBED_FEEDS_WRITE { get { return Internal.Android._subscribed_feeds_write(); } }
            public static PlatformPermission SYSTEM_ALERT_WINDOW { get { return Internal.Android._system_alert_window(); } }
            public static PlatformPermission TRANSMIT_IR { get { return Internal.Android._transmit_ir(); } }
            public static PlatformPermission UNINSTALL_SHORTCUT { get { return Internal.Android._uninstall_shortcut(); } }
            public static PlatformPermission UPDATE_DEVICE_STATS { get { return Internal.Android._update_device_stats(); } }
            public static PlatformPermission USE_CREDENTIALS { get { return Internal.Android._use_credentials(); } }
            public static PlatformPermission USE_SIP { get { return Internal.Android._use_sip(); } }
            public static PlatformPermission VIBRATE { get { return Internal.Android._vibrate(); } }
            public static PlatformPermission WAKE_LOCK { get { return Internal.Android._wake_lock(); } }
            public static PlatformPermission WRITE_APN_SETTINGS { get { return Internal.Android._write_apn_settings(); } }
            public static PlatformPermission WRITE_CALENDAR { get { return Internal.Android._write_calendar(); } }
            public static PlatformPermission WRITE_CALL_LOG { get { return Internal.Android._write_call_log(); } }
            public static PlatformPermission WRITE_CONTACTS { get { return Internal.Android._write_contacts(); } }
            public static PlatformPermission WRITE_EXTERNAL_STORAGE { get { return Internal.Android._write_external_storage(); } }
            public static PlatformPermission WRITE_GSERVICES { get { return Internal.Android._write_gservices(); } }
            public static PlatformPermission WRITE_HISTORY_BOOKMARKS { get { return Internal.Android._write_history_bookmarks(); } }
            public static PlatformPermission WRITE_PROFILE { get { return Internal.Android._write_profile(); } }
            public static PlatformPermission WRITE_SECURE_SETTINGS { get { return Internal.Android._write_secure_settings(); } }
            public static PlatformPermission WRITE_SETTINGS { get { return Internal.Android._write_settings(); } }
            public static PlatformPermission WRITE_SMS { get { return Internal.Android._write_sms(); } }
            public static PlatformPermission WRITE_SOCIAL_STREAM { get { return Internal.Android._write_social_stream(); } }
            public static PlatformPermission WRITE_SYNC_SETTINGS { get { return Internal.Android._write_sync_settings(); } }
            public static PlatformPermission WRITE_USER_DICTIONARY { get { return Internal.Android._write_user_dictionary(); } }
            public static PlatformPermission WRITE_VOICEMAIL { get { return Internal.Android._write_voicemail(); } }
            public static PlatformPermission POST_NOTIFICATIONS { get { return Internal.Android._post_notification(); } }
        }
    }

    public static extern(!android) class Permissions
    {
        public static bool ShouldShowInformation(PlatformPermission x)
        {
            return false;
        }

        public static Future<PlatformPermission> Request(PlatformPermission x)
        {
            var futurePermission = new PermissionPromise(x);
            futurePermission.Reject(new Exception("Permissions not required on current platform"));
            return futurePermission;
        }

        public static Future<PlatformPermission[]> Request(PlatformPermission[] x)
        {
            var futurePermission = new PermissionsPromise(x);
            futurePermission.Reject(new Exception("Permissions not required on current platform"));
            return futurePermission;
        }
    }
}
