using Uno;
using Uno.IO;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Storage
{
	interface IUserSettings
	{
		string GetStringValue(string key);

		double GetNumberValue(string key);

		bool GetBooleanValue(string key);

		void SetStringValue(string key, string value);

		void SetNumberValue(string key, double value);

		void SetBooleanValue(string key, bool value);

		void Remove(string key);

		void Clear();
	}

	public extern(!MOBILE) class DesktopUserSettingsImpl : IUserSettings
	{
		string filename = "UserSettings.json";
		Dictionary<string, object> data = new Dictionary<string, object>();

		public DesktopUserSettingsImpl()
		{
			string content = "";
			ApplicationDir.TryRead(filename, out content);
			if (content != "") {
				IObject obj = Json.Parse(content) as IObject;
				for (var i = 0; i< obj.Keys.Length; i++)
				 	data[obj.Keys[i]] = obj[obj.Keys[i]];
			}
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

	[ForeignInclude(Language.Java, "android.content.SharedPreferences", "android.preference.PreferenceManager")]
	public extern(Android) class AndroidUserSettingsImpl : IUserSettings
	{
		Java.Object _sharedPreferences;

		public AndroidUserSettingsImpl()
		{
			_sharedPreferences = Init();
		}

		[Foreign(Language.Java)]
		private Java.Object Init()
		@{
			return PreferenceManager.getDefaultSharedPreferences(com.fuse.Activity.getRootActivity());
		@}

		[Foreign(Language.Java)]
		public string GetStringValue(string key)
		@{
			SharedPreferences preferences = (SharedPreferences)@{AndroidUserSettingsImpl:Of(_this)._sharedPreferences:Get()};
			return preferences.getString(key, "");
		@}

		[Foreign(Language.Java)]
		public double GetNumberValue(string key)
		@{
			SharedPreferences preferences = (SharedPreferences)@{AndroidUserSettingsImpl:Of(_this)._sharedPreferences:Get()};
			return preferences.getFloat(key, -1f);
		@}

		[Foreign(Language.Java)]
		public bool GetBooleanValue(string key)
		@{
			SharedPreferences preferences = (SharedPreferences)@{AndroidUserSettingsImpl:Of(_this)._sharedPreferences:Get()};
			return preferences.getBoolean(key, false);
		@}

		[Foreign(Language.Java)]
		public void SetStringValue(string key, string value)
		@{
			SharedPreferences preferences = (SharedPreferences)@{AndroidUserSettingsImpl:Of(_this)._sharedPreferences:Get()};
			SharedPreferences.Editor editor = preferences.edit();
			editor.putString(key, value);
			editor.commit();
		@}

		[Foreign(Language.Java)]
		public void SetNumberValue(string key, double value)
		@{
			SharedPreferences preferences = (SharedPreferences)@{AndroidUserSettingsImpl:Of(_this)._sharedPreferences:Get()};
			SharedPreferences.Editor editor = preferences.edit();
			editor.putFloat(key, (float)value);
			editor.commit();
		@}

		[Foreign(Language.Java)]
		public void SetBooleanValue(string key, bool value)
		@{
			SharedPreferences preferences = (SharedPreferences)@{AndroidUserSettingsImpl:Of(_this)._sharedPreferences:Get()};
			SharedPreferences.Editor editor = preferences.edit();
			editor.putBoolean(key, value);
			editor.commit();
		@}

		[Foreign(Language.Java)]
		public void Remove(string key)
		@{
			SharedPreferences preferences = (SharedPreferences)@{AndroidUserSettingsImpl:Of(_this)._sharedPreferences:Get()};
			SharedPreferences.Editor editor = preferences.edit();
			editor.remove(key);
			editor.commit();
		@}

		[Foreign(Language.Java)]
		public void Clear()
		@{
			SharedPreferences preferences = (SharedPreferences)@{AndroidUserSettingsImpl:Of(_this)._sharedPreferences:Get()};
			SharedPreferences.Editor editor = preferences.edit();
			editor.clear();
			editor.commit();
		@}
	}

	public extern(iOS) class IOSUserSettingsImpl : IUserSettings
	{
		ObjC.Object _userDefaults;

		public IOSUserSettingsImpl()
		{
			_userDefaults = Init();
		}

		[Foreign(Language.ObjC)]
		private ObjC.Object Init()
		@{
			return [NSUserDefaults standardUserDefaults];
		@}

		[Foreign(Language.ObjC)]
		public string GetStringValue(string key)
		@{
			NSUserDefaults * userDefault = (NSUserDefaults *)@{IOSUserSettingsImpl:Of(_this)._userDefaults:Get()};
			return [userDefault stringForKey:key];
		@}

		[Foreign(Language.ObjC)]
		public double GetNumberValue(string key)
		@{
			NSUserDefaults * userDefault = (NSUserDefaults *)@{IOSUserSettingsImpl:Of(_this)._userDefaults:Get()};
			return [userDefault floatForKey:key];
		@}

		[Foreign(Language.ObjC)]
		public bool GetBooleanValue(string key)
		@{
			NSUserDefaults * userDefault = (NSUserDefaults *)@{IOSUserSettingsImpl:Of(_this)._userDefaults:Get()};
			return [userDefault boolForKey:key];
		@}

		[Foreign(Language.ObjC)]
		public void SetStringValue(string key, string value)
		@{
			NSUserDefaults * userDefault = (NSUserDefaults *)@{IOSUserSettingsImpl:Of(_this)._userDefaults:Get()};
			[userDefault setObject:value forKey:key];
			[userDefault synchronize];
		@}

		[Foreign(Language.ObjC)]
		public void SetNumberValue(string key, double value)
		@{
			NSUserDefaults * userDefault = (NSUserDefaults *)@{IOSUserSettingsImpl:Of(_this)._userDefaults:Get()};
			[userDefault setFloat:value forKey:key];
			[userDefault synchronize];
		@}

		[Foreign(Language.ObjC)]
		public void SetBooleanValue(string key, bool value)
		@{
			NSUserDefaults * userDefault = (NSUserDefaults *)@{IOSUserSettingsImpl:Of(_this)._userDefaults:Get()};
			[userDefault setBool:value forKey:key];
			[userDefault synchronize];
		@}

		[Foreign(Language.ObjC)]
		public void Remove(string key)
		@{
			NSUserDefaults * userDefault = (NSUserDefaults *)@{IOSUserSettingsImpl:Of(_this)._userDefaults:Get()};
			[userDefault removeObjectForKey:key];
			[userDefault synchronize];
		@}

		[Foreign(Language.ObjC)]
		public void Clear()
		@{
			NSUserDefaults * userDefault = (NSUserDefaults *)@{IOSUserSettingsImpl:Of(_this)._userDefaults:Get()};
			[userDefault removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
		@}
	}
}