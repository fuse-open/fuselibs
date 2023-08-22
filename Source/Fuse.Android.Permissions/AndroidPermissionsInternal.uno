using Uno;
using Uno.Collections;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;
using Uno.Compiler.ExportTargetInterop.Android;

namespace Fuse.Android.Permissions.Internal
{
    [TargetSpecificImplementation]
    internal extern(android) class Android
    {
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _access_checkin_properties()
        {
            return new PlatformPermission("android.permission.ACCESS_CHECKIN_PROPERTIES");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _access_background_location()
        {
            return new PlatformPermission("android.permission.ACCESS_BACKGROUND_LOCATION");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _access_coarse_location()
        {
            return new PlatformPermission("android.permission.ACCESS_COARSE_LOCATION");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _access_fine_location()
        {
            return new PlatformPermission("android.permission.ACCESS_FINE_LOCATION");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _access_location_extra_commands()
        {
            return new PlatformPermission("android.permission.ACCESS_LOCATION_EXTRA_COMMANDS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _access_mock_location()
        {
            return new PlatformPermission("android.permission.ACCESS_MOCK_LOCATION");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _access_network_state()
        {
            return new PlatformPermission("android.permission.ACCESS_NETWORK_STATE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _access_surface_flinger()
        {
            return new PlatformPermission("android.permission.ACCESS_SURFACE_FLINGER");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _access_wifi_state()
        {
            return new PlatformPermission("android.permission.ACCESS_WIFI_STATE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _account_manager()
        {
            return new PlatformPermission("android.permission.ACCOUNT_MANAGER");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _add_voicemail()
        {
            return new PlatformPermission("android.permission.ADD_VOICEMAIL");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _authenticate_accounts()
        {
            return new PlatformPermission("android.permission.AUTHENTICATE_ACCOUNTS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _battery_stats()
        {
            return new PlatformPermission("android.permission.BATTERY_STATS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _bind_accessibility_service()
        {
            return new PlatformPermission("android.permission.BIND_ACCESSIBILITY_SERVICE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _bind_appwidget()
        {
            return new PlatformPermission("android.permission.BIND_APPWIDGET");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _bind_device_admin()
        {
            return new PlatformPermission("android.permission.BIND_DEVICE_ADMIN");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _bind_dream_service()
        {
            return new PlatformPermission("android.permission.BIND_DREAM_SERVICE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _bind_input_method()
        {
            return new PlatformPermission("android.permission.BIND_INPUT_METHOD");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _bind_nfc_service()
        {
            return new PlatformPermission("android.permission.BIND_NFC_SERVICE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _bind_notification_listener_service()
        {
            return new PlatformPermission("android.permission.BIND_NOTIFICATION_LISTENER_SERVICE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _bind_print_service()
        {
            return new PlatformPermission("android.permission.BIND_PRINT_SERVICE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _bind_remoteviews()
        {
            return new PlatformPermission("android.permission.BIND_REMOTEVIEWS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _bind_text_service()
        {
            return new PlatformPermission("android.permission.BIND_TEXT_SERVICE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _bind_tv_input()
        {
            return new PlatformPermission("android.permission.BIND_TV_INPUT");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _bind_voice_interaction()
        {
            return new PlatformPermission("android.permission.BIND_VOICE_INTERACTION");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _bind_vpn_service()
        {
            return new PlatformPermission("android.permission.BIND_VPN_SERVICE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _bind_wallpaper()
        {
            return new PlatformPermission("android.permission.BIND_WALLPAPER");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _bluetooth()
        {
            return new PlatformPermission("android.permission.BLUETOOTH");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _bluetooth_admin()
        {
            return new PlatformPermission("android.permission.BLUETOOTH_ADMIN");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _bluetooth_privileged()
        {
            return new PlatformPermission("android.permission.BLUETOOTH_PRIVILEGED");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _body_sensors()
        {
            return new PlatformPermission("android.permission.BODY_SENSORS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _brick()
        {
            return new PlatformPermission("android.permission.BRICK");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _broadcast_package_removed()
        {
            return new PlatformPermission("android.permission.BROADCAST_PACKAGE_REMOVED");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _broadcast_sms()
        {
            return new PlatformPermission("android.permission.BROADCAST_SMS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _broadcast_sticky()
        {
            return new PlatformPermission("android.permission.BROADCAST_STICKY");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _broadcast_wap_push()
        {
            return new PlatformPermission("android.permission.BROADCAST_WAP_PUSH");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _call_phone()
        {
            return new PlatformPermission("android.permission.CALL_PHONE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _call_privileged()
        {
            return new PlatformPermission("android.permission.CALL_PRIVILEGED");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _camera()
        {
            return new PlatformPermission("android.permission.CAMERA");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _capture_audio_output()
        {
            return new PlatformPermission("android.permission.CAPTURE_AUDIO_OUTPUT");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _capture_secure_video_output()
        {
            return new PlatformPermission("android.permission.CAPTURE_SECURE_VIDEO_OUTPUT");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _capture_video_output()
        {
            return new PlatformPermission("android.permission.CAPTURE_VIDEO_OUTPUT");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _change_component_enabled_state()
        {
            return new PlatformPermission("android.permission.CHANGE_COMPONENT_ENABLED_STATE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _change_configuration()
        {
            return new PlatformPermission("android.permission.CHANGE_CONFIGURATION");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _change_network_state()
        {
            return new PlatformPermission("android.permission.CHANGE_NETWORK_STATE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _change_wifi_multicast_state()
        {
            return new PlatformPermission("android.permission.CHANGE_WIFI_MULTICAST_STATE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _change_wifi_state()
        {
            return new PlatformPermission("android.permission.CHANGE_WIFI_STATE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _clear_app_cache()
        {
            return new PlatformPermission("android.permission.CLEAR_APP_CACHE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _clear_app_user_data()
        {
            return new PlatformPermission("android.permission.CLEAR_APP_USER_DATA");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _control_location_updates()
        {
            return new PlatformPermission("android.permission.CONTROL_LOCATION_UPDATES");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _delete_cache_files()
        {
            return new PlatformPermission("android.permission.DELETE_CACHE_FILES");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _delete_packages()
        {
            return new PlatformPermission("android.permission.DELETE_PACKAGES");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _device_power()
        {
            return new PlatformPermission("android.permission.DEVICE_POWER");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _diagnostic()
        {
            return new PlatformPermission("android.permission.DIAGNOSTIC");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _disable_keyguard()
        {
            return new PlatformPermission("android.permission.DISABLE_KEYGUARD");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _dump()
        {
            return new PlatformPermission("android.permission.DUMP");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _expand_status_bar()
        {
            return new PlatformPermission("android.permission.EXPAND_STATUS_BAR");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _factory_test()
        {
            return new PlatformPermission("android.permission.FACTORY_TEST");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _flashlight()
        {
            return new PlatformPermission("android.permission.FLASHLIGHT");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _force_back()
        {
            return new PlatformPermission("android.permission.FORCE_BACK");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _get_accounts()
        {
            return new PlatformPermission("android.permission.GET_ACCOUNTS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _get_package_size()
        {
            return new PlatformPermission("android.permission.GET_PACKAGE_SIZE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _get_tasks()
        {
            return new PlatformPermission("android.permission.GET_TASKS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _get_top_activity_info()
        {
            return new PlatformPermission("android.permission.GET_TOP_ACTIVITY_INFO");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _global_search()
        {
            return new PlatformPermission("android.permission.GLOBAL_SEARCH");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _hardware_test()
        {
            return new PlatformPermission("android.permission.HARDWARE_TEST");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _inject_events()
        {
            return new PlatformPermission("android.permission.INJECT_EVENTS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _install_location_provider()
        {
            return new PlatformPermission("android.permission.INSTALL_LOCATION_PROVIDER");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _install_packages()
        {
            return new PlatformPermission("android.permission.INSTALL_PACKAGES");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _install_shortcut()
        {
            return new PlatformPermission("android.permission.INSTALL_SHORTCUT");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _internal_system_window()
        {
            return new PlatformPermission("android.permission.INTERNAL_SYSTEM_WINDOW");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _internet()
        {
            return new PlatformPermission("android.permission.INTERNET");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _kill_background_processes()
        {
            return new PlatformPermission("android.permission.KILL_BACKGROUND_PROCESSES");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _location_hardware()
        {
            return new PlatformPermission("android.permission.LOCATION_HARDWARE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _manage_accounts()
        {
            return new PlatformPermission("android.permission.MANAGE_ACCOUNTS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _manage_app_tokens()
        {
            return new PlatformPermission("android.permission.MANAGE_APP_TOKENS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _manage_documents()
        {
            return new PlatformPermission("android.permission.MANAGE_DOCUMENTS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _master_clear()
        {
            return new PlatformPermission("android.permission.MASTER_CLEAR");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _media_content_control()
        {
            return new PlatformPermission("android.permission.MEDIA_CONTENT_CONTROL");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _modify_audio_settings()
        {
            return new PlatformPermission("android.permission.MODIFY_AUDIO_SETTINGS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _modify_phone_state()
        {
            return new PlatformPermission("android.permission.MODIFY_PHONE_STATE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _mount_format_filesystems()
        {
            return new PlatformPermission("android.permission.MOUNT_FORMAT_FILESYSTEMS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _mount_unmount_filesystems()
        {
            return new PlatformPermission("android.permission.MOUNT_UNMOUNT_FILESYSTEMS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _nfc()
        {
            return new PlatformPermission("android.permission.NFC");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _persistent_activity()
        {
            return new PlatformPermission("android.permission.PERSISTENT_ACTIVITY");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _process_outgoing_calls()
        {
            return new PlatformPermission("android.permission.PROCESS_OUTGOING_CALLS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_calendar()
        {
            return new PlatformPermission("android.permission.READ_CALENDAR");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_call_log()
        {
            return new PlatformPermission("android.permission.READ_CALL_LOG");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_contacts()
        {
            return new PlatformPermission("android.permission.READ_CONTACTS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_external_storage()
        {
            return new PlatformPermission("android.permission.READ_EXTERNAL_STORAGE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_media_images()
        {
            return new PlatformPermission("android.permission.READ_MEDIA_IMAGES");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_media_audio()
        {
            return new PlatformPermission("android.permission.READ_MEDIA_AUDIO");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_media_video()
        {
            return new PlatformPermission("android.permission.READ_MEDIA_VIDEO");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_frame_buffer()
        {
            return new PlatformPermission("android.permission.READ_FRAME_BUFFER");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_history_bookmarks()
        {
            return new PlatformPermission("android.permission.READ_HISTORY_BOOKMARKS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_input_state()
        {
            return new PlatformPermission("android.permission.READ_INPUT_STATE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_logs()
        {
            return new PlatformPermission("android.permission.READ_LOGS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_phone_state()
        {
            return new PlatformPermission("android.permission.READ_PHONE_STATE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_profile()
        {
            return new PlatformPermission("android.permission.READ_PROFILE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_sms()
        {
            return new PlatformPermission("android.permission.READ_SMS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_social_stream()
        {
            return new PlatformPermission("android.permission.READ_SOCIAL_STREAM");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_sync_settings()
        {
            return new PlatformPermission("android.permission.READ_SYNC_SETTINGS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_sync_stats()
        {
            return new PlatformPermission("android.permission.READ_SYNC_STATS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_user_dictionary()
        {
            return new PlatformPermission("android.permission.READ_USER_DICTIONARY");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _read_voicemail()
        {
            return new PlatformPermission("android.permission.READ_VOICEMAIL");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _reboot()
        {
            return new PlatformPermission("android.permission.REBOOT");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _receive_boot_completed()
        {
            return new PlatformPermission("android.permission.RECEIVE_BOOT_COMPLETED");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _receive_mms()
        {
            return new PlatformPermission("android.permission.RECEIVE_MMS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _receive_sms()
        {
            return new PlatformPermission("android.permission.RECEIVE_SMS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _receive_wap_push()
        {
            return new PlatformPermission("android.permission.RECEIVE_WAP_PUSH");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _record_audio()
        {
            return new PlatformPermission("android.permission.RECORD_AUDIO");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _reorder_tasks()
        {
            return new PlatformPermission("android.permission.REORDER_TASKS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _restart_packages()
        {
            return new PlatformPermission("android.permission.RESTART_PACKAGES");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _send_respond_via_message()
        {
            return new PlatformPermission("android.permission.SEND_RESPOND_VIA_MESSAGE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _send_sms()
        {
            return new PlatformPermission("android.permission.SEND_SMS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _set_activity_watcher()
        {
            return new PlatformPermission("android.permission.SET_ACTIVITY_WATCHER");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _set_alarm()
        {
            return new PlatformPermission("android.permission.SET_ALARM");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _set_always_finish()
        {
            return new PlatformPermission("android.permission.SET_ALWAYS_FINISH");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _set_animation_scale()
        {
            return new PlatformPermission("android.permission.SET_ANIMATION_SCALE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _set_debug_app()
        {
            return new PlatformPermission("android.permission.SET_DEBUG_APP");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _set_orientation()
        {
            return new PlatformPermission("android.permission.SET_ORIENTATION");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _set_pointer_speed()
        {
            return new PlatformPermission("android.permission.SET_POINTER_SPEED");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _set_preferred_applications()
        {
            return new PlatformPermission("android.permission.SET_PREFERRED_APPLICATIONS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _set_process_limit()
        {
            return new PlatformPermission("android.permission.SET_PROCESS_LIMIT");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _set_time()
        {
            return new PlatformPermission("android.permission.SET_TIME");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _set_time_zone()
        {
            return new PlatformPermission("android.permission.SET_TIME_ZONE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _set_wallpaper()
        {
            return new PlatformPermission("android.permission.SET_WALLPAPER");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _set_wallpaper_hints()
        {
            return new PlatformPermission("android.permission.SET_WALLPAPER_HINTS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _signal_persistent_processes()
        {
            return new PlatformPermission("android.permission.SIGNAL_PERSISTENT_PROCESSES");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _status_bar()
        {
            return new PlatformPermission("android.permission.STATUS_BAR");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _subscribed_feeds_read()
        {
            return new PlatformPermission("android.permission.SUBSCRIBED_FEEDS_READ");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _subscribed_feeds_write()
        {
            return new PlatformPermission("android.permission.SUBSCRIBED_FEEDS_WRITE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _system_alert_window()
        {
            return new PlatformPermission("android.permission.SYSTEM_ALERT_WINDOW");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _transmit_ir()
        {
            return new PlatformPermission("android.permission.TRANSMIT_IR");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _uninstall_shortcut()
        {
            return new PlatformPermission("android.permission.UNINSTALL_SHORTCUT");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _update_device_stats()
        {
            return new PlatformPermission("android.permission.UPDATE_DEVICE_STATS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _use_credentials()
        {
            return new PlatformPermission("android.permission.USE_CREDENTIALS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _use_sip()
        {
            return new PlatformPermission("android.permission.USE_SIP");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _vibrate()
        {
            return new PlatformPermission("android.permission.VIBRATE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _wake_lock()
        {
            return new PlatformPermission("android.permission.WAKE_LOCK");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _write_apn_settings()
        {
            return new PlatformPermission("android.permission.WRITE_APN_SETTINGS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _write_calendar()
        {
            return new PlatformPermission("android.permission.WRITE_CALENDAR");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _write_call_log()
        {
            return new PlatformPermission("android.permission.WRITE_CALL_LOG");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _write_contacts()
        {
            return new PlatformPermission("android.permission.WRITE_CONTACTS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _write_external_storage()
        {
            return new PlatformPermission("android.permission.WRITE_EXTERNAL_STORAGE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _write_gservices()
        {
            return new PlatformPermission("android.permission.WRITE_GSERVICES");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _write_history_bookmarks()
        {
            return new PlatformPermission("android.permission.WRITE_HISTORY_BOOKMARKS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _write_profile()
        {
            return new PlatformPermission("android.permission.WRITE_PROFILE");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _write_secure_settings()
        {
            return new PlatformPermission("android.permission.WRITE_SECURE_SETTINGS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _write_settings()
        {
            return new PlatformPermission("android.permission.WRITE_SETTINGS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _write_sms()
        {
            return new PlatformPermission("android.permission.WRITE_SMS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _write_social_stream()
        {
            return new PlatformPermission("android.permission.WRITE_SOCIAL_STREAM");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _write_sync_settings()
        {
            return new PlatformPermission("android.permission.WRITE_SYNC_SETTINGS");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _write_user_dictionary()
        {
            return new PlatformPermission("android.permission.WRITE_USER_DICTIONARY");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _write_voicemail()
        {
            return new PlatformPermission("android.permission.WRITE_VOICEMAIL");
        }
        [TargetSpecificImplementation]
        internal static extern PlatformPermission _post_notification()
        {
            return new PlatformPermission("android.permission.POST_NOTIFICATIONS");
        }
    }
}
