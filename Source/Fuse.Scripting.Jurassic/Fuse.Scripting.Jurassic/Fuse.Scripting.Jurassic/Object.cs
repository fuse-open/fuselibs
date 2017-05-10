using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Jurassic;
using Jurassic.Library;

namespace Fuse.Scripting.Jurassic
{
	public class ObjectHandle
	{
		public ObjectInstance ObjectInstance { get { return _objectInstance; } }

		readonly ObjectInstance _objectInstance;

		public ObjectHandle(ObjectInstance objectInstance)
		{
			_objectInstance = objectInstance;
		}

		public override bool Equals(object obj)
		{
			var ah = obj as ObjectHandle;
			if (ah == null) return false;
			return _objectInstance.Equals(ah.ObjectInstance);
		}
	}

	public static class ObjectImpl
	{
		public static void SetValue(ObjectHandle handle, string key, object value)
		{
			Helpers.Try(() => handle.ObjectInstance.SetPropertyValue(key, Helpers.FromHandle(value), true));
		}

		public static object GetValue(ObjectHandle handle, string key)
		{
			return Helpers.Try(() => Helpers.ToHandle(handle.ObjectInstance.GetPropertyValue(key)));
		}

		public static string[] GetKeys(ObjectHandle handle)
		{
			return Helpers.Try(() => handle.ObjectInstance.Properties.Select(x => x.Name).ToArray());
		}

		public static object CallMethod(ObjectHandle handle, string name, object[] args)
		{
			var func = handle.ObjectInstance.GetPropertyValue(name) as FunctionInstance;
			if (func == null)
				throw new Exception("Object does not contain function: " + name);

			var arguments = Helpers.FromHandles(args);
			object result = null;
			result = Helpers.Try(() => Helpers.ToHandle(func.Call(handle.ObjectInstance, arguments)));
			return result;
		}

		public static bool InstanceOf(ObjectHandle handle, object type)
		{
			if (type is FunctionHandle)
			{
				var typeInst = ((FunctionHandle)type).FunctionInstance;

				return typeInst.HasInstance(handle.ObjectInstance);
			}

			return false;
		}

		public static bool ContainsKey(ObjectHandle handle, string key)
		{
			return handle.ObjectInstance.HasProperty(key);
		}

	}
}
