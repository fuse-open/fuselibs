using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Jurassic;
using Jurassic.Library;

namespace Fuse.Scripting.Jurassic
{

	public class ArrayHandle
	{
		public ArrayInstance ArrayInstance { get { return _arrayInstance; } }

		readonly ArrayInstance _arrayInstance;

		public ArrayHandle(ArrayInstance arrayInstance)
		{
			_arrayInstance = arrayInstance;
		}

		public override bool Equals(object obj)
		{
			var ah = obj as ArrayHandle;
			if (ah == null) return false;
			return _arrayInstance.Equals(ah.ArrayInstance);
		}
	}

	public static class ArrayImpl
	{
		public static int GetLength(ArrayHandle handle)
		{
			return Helpers.Try(() => (int)handle.ArrayInstance.Length);
		}

		public static void SetValue(ArrayHandle handle, int index, object value)
		{
			Helpers.Try(() => { handle.ArrayInstance[index] = Helpers.FromHandle(value); });
		}

		public static object GetValue(ArrayHandle handle, int index)
		{
			return Helpers.Try(() => Helpers.ToHandle(handle.ArrayInstance[index]));
		}

	}
}
