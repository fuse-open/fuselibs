using Uno;
using Uno.IO;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Storage
{
	public extern(!MOBILE) class DesktopUserSettingsImpl
	{
		static readonly string filename = "UserSettings.json";
		static DesktopUserSettingsImpl instance;
		static Dictionary<string, object> data = new Dictionary<string, object>();

		private DesktopUserSettingsImpl()
		{
			string content = "";
			ApplicationDir.TryRead(filename, out content);
			if (content != "") {
				IObject obj = Json.Parse(content) as IObject;
				for (var i = 0; i< obj.Keys.Length; i++)
				 	data[obj.Keys[i]] = obj[obj.Keys[i]];
			}
		}

		public static DesktopUserSettingsImpl GetInstance()
		{
			if (instance != null)
				return instance;
			instance = new DesktopUserSettingsImpl();
			return instance;
		}

		public string GetStringValue(string key)
		{
			if (data.ContainsKey(key))
				return data[key] as string;
			else
				return "";
		}

		public double GetNumberValue(string key)
		{
			if (data.ContainsKey(key))
				return (double)data[key];
			else
				return 0;
		}

		public bool GetBooleanValue(string key)
		{
			if (data.ContainsKey(key))
				return (bool)data[key];
			else
				return false;
		}

		public void SetStringValue(string key, string value)
		{
			if (data.ContainsKey(key))
				data.Remove(key);
			data.Add(key, value);
			Synchronize();
		}

		public void SetNumberValue(string key, double value)
		{
			if (data.ContainsKey(key))
				data.Remove(key);
			data.Add(key, value);
			Synchronize();
		}

		public void SetBooleanValue(string key, bool value)
		{
			if (data.ContainsKey(key))
				data.Remove(key);
			data.Add(key, value);
			Synchronize();
		}

		public void Remove(string key)
		{
			data.Remove(key);
			Synchronize();
		}

		public void Clear()
		{
			data.Clear();
			Synchronize();
		}

		private void Synchronize()
		{
			var jsonString = Json.Stringify(data);
			ApplicationDir.Write(filename, jsonString);
		}
	}

	[ForeignInclude(Language.Java, "com.fuse.Activity", "android.content.SharedPreferences", "android.preference.PreferenceManager")]
	public extern(Android) class AndroidUserSettingsImpl
	{
		[Foreign(Language.Java)]
		public static string GetStringValue(string key)
		@{
			SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(Activity.getRootActivity());
			return preferences.getString(key, "");
		@}

		[Foreign(Language.Java)]
		public static double GetNumberValue(string key)
		@{
			SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(Activity.getRootActivity());
			return preferences.getFloat(key, -1f);
		@}

		[Foreign(Language.Java)]
		public static bool GetBooleanValue(string key)
		@{
			SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(Activity.getRootActivity());
			return preferences.getBoolean(key, false);
		@}

		[Foreign(Language.Java)]
		public static void SetStringValue(string key, string value)
		@{
			SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(Activity.getRootActivity());
			SharedPreferences.Editor editor = preferences.edit();
			editor.putString(key, value);
			editor.commit();
		@}

		[Foreign(Language.Java)]
		public static void SetNumberValue(string key, double value)
		@{
			SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(Activity.getRootActivity());
			SharedPreferences.Editor editor = preferences.edit();
			editor.putFloat(key, (float)value);
			editor.commit();
		@}

		[Foreign(Language.Java)]
		public static void SetBooleanValue(string key, bool value)
		@{
			SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(com.fuse.Activity.getRootActivity());
			SharedPreferences.Editor editor = preferences.edit();
			editor.putBoolean(key, value);
			editor.commit();
		@}

		[Foreign(Language.Java)]
		public static void Remove(string key)
		@{
			SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(com.fuse.Activity.getRootActivity());
			SharedPreferences.Editor editor = preferences.edit();
			editor.remove(key);
			editor.commit();
		@}

		[Foreign(Language.Java)]
		public static void Clear()
		@{
			SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(com.fuse.Activity.getRootActivity());
			SharedPreferences.Editor editor = preferences.edit();
			editor.clear();
			editor.commit();
		@}
	}

	public extern(iOS) class IOSUserSettingsImpl
	{
		[Foreign(Language.ObjC)]
		public static string GetStringValue(string key)
		@{
			NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
			return [userDefault stringForKey:key];
		@}

		[Foreign(Language.ObjC)]
		public static double GetNumberValue(string key)
		@{
			NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
			return [userDefault floatForKey:key];
		@}

		[Foreign(Language.ObjC)]
		public static bool GetBooleanValue(string key)
		@{
			NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
			return [userDefault boolForKey:key];
		@}

		[Foreign(Language.ObjC)]
		public static void SetStringValue(string key, string value)
		@{
			NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
			[userDefault setObject:value forKey:key];
			[userDefault synchronize];
		@}

		[Foreign(Language.ObjC)]
		public static void SetNumberValue(string key, double value)
		@{
			NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
			[userDefault setFloat:value forKey:key];
			[userDefault synchronize];
		@}

		[Foreign(Language.ObjC)]
		public static void SetBooleanValue(string key, bool value)
		@{
			NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
			[userDefault setBool:value forKey:key];
			[userDefault synchronize];
		@}

		[Foreign(Language.ObjC)]
		public static void Remove(string key)
		@{
			NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
			[userDefault removeObjectForKey:key];
			[userDefault synchronize];
		@}

		[Foreign(Language.ObjC)]
		public static void Clear()
		@{
			NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
			[userDefault removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
		@}
	}
}