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
		public UserSettingsModule()
		{
			if (_instance != null) return;
			_instance = this;
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
			AddMember(new NativeFunction("remove", Remove));
			AddMember(new NativeFunction("clear", Clear));
		}

		/**
			@scriptmethod getString(key)

			Retrieve a String value from the UserSetting.

			@param key The name of the UserSetting to retrieve

		*/
		object GetString(Context c, object[] args)
		{
			if (args.Length > 0)
			{
				string key = args[0] as string;
				if defined(Android)
					return AndroidUserSettingsImpl.GetStringValue(key);
				else if defined(iOS)
					return IOSUserSettingsImpl.GetStringValue(key);
				else
					return DesktopUserSettingsImpl.GetInstance().GetStringValue(key);
			}
			return null;
		}

		/**
			@scriptmethod putString(key, value)

			Set a String value in the UserSetting.

			@param key The name of the UserSetting to save
			@param value The string value of the UserSetting to save
		*/
		object PutString(Context c, object[] args)
		{
			if (args.Length > 1)
			{
				string key = args[0] as string;
				if (args[1] == null)
					return null;
				string value = args[1] as string;
				if defined(Android)
					AndroidUserSettingsImpl.SetStringValue(key, value);
				else if defined(iOS)
					IOSUserSettingsImpl.SetStringValue(key, value);
				else
					DesktopUserSettingsImpl.GetInstance().SetStringValue(key, value);
			}
			return null;
		}

		/**
			@scriptmethod getNumber(key)

			Retrieve a Number value from the UserSetting.

			@param key The name of the UserSetting to retrieve

		*/
		object GetNumber(Context c, object[] args)
		{
			if (args.Length > 0)
			{
				string key = args[0] as string;
				if defined(Android)
					return AndroidUserSettingsImpl.GetNumberValue(key);
				else if defined(iOS)
					return IOSUserSettingsImpl.GetNumberValue(key);
				else
					return DesktopUserSettingsImpl.GetInstance().GetNumberValue(key);
			}
			return null;
		}

		/**
			@scriptmethod putNumber(key, value)

			Set a Number value in the UserSetting.

			@param key The name of the UserSetting to save
			@param value The number value of the UserSetting to save
		*/
		object PutNumber(Context c, object[] args)
		{
			if (args.Length > 1)
			{
				string key = args[0] as string;
				if (args[1] == null)
					return null;
				double value = Marshal.ToDouble(args[1]);
				if defined(Android)
					AndroidUserSettingsImpl.SetNumberValue(key, value);
				else if defined(iOS)
					IOSUserSettingsImpl.SetNumberValue(key, value);
				else
					DesktopUserSettingsImpl.GetInstance().SetNumberValue(key, value);
			}
			return null;
		}

		/**
			@scriptmethod getBoolean(key)

			Retrieve a Boolean value from the UserSetting.

			@param key The name of the UserSetting to retrieve

		*/
		object GetBoolean(Context c, object[] args)
		{
			if (args.Length > 0)
			{
				string key = args[0] as string;
				if defined(Android)
					return AndroidUserSettingsImpl.GetBooleanValue(key);
				else if defined(iOS)
					return IOSUserSettingsImpl.GetBooleanValue(key);
				else
					return DesktopUserSettingsImpl.GetInstance().GetBooleanValue(key);
			}
			return null;
		}

		/**
			@scriptmethod putNumber(key, value)

			Set a Boolean value in the UserSetting.

			@param key The name of the UserSetting to save
			@param value The boolean value of the UserSetting to save
		*/
		object PutBoolean(Context c, object[] args)
		{
			if (args.Length > 1)
			{
				string key = args[0] as string;
				if (args[1] == null)
					return null;
				bool value = Marshal.ToBool(args[1]);
				if defined(Android)
					AndroidUserSettingsImpl.SetBooleanValue(key, value);
				else if defined(iOS)
					IOSUserSettingsImpl.SetBooleanValue(key, value);
				else
					DesktopUserSettingsImpl.GetInstance().SetBooleanValue(key, value);
			}
			return null;
		}

		/**
			@scriptmethod getObject(key)

			Retrieve a Json Object value from the UserSetting.

			@param key The name of the UserSetting to retrieve

		*/
		object GetObject(Context c, object[] args)
		{
			if (args.Length > 0)
			{
				string key = args[0] as string;
				var value = "";
				if defined(Android)
					value = AndroidUserSettingsImpl.GetStringValue(key);
				else if defined(iOS)
					value = IOSUserSettingsImpl.GetStringValue(key);
				else
					value = DesktopUserSettingsImpl.GetInstance().GetStringValue(key);
				if (value != null)
				{
					// convert string to scripting object
					return Converter(c, Json.Parse(value));
				}
			}
			return null;
		}

		/**
			@scriptmethod putObject(key, value)

			Set a JSON value in the UserSetting.

			@param key The name of the UserSetting to save
			@param value The JSON object value of the UserSetting to save
		*/
		object PutObject(Context c, object[] args)
		{
			if (args.Length > 1)
			{
				string key = args[0] as string;
				if (args[1] == null)
					return null;
				// convert scripting object to string
				var value = Json.Stringify(args[1]);
				if defined(Android)
					AndroidUserSettingsImpl.SetStringValue(key, value);
				else if defined(iOS)
					IOSUserSettingsImpl.SetStringValue(key, value);
				else
					DesktopUserSettingsImpl.GetInstance().SetStringValue(key, value);
			}
			return null;
		}

		/**
			@scriptmethod remove(key)

			remove value based on key.

			@param key The name of the UserSetting to remove
		*/
		object Remove(Context c, object[] args)
		{
			if (args.Length > 0)
			{
				string key = args[0] as string;
				if defined(Android)
					AndroidUserSettingsImpl.Remove(key);
				else if defined(iOS)
					IOSUserSettingsImpl.Remove(key);
				else
					DesktopUserSettingsImpl.GetInstance().Remove(key);
			}
			return null;
		}

		/**
			@scriptmethod clear()

			clear User Setting values
		*/
		object Clear(Context c, object[] args)
		{
			if defined(Android)
				AndroidUserSettingsImpl.Clear();
			else if defined(iOS)
				IOSUserSettingsImpl.Clear();
			else
				DesktopUserSettingsImpl.GetInstance().Clear();
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