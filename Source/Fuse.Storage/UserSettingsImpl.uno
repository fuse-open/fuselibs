using Uno;
using Uno.Collections;
using Uno.IO;

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

	public class UserSettingsImpl : IUserSettings
	{
		static IUserSettings _userSettings;
		public UserSettingsImpl()
		{
			if(_userSettings != null) return;
			if defined(Android)
				_userSettings = new AndroidUserSettings();
			else if defined(iOS)
				_userSettings = new IOSUserSettings();
			else
				_userSettings = new DesktopUserSettings();
		}

		public string GetStringValue(string key)
		{
			return _userSettings.GetStringValue(key);
		}

		public double GetNumberValue(string key)
		{
			return _userSettings.GetNumberValue(key);
		}

		public bool GetBooleanValue(string key)
		{
			return _userSettings.GetBooleanValue(key);
		}

		public void SetStringValue(string key, string value)
		{
			_userSettings.SetStringValue(key, value);
		}

		public void SetNumberValue(string key, double value)
		{
			_userSettings.SetNumberValue(key, value);
		}

		public void SetBooleanValue(string key, bool value)
		{
			_userSettings.SetBooleanValue(key, value);
		}

		public void Remove(string key)
		{
			_userSettings.Remove(key);
		}

		public void Clear()
		{
			_userSettings.Clear();
		}
	}

	internal class DesktopUserSettings : IUserSettings
	{

		string filename = "UserSettings.json";
		Dictionary<string, object> data = new Dictionary<string, object>();

		public DesktopUserSettings()
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

		public float GetFloatValue(string key)
		{
			if (data.ContainsKey(key))
				return (float)(double)data[key];
			else
				return 0;
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
}