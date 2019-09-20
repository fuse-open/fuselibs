using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Storage
{
	[ForeignInclude(Language.Java, "android.content.SharedPreferences", "android.preference.PreferenceManager")]
	internal extern(Android) class AndroidUserSettings : IUserSettings
	{
		Java.Object _handle;
		Java.Object _handleEditor;

		public AndroidUserSettings()
		{
			_handle = Init();
			_handleEditor = GetEditor(_handle);
		}

		[Foreign(Language.Java)]
		Java.Object Init()
		@{
			return PreferenceManager.getDefaultSharedPreferences(com.fuse.Activity.getRootActivity());
		@}

		[Foreign(Language.Java)]
		Java.Object GetEditor(Java.Object handle)
		@{
			return ((SharedPreferences)handle).edit();
		@}

		public string GetStringValue(string key)
		{
			return GetStringValue(_handle, key);
		}

		[Foreign(Language.Java)]
		string GetStringValue(Java.Object handle, string key)
		@{
			return ((SharedPreferences)handle).getString(key, "");
		@}

		public bool GetBooleanValue(string key)
		{
			return GetBooleanValue(_handle, key);
		}

		[Foreign(Language.Java)]
		bool GetBooleanValue(Java.Object handle, string key)
		@{
			return ((SharedPreferences)handle).getBoolean(key, false);
		@}

		public double GetNumberValue(string key)
		{
			return (double)GetFloatValue(_handle, key);
		}

		[Foreign(Language.Java)]
		float GetFloatValue(Java.Object handle, string key)
		@{
			return ((SharedPreferences)handle).getFloat(key, -1);
		@}

		public void SetStringValue(string key, string value)
		{
			SetStringValue(_handleEditor, key, value);
		}

		[Foreign(Language.Java)]
		void SetStringValue(Java.Object handle, string key, string value)
		@{
			((SharedPreferences.Editor)handle).putString(key, value);
			((SharedPreferences.Editor)handle).commit();
		@}

		public void SetBooleanValue(string key, bool value)
		{
			SetBooleanValue(_handleEditor, key, value);
		}

		[Foreign(Language.Java)]
		void SetBooleanValue(Java.Object handle, string key, bool value)
		@{
			((SharedPreferences.Editor)handle).putBoolean(key, value);
			((SharedPreferences.Editor)handle).commit();
		@}

		public void SetNumberValue(string key, double value)
		{
			SetFloatValue(_handleEditor, key, (float)value);
		}

		[Foreign(Language.Java)]
		void SetFloatValue(Java.Object handle, string key, float value)
		@{
			((SharedPreferences.Editor)handle).putFloat(key, value);
			((SharedPreferences.Editor)handle).commit();
		@}

		public void Remove(string key)
		{
			Remove(_handleEditor, key);
		}

		[Foreign(Language.Java)]
		void Remove(Java.Object handle, string key)
		@{
			((SharedPreferences.Editor)handle).remove(key);
			((SharedPreferences.Editor)handle).commit();
		@}

		public void Clear()
		{
			Clear(_handleEditor);
		}

		[Foreign(Language.Java)]
		void Clear(Java.Object handle)
		@{
			((SharedPreferences.Editor)handle).clear();
			((SharedPreferences.Editor)handle).commit();
		@}
	}
}