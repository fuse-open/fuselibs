using Uno;
using Uno.UX;

using Fuse;
using Fuse.Scripting;

namespace Fuse.Storage
{
	[UXGlobalModule]
	/**
		@scriptmodule FuseJS/UserSettings

		`FuseJS/UserSettings` module provides key-value pairs mechanism to store and retrieve primitive data types (string, number, boolean) as well as an array and json object.
		You can use this module to store information such as configuration data, application states etc.

		> `UserSettings` module is implemented atop NSUserDefaults on iOS and Shared Preferences on Android

		## Example

			<JavaScript>
				var userSettings = require("FuseJS/UserSettings")

				userSettings.putString('email', 'john.appleseed@example.com');
				userSettings.putString('password', 's3c1ReT');
				userSettings.putString('api_token', '73awnljqurelcvxiy832a');
				userSettings.putBoolean('logged', true);
				userSettings.putNumber('state_num', 2);
				userSettings.putArray('preferences', ['Technology', 'Cars', 'Foods']);
				userSettings.putObject('profile', {
					'first_name': 'John',
					'last_name': 'Appleseed',
					'gender': 'male',
					'address': '5 avenue'
					'age': 25,
					'married': false
				});

				var username = userSettings.getString('username');
				var password = userSettings.getString('password');
				var api_token = userSettings.getString('api_token');
				var logged = userSettings.getBoolean('logged');
				var state_num = userSettings.getNumber('state_num');
				var preferences = userSettings.getArray('preferences');
				var profile = userSettings.getObject('profile');
			</JavaScript>

	*/
	public sealed class UserSettingsModule : NativeModule
	{
		static readonly UserSettingsModule _instance;
		UserSettingsImpl _userSettingImpl;
		public UserSettingsModule()
		{
			if (_instance != null) return;
			_instance = this;
			_userSettingImpl = new UserSettingsImpl();
			Resource.SetGlobalKey(_instance, "FuseJS/UserSettings");
			AddMember(new NativeFunction("getString", GetString));
			AddMember(new NativeFunction("putString", PutString));
			AddMember(new NativeFunction("getNumber", GetNumber));
			AddMember(new NativeFunction("putNumber", PutNumber));
			AddMember(new NativeFunction("getBoolean", GetBoolean));
			AddMember(new NativeFunction("putBoolean", PutBoolean));
			AddMember(new NativeFunction("getArray", GetObject));
			AddMember(new NativeFunction("putArray", PutObject));
			AddMember(new NativeFunction("getObject", GetObject));
			AddMember(new NativeFunction("putObject", PutObject));
			AddMember(new NativeFunction("clear", Clear));
		}

		object GetString(Context c, object[] args)
		{
			if (args.Length > 0)
			{
				string key = args[0] as string;
				return _userSettingImpl.GetStringValue(key);
			}
			return null;
		}

		object PutString(Context c, object[] args)
		{
			if (args.Length > 1)
			{
				string key = args[0] as string;
				if (args[1] == null)
					return null;
				string value = args[1] as string;
				_userSettingImpl.SetStringValue(key, value);
			}
			return null;
		}

		object GetNumber(Context c, object[] args)
		{
			if (args.Length > 0)
			{
				string key = args[0] as string;
				return _userSettingImpl.GetNumberValue(key);
			}
			return null;
		}

		object PutNumber(Context c, object[] args)
		{
			if (args.Length > 1)
			{
				string key = args[0] as string;
				if (args[1] == null)
					return null;
				double value = Marshal.ToDouble(args[1]);
				_userSettingImpl.SetNumberValue(key, value);
			}
			return null;
		}

		object GetBoolean(Context c, object[] args)
		{
			if (args.Length > 0)
			{
				string key = args[0] as string;
				return _userSettingImpl.GetBooleanValue(key);
			}
			return null;
		}

		object PutBoolean(Context c, object[] args)
		{
			if (args.Length > 1)
			{
				string key = args[0] as string;
				if (args[1] == null)
					return null;
				bool value = Marshal.ToBool(args[1]);
				_userSettingImpl.SetBooleanValue(key, value);
			}
			return null;
		}

		object GetObject(Context c, object[] args)
		{
			if (args.Length > 0)
			{
				string key = args[0] as string;
				var value = _userSettingImpl.GetStringValue(key);
				if (value != null)
				{
					// convert string to scripting object
					return Converter(c, Json.Parse(value));
				}
			}
			return null;
		}

		object PutObject(Context c, object[] args)
		{
			if (args.Length > 1)
			{
				string key = args[0] as string;
				if (args[1] == null)
					return null;
				// convert scripting object to string
				var value = Json.Stringify(args[1]);
				_userSettingImpl.SetStringValue(key, value);
			}
			return null;
		}

		object Clear(Context c, object[] args)
		{
			_userSettingImpl.Clear();
			return null;
		}

		object Converter(Context c, object obj)
		{
			if (obj is IObject)
			{
				var output = c.NewObject();
				var data = obj as IObject;
				for (var i=0; i<data.Keys.Length; i++)
					output[data.Keys[i]] = Converter(c, data[data.Keys[i]]);
				return output;
			}
			else if (obj is IArray)
			{
				var arr = obj as IArray;
				var values = new object[arr.Length];
				for (int i = 0; i < values.Length; i++)
					values[i] = Converter(c, arr[i]);
				return c.NewArray(values);
			}
			else if (obj is string)
				return (string)obj;
			else if (obj is bool)
				return (bool)obj;
			else if (obj is double)
				return (double)obj;
			else
				return null;
		}
	}
}